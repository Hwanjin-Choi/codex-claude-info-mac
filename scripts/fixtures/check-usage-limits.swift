import Foundation

@main
enum CheckUsageLimits {
    static func main() throws {
        let payload = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))) as! [String: Any]
        let limits = CodexRateLimits.parse(payload)
        precondition(limits.count == 4)
        precondition(limits.first?.id == "codex-primary")
        precondition(limits.first?.title == "Codex · 주간 사용량")
        precondition(CodexRateLimits.menuTitle(for: limits) == "Codex 주간 36%")
        precondition(CodexRateLimits.weekly(in: limits.reversed())?.usedPercent == 36)
        precondition(limits.last?.title == "Luna Reserve (예비) · 주간 사용량")
        precondition(limits.contains { $0.title == "GPT-5.3-Codex-Spark · 5시간 사용량" })

        let withoutCodex = limits.filter { $0.id != "codex-primary" }
        precondition(CodexRateLimits.weekly(in: withoutCodex) == nil)
        precondition(CodexRateLimits.menuTitle(for: withoutCodex) == "Codex 주간 —")

        let legacy: [String: Any] = ["rateLimitsByLimitId": [:], "rateLimits": [
            "primary": ["usedPercent": 90, "windowDurationMins": 300, "resetsAt": 2_000_000_000],
            "secondary": ["usedPercent": 42, "windowDurationMins": 10080, "resetsAt": 2_000_000_000]
        ]]
        let legacyLimits = CodexRateLimits.parse(legacy)
        precondition(legacyLimits.first?.id == "codex-secondary")
        precondition(CodexRateLimits.menuTitle(for: legacyLimits) == "Codex 주간 42%")
        precondition(CodexRateLimits.weekly(in: legacyLimits.filter { $0.windowMinutes == 300 }) == nil)
        precondition(CodexRateLimits.parse(["rateLimits": NSNull()]).isEmpty)
        print("Weekly selection, reserve isolation, duration labels, legacy fallback and missing weekly data: passed")
    }
}
