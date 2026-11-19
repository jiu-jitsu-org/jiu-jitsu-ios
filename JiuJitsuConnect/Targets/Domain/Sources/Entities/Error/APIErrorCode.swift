//
//  APIErrorCode.swift
//  Domain
//
//  Created by suni on 10/27/25.
//

import Foundation

public enum APIErrorCode: String, Equatable {
    // MARK: - Auth (A0000)
    case socialVerificationFailed = "A0010" // 소셜 계정 확인 실패(인증 키 파싱) — 서버 이름 KEY_PARSING_ERROR
    case authenticationFailed = "A0011" // 인증 실패
    case notMatchCategory = "A0002" // 잘못된 유형의 토큰
    case expiredToken = "A0003" // 만료된 토큰
    case invalidRefreshToken = "A0009" // 유효하지 않은 refresh token
    
    // MARK: - Request (R0000)
    case wrongParameter = "R0002" // 잘못된 요청 데이터
    case nicknameDuplicated = "R0003" // 이미 사용중인 닉네임
    case invalidNickname = "R0004" // 잘못된 닉네임 형식

    // MARK: - User (U0000)
    case accountNotFound = "U0002" // 토큰의 회원이 없음 (인증 단계)
    case userNotFound = "U0011" // 존재하지 않는 회원 (탈퇴 유예 중인 작성자 포함)
    case alreadyWithdrawn = "U0004" // 이미 탈퇴 처리된 계정
    case withdrawnAccountExpired = "U0005" // 탈퇴 후 30일이 지나 영구 삭제된 계정
    case alreadyReported = "U0008" // 이미 신고한 대상 (글 · 댓글 · 회원)
        
    /// 클라이언트에서 알 수 없는 새로운 에러 코드를 처리하기 위한 케이스
    case unknown
    
    /// 토큰 갱신 응답이 이 코드면 세션이 끝난 것이다(#373). 갱신 · 자동 로그인이 같이 쓴다.
    /// 그 밖의 4xx(서버 앞단의 403 · 429 등)는 일시 실패로 보고 토큰을 지우지 않는다.
    public var endsSession: Bool {
        switch self {
        case .notMatchCategory, .expiredToken, .invalidRefreshToken, .accountNotFound:
            return true
        default:
            return false
        }
    }

    /// 사용자에게 보여줄 기본 에러 메시지
    public var displayMessage: String {
        switch self {
        default:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
