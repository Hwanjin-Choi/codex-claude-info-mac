import Foundation

struct ClaudeLimitState: Codable {
    var usedPercentage: Double
    var resetsAt: Date
}

struct ClaudeCapturedState: Codable {
    var updatedAt: Date
    var sessionID: String?
    var sessionName: String?
    var modelID: String?
    var modelName: String?
    var effort: String?
    var thinkingEnabled: Bool?
    var contextPercentage: Double?
    var fiveHour: ClaudeLimitState?
    var sevenDay: ClaudeLimitState?
    var totalCostUSD: Double?
    var durationMS: Int?
    var workState: String
    var lastError: String?
}

struct ClaudeDesktopSnapshot: Sendable {
    var updatedAt: Date
    var sessionID: String?
    var sessionName: String?
    var modelID: String?
    var effort: String?
    var fiveHourPercentage: Double?
    var sevenDayPercentage: Double?
}

enum ClaudeIntegrationState {
    case checking, notInstalled, installed, failed(String)

    var title: String {
        switch self {
        case .checking: "연동 확인 중"
        case .notInstalled: "Claude 연동 필요"
        case .installed: "Claude 연동됨"
        case .failed: "연동 오류"
        }
    }
}
