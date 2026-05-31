//
//  ImageKitConfig.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation
import Domain

/// ImageKit 업로드에 필요한 상수와 런타임 secret을 한 곳에 모아둔다.
///
/// `IMAGEKIT_PUBLIC_KEY`는 `Configs/Secrets.xcconfig` → `Project.swift`의 appInfoPlist → Info.plist
/// 경로로 주입된다. 클라이언트에 노출되는 public 값이지만, 환경별 교체 가능성을 위해
/// `BASE_URL`과 동일한 패턴으로 관리한다.
enum ImageKitConfig {
    static let uploadBaseURL = "https://upload.imagekit.io"
    static let uploadPath    = "/api/v1/files/upload"

    static var publicKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "IMAGEKIT_PUBLIC_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("IMAGEKIT_PUBLIC_KEY is not set in Info.plist")
        }
        return key
    }

    /// 업로드 폴더 — 사용 맥락별로 분리해 호스팅 측에서 스토리지/검색이 용이하도록 한다.
    static func uploadFolder(for purpose: ImageUploadPurpose) -> String {
        switch purpose {
        case .profileImage:           return "community/profile"
        case .instructorVerification: return "community/verification"
        }
    }

    /// 업로드 파일명 prefix — 호스팅 측 파일 목록에서 사용처 식별을 빠르게 한다.
    /// 실제 파일명에는 `\(prefix)_\(timestamp).jpg` 형태로 timestamp를 덧붙인다.
    static func filenamePrefix(for purpose: ImageUploadPurpose) -> String {
        switch purpose {
        case .profileImage:           return "profile"
        case .instructorVerification: return "verification"
        }
    }

    /// 업로드 페이로드 정규화 파라미터 — purpose별로 의도가 다르다.
    ///
    /// - `.profileImage`: 모바일 헤더 아바타(<= 414pt) 표시 전용 → 작게 만들어 트래픽/스토리지 절감
    /// - `.instructorVerification`: 관리자 검수용 → 사진 속 자격증/도장 명판 등 디테일이 보여야 하므로
    ///   원본에 가깝게 유지. 단 풀해상도(8K급) 그대로 보내면 ImageKit 업로드/대역폭 제약에 걸릴 수 있어
    ///   긴 변 2560px / 품질 0.85 정도로만 압축 (≈ 1~2MB)
    static func uploadCompression(for purpose: ImageUploadPurpose) -> (maxPixel: CGFloat, quality: CGFloat) {
        switch purpose {
        case .profileImage:           return (1024, 0.8)
        case .instructorVerification: return (2560, 0.85)
        }
    }
}
