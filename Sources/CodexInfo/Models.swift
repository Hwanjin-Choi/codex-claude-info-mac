import SwiftUI

struct UsageLimit: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: Date

    var resetText: String {
        resetsAt.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    var windowText: String {
        if windowMinutes >= 1_440 { return "\(windowMinutes / 1_440)일 한도" }
        if windowMinutes >= 60 { return "\(windowMinutes / 60)시간 한도" }
        return "\(windowMinutes)분 한도"
    }
}

struct ResetReport: Codable {
    let date: Date
    let message: String
}

struct DailyUsage: Identifiable, Codable, Equatable {
    let date: Date
    let tokens: Int

    var id: Date { date }
    var weekday: String { date.formatted(.dateTime.weekday(.narrow)) }
}

struct UsageSummary {
    var lifetimeTokens = 0
    var peakDailyTokens = 0
    var longestTurnSeconds = 0
    var currentStreakDays = 0
}

enum WorkState {
    case checking, working, recentlyCompleted, idle, failed

    var title: String {
        switch self {
        case .checking: "상태 확인 중"
        case .working: "Codex 작업 중"
        case .recentlyCompleted: "최근 작업 완료"
        case .idle: "대기 중"
        case .failed: "연결 오류"
        }
    }

    var detail: String {
        switch self {
        case .checking: "로컬 작업 상태를 확인하고 있습니다."
        case .working: "Codex가 응답을 생성하거나 명령을 실행 중입니다."
        case .recentlyCompleted: "방금 작업이 갱신되었습니다."
        case .idle: "새로운 작업을 기다리고 있습니다."
        case .failed: "Codex App Server 연결을 확인하세요."
        }
    }

    var symbol: String {
        switch self {
        case .checking: "circle.dotted"
        case .working: "bolt.fill"
        case .recentlyCompleted: "checkmark.circle.fill"
        case .idle: "pause.circle"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

enum APIHealth {
    case checking, healthy, degraded

    var title: String {
        switch self { case .checking: "확인 중"; case .healthy: "정상"; case .degraded: "점검 필요" }
    }
    var symbol: String {
        switch self { case .checking: "circle.dotted"; case .healthy: "checkmark.circle.fill"; case .degraded: "exclamationmark.circle.fill" }
    }
    var color: Color {
        switch self { case .checking: .secondary; case .healthy: .green; case .degraded: .orange }
    }
}
