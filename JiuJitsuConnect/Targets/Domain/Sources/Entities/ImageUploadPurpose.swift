//
//  ImageUploadPurpose.swift
//  Domain
//
//  Created by suni on 5/31/26.
//

import Foundation

/// 이미지 호스팅 업로드의 사용 맥락.
///
/// `ImageUploadRepository.uploadImage(_:purpose:)` 호출 시 전달되어 Data 레이어가
/// 적절한 호스팅 폴더와 파일명 prefix를 결정하도록 한다. 호스팅 측에서 사용처별
/// 스토리지/대역폭/검색이 분리되어 관리하기 용이해진다.
public enum ImageUploadPurpose: Sendable, Equatable {
    /// 프로필 이미지 — 헤더 아바타로 즉시 노출되는 1:1 크롭 이미지
    case profileImage

    /// 관장 사범 인증 사진 — 관리자 검수용, 외부 노출 없음
    case instructorVerification
}
