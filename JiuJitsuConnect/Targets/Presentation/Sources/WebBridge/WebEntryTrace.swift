//
//  WebEntryTrace.swift
//  Presentation
//
//  쌓이는 웹 화면(게시글 상세·글쓰기 등)에 들어갈 때 단계별로 걸린 시간을 한 줄로 남긴다(#298).
//  상세 진입 속도 개선의 전/후 비교 기준. DEBUG·BETA에서만 기록하고, 운영 빌드에서는 시작 시각도 잡지 않는다.
//

import Foundation
import CoreKit

/// 상세 진입 단계별 시간 측정.
///
/// - 시작 시각(t0)은 상세 State를 만든 순간이다(`Origin`). State는 값만 들고 기록은 웹뷰(BridgeWebView)만 한다 —
///   진입로가 몇 곳이든 빠지지 않고, 리듀서가 전역 상태를 건드리지 않게.
/// - 키는 웹뷰를 만들 때의 `loadToken`. 처음 로드만 잰다 — 다시 시도는 실패로 이미 끝났고, 첫 로드 중 당겨서
///   새로고침하면 `refreshed`로 끝맺는다. `Origin`이 없는 웹(홈 피드·대회 탭 첫 화면)은 기록하지 않는다.
/// - `launch`: 앱 프로세스 시작부터 t0까지. 꺼진 앱 진입이면 스플래시 시간이 들어간다
/// - `result`
///   - `ok`: 완료(didFinish)와 PAGE_READY가 둘 다 옴
///   - `nopage`: 완료 뒤 `pageReadyGrace` 안에 PAGE_READY가 없음. 원래 안 보내는 화면(밸런스 상세 등)이나
///     삭제·오류 화면, 또는 늦게 오는 중
///   - `late_page`: `nopage`로 남긴 뒤 PAGE_READY가 옴(토큰 갱신 뒤 다시 그리는 등). 그 값까지 한 줄 더 남긴다
///   - `failed` / `closed` / `refreshed`: 완료 전에 실패·닫힘·새로고침
///
/// 메인 스레드(웹뷰·코디네이터)에서만 부르므로 `HomeFeedPreloader`처럼 MainActor 정적 상태로 둔다.
@MainActor
enum WebEntryTrace {
    /// 상세 State를 만든 순간과 진입 경로.
    /// 시각은 만들 때마다 달라 State 비교에서 뺀다. 진입 경로는 비교한다.
    struct Origin: Equatable, Sendable {
        let startedAt: ContinuousClock.Instant
        var via: Via

        nonisolated init(via: Via = .subview) {
            self.startedAt = .now
            self.via = via
        }

        nonisolated static func == (lhs: Origin, rhs: Origin) -> Bool { lhs.via == rhs.via }
    }

    enum Via: String, Sendable {
        /// 앱 안에서 쌓은 화면(OPEN_SUBVIEW, 알림함·내 활동 등 네이티브 버튼).
        case subview
        /// 공유 링크·푸시로 연 화면.
        case deeplink
    }

    enum Stage: String, CaseIterable, Sendable {
        case webView = "webview"
        case load
        case commit
        case ready
        case page
        case finish
    }

    enum Outcome: String, Sendable {
        case failed
        case closed
        case refreshed
    }

    static func begin(token: UUID, origin: Origin, url: URL) {
        #if DEBUG || BETA
        sequence += 1
        entries[token] = Entry(
            origin: origin,
            path: url.path,
            sequence: sequence,
            launch: millisecondsSinceProcessStart(at: origin)
        )
        #endif
    }

    static func mark(_ stage: Stage, token: UUID) {
        #if DEBUG || BETA
        guard var entry = entries[token], entry.marks[stage] == nil else { return }
        // 같은 단계가 다시 와도(웹 안에서의 이동 등) 처음 시각만 둔다.
        entry.marks[stage] = milliseconds(.now - entry.origin.startedAt)
        if entry.marks[.finish] != nil, entry.marks[.page] != nil {
            entries[token] = nil
            log(entry, result: entry.isReported ? "late_page" : "ok")
            return
        }
        entries[token] = entry
        if stage == .finish {
            Task {
                try? await Task.sleep(for: pageReadyGrace)
                reportMissingPage(token: token)
            }
        }
        #endif
    }

    static func end(_ outcome: Outcome, token: UUID) {
        #if DEBUG || BETA
        guard let entry = entries.removeValue(forKey: token), !entry.isReported else { return }
        // 첫 로드를 다 마친 뒤의 닫힘·새로고침은 진입을 끊은 게 아니다.
        log(entry, result: entry.marks[.finish] != nil ? "nopage" : outcome.rawValue)
        #endif
    }

    #if DEBUG || BETA
    private struct Entry {
        let origin: Origin
        let path: String
        let sequence: Int
        // 앱 프로세스 시작 → t0. 꺼진 앱을 링크로 열면 스플래시 시간이 여기 들어가 #300 전/후를 볼 수 있고,
        // 값의 크기로 꺼진 앱 진입과 켜진 앱 진입이 갈린다. 읽지 못하면 nil.
        let launch: Int?
        var marks: [Stage: Int] = [:]
        // `nopage`로 이미 남김. 늦은 PAGE_READY를 기다리는 중.
        var isReported = false

        func line(result: String) -> String {
            let stages = Stage.allCases
                .map { stage in "\(stage.rawValue)=\(marks[stage].map { "+\($0)" } ?? "-")" }
                .joined(separator: " ")
            let launchText = launch.map { "+\($0)" } ?? "-"
            return "[entry] seq=\(sequence) via=\(origin.via.rawValue) \(path) launch=\(launchText) \(stages) result=\(result)"
        }
    }

    private static var entries: [UUID: Entry] = [:]
    // 앱 실행 후 몇 번째 상세 진입인지(첫 진입과 그다음을 나눠 보기 위해).
    private static var sequence = 0
    // 시뮬레이터에서 PAGE_READY가 완료보다 1ms 늦게 온 적이 있어, 완료 즉시 `nopage`로 보지 않고 잠깐 기다린다.
    private static let pageReadyGrace: Duration = .seconds(2)

    private static func reportMissingPage(token: UUID) {
        guard var entry = entries[token], !entry.isReported else { return }
        entry.isReported = true
        entries[token] = entry
        log(entry, result: "nopage")
    }

    private static func log(_ entry: Entry, result: String) {
        Log.trace(entry.line(result: result), category: .network, level: .info)
    }

    /// 프로세스 시작 시각(커널 기록, 벽시계)부터 t0까지의 ms. t0는 단조 시계라 지금까지 흐른 시간을 빼서 맞춘다.
    private static func millisecondsSinceProcessStart(at origin: Origin) -> Int? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&name, UInt32(name.count), &info, &size, nil, 0) == 0 else { return nil }
        let start = info.kp_proc.p_starttime
        let processStart = Date(timeIntervalSince1970: TimeInterval(start.tv_sec) + TimeInterval(start.tv_usec) / 1_000_000)
        let sinceOrigin = milliseconds(.now - origin.startedAt)
        return Int((Date.now.timeIntervalSince(processStart) * 1000).rounded()) - sinceOrigin
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        Int((duration / .milliseconds(1)).rounded())
    }
    #endif
}
