//
//  AppVersionPolicy.swift
//  Domain
//
//  서버가 정한 OS별 최소 · 최신 앱 버전과, 지금 버전이 받아야 할 업데이트 안내(#326).
//

import Foundation

public struct AppVersionPolicy: Equatable, Sendable {
    /// 이보다 낮으면 쓸 수 없다(꼭 필요한 업데이트).
    public let minimumVersion: String
    /// 이보다 낮으면 새 버전을 권한다.
    public let latestVersion: String

    public init(minimumVersion: String, latestVersion: String) {
        self.minimumVersion = minimumVersion
        self.latestVersion = latestVersion
    }

    public func requirement(for currentVersion: String) -> AppUpdateRequirement {
        if AppVersionNumber(currentVersion) < AppVersionNumber(minimumVersion) {
            return .required
        }
        if AppVersionNumber(currentVersion) < AppVersionNumber(latestVersion) {
            return .recommended(latestVersion: latestVersion)
        }
        return .upToDate
    }
}

public enum AppUpdateRequirement: Equatable, Sendable {
    case upToDate
    case recommended(latestVersion: String)
    case required
}

/// 마디별 숫자로 비교한다(`1.10.0` > `1.9.0`). 빠진 마디는 0, 숫자가 아닌 마디도 0으로 본다(`1.0` == `1.0.0`).
public struct AppVersionNumber: Comparable, Sendable {
    private let parts: [Int]

    public init(_ version: String) {
        parts = version.split(separator: ".").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}
