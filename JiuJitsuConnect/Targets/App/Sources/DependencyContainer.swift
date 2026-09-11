//
//  DependencyContainer.swift
//  App
//
//  Created by suni on 9/21/25.
//
//  앱의 Composition Root.
//  Repository / FirebaseClient 인스턴스 생명주기(lazy 단일 인스턴스)를 보유하고,
//  TCA Client(`AuthClient`, `UserClient`, `CommunityClient`, `FirebaseClient`) 빌드를 담당한다.
//
//  실제 인스턴스화 로직은 `RepositoryFactory` / `FirebaseClientFactory`로 분리되어 있어
//  본 컨테이너는 의존성 그래프를 조립하는 책임에만 집중한다.
//

import Foundation
import Domain
import Data
import Presentation
import CoreKit

public final class DependencyContainer {
    public static let shared = DependencyContainer()

    private init() {
        // 앱이 시작될 때, CoreKit의 Log 핸들러를 Pulse 핸들러로 설정합니다.
        Log.handler = PulseLogHandler()
    }

    // MARK: - Shared Infra (single instance)
    // 401 토큰 갱신 single-flight를 위해 모든 Repository가 동일한 NetworkService(=동일 코디네이터)를
    // 공유한다. TokenStorage도 동일 인스턴스로 묶어 시드/갱신 경로를 일치시킨다.
    private let sharedTokenStorage: TokenStorage = DefaultTokenStorage()
    /// 401 인터셉터의 토큰 갱신/세션 만료를 Presentation(웹뷰 동기화·로그아웃)으로 전달하는 채널.
    private let authSessionEventBroadcaster = AuthSessionEventBroadcaster()
    /// AppDelegate가 받은 푸시 탭을 Presentation(딥링크 라우팅)으로 전달하는 채널.
    private let pushNotificationTapRelay = PushNotificationTapRelay()
    private lazy var sharedNetworkService: NetworkService = DefaultNetworkService(
        tokenStorage: sharedTokenStorage,
        sessionEventBroadcaster: authSessionEventBroadcaster
    )

    // MARK: - Repositories (lazy single instance)
    private lazy var authRepository: AuthRepository = RepositoryFactory.makeAuthRepository(
        networkService: sharedNetworkService,
        tokenStorage: sharedTokenStorage
    )
    private lazy var userRepository: UserRepository = RepositoryFactory.makeUserRepository(
        networkService: sharedNetworkService,
        tokenStorage: sharedTokenStorage
    )
    private lazy var communityRepository: CommunityRepository = RepositoryFactory.makeCommunityRepository(
        networkService: sharedNetworkService
    )
    private lazy var imageUploadRepository: ImageUploadRepository = RepositoryFactory.makeImageUploadRepository(
        networkService: sharedNetworkService
    )
    private lazy var imageRepository: ImageRepository = RepositoryFactory.makeImageRepository(
        networkService: sharedNetworkService
    )

    // MARK: - Firebase Client (shared instance)
    private lazy var sharedFirebaseClient: FirebaseClient = FirebaseClientFactory.make()

    // MARK: - TCA Clients

    public func configureAuthClient() -> AuthClient {
        return AuthClient(
            loginWithGoogle: {
                try await self.authRepository.signInWithGoogle()
            },
            loginWithApple: {
                try await self.authRepository.signInWithApple()
            },
            loginWithKakao: {
                try await self.authRepository.signInWithKakao()
            },
            serverLogin: { user in
                try await self.authRepository.serverLogin(user: user)
            },
            serverLogout: {
                try await self.authRepository.serverLogout()
            },
            signOut: {
                await self.authRepository.signOut()
            },
            autoLogin: {
                try await self.authRepository.autoLogin()
            },
            hasValidToken: {
                self.authRepository.hasValidToken()
            },
            refreshSession: {
                try await self.authRepository.refreshSession()
            }
        )
    }

    /// 401 인터셉터가 방송하는 세션 이벤트를 TCA가 구독하기 위한 클라이언트.
    public func configureAuthSessionEventClient() -> AuthSessionEventClient {
        AuthSessionEventClient(events: { [authSessionEventBroadcaster] in
            authSessionEventBroadcaster.events()
        })
    }

    /// 푸시 탭 payload를 TCA가 구독하기 위한 클라이언트.
    public func configurePushNotificationClient() -> PushNotificationClient {
        PushNotificationClient(taps: { [pushNotificationTapRelay] in
            pushNotificationTapRelay.taps()
        })
    }

    /// AppDelegate가 푸시 탭 payload를 흘려보내는 발신 창구.
    public func deliverPushNotificationTap(_ payload: PushActionPayload) {
        pushNotificationTapRelay.send(payload)
    }

    public func configureUserClient() -> UserClient {
        UserClient(
            signup: { info in
                try await self.userRepository.signup(info: info)
            },
            checkNickname: { info in
                try await self.userRepository.checkNickname(info: info)
            },
            withdrawal: {
                try await self.userRepository.withdrawal()
            },
            fetchUserProfile: {
                try await self.userRepository.fetchUserProfile()
            },
            registerAppInfo: { info in
                _ = try await self.userRepository.registerAppInfo(info: info)
            },
            updateFCMToken: { token in
                let info = await MainActor.run {
                    AppInfo.makeWithCurrentDevice(fcmToken: token)
                }
                _ = try await self.userRepository.registerAppInfo(info: info)
                self.sharedFirebaseClient.cacheToken(token)
            },
            updateNickname: { nickname in
                _ = try await self.userRepository.updateNickname(nickname)
            },
            setProfileImage: { imageFileId in
                _ = try await self.userRepository.setProfileImage(imageFileId: imageFileId)
            },
            requestOwnerVerification: { imageFileId in
                _ = try await self.userRepository.requestOwnerVerification(imageFileId: imageFileId)
            }
        )
    }

    public func configureCommunityClient() -> CommunityClient {
        return CommunityClient(
            fetchProfile: {
                try await self.communityRepository.fetchProfile()
            },
            updateProfile: { profile, section in
                try await self.communityRepository.updateProfile(profile, section: section)
            }
        )
    }

    public func configureImageUploadClient() -> ImageUploadClient {
        return ImageUploadClient(
            uploadImage: { data, purpose in
                // 1·2단계: CDN(ImageKit) 업로드 → cdnId/imageUrl 확보
                let uploaded = try await self.imageUploadRepository.uploadImage(data, purpose: purpose)
                // 3단계: 우리 서버 등록(POST /api/image) → Int id 발급
                return try await self.imageRepository.registerImage(
                    cdnId: uploaded.cdnId,
                    imageUrl: uploaded.imageUrl
                )
            }
        )
    }

    public func configureImageClient() -> ImageClient {
        return ImageClient(
            registerImage: { cdnId, imageUrl in
                try await self.imageRepository.registerImage(cdnId: cdnId, imageUrl: imageUrl)
            },
            deleteImage: { id in
                try await self.imageRepository.deleteImage(id: id)
            }
        )
    }

    public func configureFirebaseClient() -> FirebaseClient {
        return sharedFirebaseClient
    }

    public func configureNoticeClient() -> NoticeClient {
        let noticeService = NoticeService(networkService: sharedNetworkService)
        return NoticeClient(
            fetchSetting: {
                try await noticeService.fetchSetting()
            },
            updateSetting: { setting in
                try await noticeService.updateSetting(setting)
            }
        )
    }
}
