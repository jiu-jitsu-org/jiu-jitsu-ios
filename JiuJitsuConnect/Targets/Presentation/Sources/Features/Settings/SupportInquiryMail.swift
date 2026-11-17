//
//  SupportInquiryMail.swift
//  Presentation
//
//  Created by suni on 11/16/26.
//

import Foundation

/// 설정 › 문의하기 메일(#331). 받는 사람·제목과, 답할 때 필요한 기기 정보를 본문 맨 아래에 채운다.
enum SupportInquiryMail {
    static let subject = "[OSS 문의]"

    /// 문의를 받을 때 보는 기기 정보. 회원 번호는 로그인했을 때만 있다.
    struct DeviceInfo: Equatable, Sendable {
        let appVersion: String
        let buildNumber: String
        let osVersion: String
        let modelIdentifier: String
        let userId: Int?
        /// 앱을 켜 둔 동안 마지막으로 보인 오류(#379). 없으면 줄을 뺀다.
        var recentError: RecentError?

        static func current(userId: Int?, recentError: RecentError? = nil) -> DeviceInfo {
            let bundle = Bundle.main
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            return DeviceInfo(
                appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A",
                buildNumber: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A",
                osVersion: "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)",
                modelIdentifier: Self.currentModelIdentifier(),
                userId: userId,
                recentError: recentError
            )
        }

        /// `iPhone17,1` 같은 모델 식별자. 시뮬레이터는 `arm64`가 나오므로 흉내 내는 기기의 식별자를 쓴다.
        private static func currentModelIdentifier() -> String {
            if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return simulated
            }
            var systemInfo = utsname()
            uname(&systemInfo)
            let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
                String(bytes: buffer.prefix { $0 != 0 }, encoding: .utf8)
            }
            guard let identifier, !identifier.isEmpty else { return "unknown" }
            return identifier
        }
    }

    /// 사용자가 쓸 자리를 위에 비워 두고, 기기 정보는 구분선 아래에 둔다.
    static func body(for info: DeviceInfo) -> String {
        var lines = [
            "",
            "",
            "",
            "-----",
            "앱 버전: \(info.appVersion) (\(info.buildNumber))",
            "iOS 버전: \(info.osVersion)",
            "기기: \(info.modelIdentifier)"
        ]
        if let userId = info.userId {
            lines.append("회원 번호: \(userId)")
        }
        if let recentError = info.recentError {
            lines.append("최근 오류: \(recentError.code) (\(Self.errorTimeFormatter.string(from: recentError.occurredAt)))")
        }
        return lines.joined(separator: "\n")
    }

    /// 서버 기록과 맞춰 보기 쉬운 '2026.11.17 14:03' 꼴. 기기 시간대 그대로.
    private static let errorTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

    static func url(to email: String, info: DeviceInfo) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body(for: info))
        ]
        return components.url
    }
}
