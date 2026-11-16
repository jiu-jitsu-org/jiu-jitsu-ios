//
//  AppStoreLink.swift
//  App
//

import Foundation

/// 스토어의 OSS 앱 페이지(#326). 업데이트 안내 · 설정 > 버전 정보의 '업데이트'가 연다.
enum AppStoreLink {
    /// App Store Connect의 Apple ID(숫자). 출시 전이라 아직 없다 — 정해지면 넣는다. 없으면 업데이트 버튼이 아무것도 열지 않는다.
    static let appID: String? = nil

    static var url: URL? {
        appID.flatMap { URL(string: "itms-apps://apps.apple.com/app/id\($0)") }
    }
}
