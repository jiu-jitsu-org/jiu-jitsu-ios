//
//  ImageKitConfig.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// ImageKit 업로드에 필요한 상수와 런타임 secret을 한 곳에 모아둔다.
///
/// `IMAGEKIT_PUBLIC_KEY`는 `Configs/Secrets.xcconfig` → `Project.swift`의 appInfoPlist → Info.plist
/// 경로로 주입된다. 클라이언트에 노출되는 public 값이지만, 환경별 교체 가능성을 위해
/// `BASE_URL`과 동일한 패턴으로 관리한다.
enum ImageKitConfig {
    static let uploadBaseURL = "https://upload.imagekit.io"
    static let uploadPath    = "/api/v1/files/upload"
    /// ImageKit 폴더 (멀티 폴더 운용 필요해지면 enum/property로 분기)
    static let uploadFolder  = "community/profile"

    static var publicKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "IMAGEKIT_PUBLIC_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("IMAGEKIT_PUBLIC_KEY is not set in Info.plist")
        }
        return key
    }
}
