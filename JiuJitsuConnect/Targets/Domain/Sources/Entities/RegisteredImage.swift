//
//  RegisteredImage.swift
//  Domain
//
//  Created by suni on 6/4/26.
//

import Foundation

/// 서버에 등록된 이미지.
///
/// CDN(ImageKit) 업로드를 마친 이미지를 BE에 등록하면 발급되는 식별 정보다.
/// 등록 직후에는 `TEMP` 상태로 저장되며, 게시물/프로필이 실제로 저장될 때 `ACTIVE`로 전환된다.
public struct RegisteredImage: Sendable, Equatable {
    /// 이미지 파일 ID — 삭제(`DELETE /api/image/{id}`) 시 사용한다.
    public let id: Int64
    /// CDN 식별자 — CDN에서의 삭제 연동에 사용된다.
    public let cdnId: String
    /// 호스팅된 이미지 절대 URL.
    public let imageUrl: String
    /// 등록 상태 (`TEMP` → 게시물/프로필 저장 시 `ACTIVE`).
    public let status: Status

    public init(id: Int64, cdnId: String, imageUrl: String, status: Status) {
        self.id = id
        self.cdnId = cdnId
        self.imageUrl = imageUrl
        self.status = status
    }

    public enum Status: String, Sendable {
        case temp = "TEMP"
        case active = "ACTIVE"
    }
}
