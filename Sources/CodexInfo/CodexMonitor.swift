import Foundation
import UserNotifications

@MainActor
final class CodexMonitor: ObservableObject {
    @Published var limits: [UsageLimit] = []
    @Published var modelName = "모델 확인 중"
    @Published var health: APIHealth = .checking
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var isRefreshing = false
    @Published var workState: WorkState = .checking
    @Published var currentTaskTitle = "작업 상태 확인 중"
    @Published var reasoningEffort = "확인 중"
    @Published var usageSummary = UsageSummary()
    @Published var dailyUsage: [DailyUsage] = []
    @Published var usageAvailable = false

    private let server = CodexAppServer()
    private let localReader = LocalCodexReader()
    private var timerTask: Task<Void, Never>?
    private let reportKey = "resetReports"
    private let snapshotKey = "usageSnapshot"

    var menuTitle: String {
        guard let first = limits.first else { return "Codex" }
        return "Codex \(Int(first.usedPercent.rounded()))%"
    }

    var lastUpdatedText: String {
        guard let lastUpdated else { return "업데이트 전" }
        return "업데이트 \(lastUpdated.formatted(date: .omitted, time: .shortened))"
    }

    var latestResetReport: ResetReport? {
        guard let data = UserDefaults.standard.data(forKey: reportKey),
              let report = try? JSONDecoder().decode([ResetReport].self, from: data).first else { return nil }
        return report
    }

    var latestReport: String {
        guard let report = latestResetReport else { return "아직 감지된 초기화가 없습니다." }
        return "\(report.date.formatted(date: .abbreviated, time: .shortened)) · \(report.message)"
    }

    func start() async {
        guard timerTask == nil else { return }
        timerTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            async let rateResponse = server.request("account/rateLimits/read")
            async let modelResponse = try? server.request("model/list", params: JSONDictionary(["limit": 100, "includeHidden": false]))
            async let usageResponse = try? server.request("account/usage/read")
            async let localStatus = localReader.readStatus()
            let (rateResult, modelResult, usageResult, status) = try await (rateResponse, modelResponse, usageResponse, localStatus)
            limits = parseLimits(rateResult.value)
            modelName = status.model ?? configuredModel() ?? defaultModel(from: modelResult?.value ?? [:]) ?? "Codex 권장 모델"
            reasoningEffort = displayEffort(status.effort)
            workState = status.workState
            currentTaskTitle = status.taskTitle
            usageAvailable = usageResult?.value["dailyUsageBuckets"] is [[String: Any]]
            if let usageResult { parseUsage(usageResult.value) }
            recordResets(newLimits: limits)
            scheduleUsageNotifications()
            health = .healthy
            errorMessage = nil
            lastUpdated = Date()
        } catch {
            health = .degraded
            workState = .failed
            errorMessage = error.localizedDescription
            lastUpdated = Date()
        }
    }

    var todayTokens: Int {
        let calendar = Calendar.current
        return dailyUsage.first(where: { calendar.isDateInToday($0.date) })?.tokens ?? 0
    }

    var yesterdayTokens: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        return dailyUsage.first(where: { calendar.isDate($0.date, inSameDayAs: yesterday) })?.tokens ?? 0
    }

    var weekTokens: Int { dailyUsage.reduce(0) { $0 + $1.tokens } }

    private func parseLimits(_ result: [String: Any]) -> [UsageLimit] {
        if let buckets = result["rateLimitsByLimitId"] as? [String: Any] {
            return buckets.keys.sorted().flatMap { key -> [UsageLimit] in
                guard let bucket = buckets[key] as? [String: Any] else { return [] }
                return windows(bucket, bucketID: key)
            }
        }
        if let bucket = result["rateLimits"] as? [String: Any] {
            return windows(bucket, bucketID: bucket["limitId"] as? String ?? "codex")
        }
        return []
    }

    private func windows(_ bucket: [String: Any], bucketID: String) -> [UsageLimit] {
        [("primary", "단기 사용량"), ("secondary", "주간 사용량")].compactMap { key, fallbackTitle in
            guard let value = bucket[key] as? [String: Any],
                  let used = (value["usedPercent"] as? NSNumber)?.doubleValue,
                  let mins = (value["windowDurationMins"] as? NSNumber)?.intValue,
                  let reset = (value["resetsAt"] as? NSNumber)?.doubleValue else { return nil }
            let bucketTitle = bucketID == "codex" ? fallbackTitle : "\(bucketID) · \(fallbackTitle)"
            return UsageLimit(id: "\(bucketID)-\(key)", title: bucketTitle, usedPercent: used,
                              windowMinutes: mins, resetsAt: Date(timeIntervalSince1970: reset))
        }
    }

    private func configuredModel() -> String? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let pattern = #"(?m)^\s*model\s*=\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private func defaultModel(from result: [String: Any]) -> String? {
        guard let models = result["data"] as? [[String: Any]] else { return nil }
        let selected = models.first(where: { ($0["isDefault"] as? Bool) == true }) ?? models.first
        return selected?["displayName"] as? String ?? selected?["model"] as? String
    }

    private func displayEffort(_ effort: String?) -> String {
        guard let effort, !effort.isEmpty else { return "기본 추론" }
        let labels = ["low": "Low", "medium": "Medium", "high": "High", "xhigh": "X-High", "max": "Max", "ultra": "Ultra"]
        return labels[effort] ?? effort.capitalized
    }

    private func parseUsage(_ result: [String: Any]) {
        if let summary = result["summary"] as? [String: Any] {
            usageSummary = UsageSummary(
                lifetimeTokens: (summary["lifetimeTokens"] as? NSNumber)?.intValue ?? 0,
                peakDailyTokens: (summary["peakDailyTokens"] as? NSNumber)?.intValue ?? 0,
                longestTurnSeconds: (summary["longestRunningTurnSec"] as? NSNumber)?.intValue ?? 0,
                currentStreakDays: (summary["currentStreakDays"] as? NSNumber)?.intValue ?? 0
            )
        }
        guard let buckets = result["dailyUsageBuckets"] as? [[String: Any]] else { return }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        dailyUsage = buckets.compactMap {
            guard let text = $0["startDate"] as? String,
                  let date = formatter.date(from: text),
                  let tokens = ($0["tokens"] as? NSNumber)?.intValue else { return nil }
            return DailyUsage(date: date, tokens: tokens)
        }
        .sorted { $0.date < $1.date }
        .suffix(7)
        .map { $0 }
    }

    private func scheduleUsageNotifications() {
        guard UserDefaults.standard.object(forKey: "usageAlerts") as? Bool ?? true else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        guard let primary = limits.first else { return }
        let threshold = primary.usedPercent >= 90 ? 90 : primary.usedPercent >= 80 ? 80 : nil
        if let threshold {
            notifyOnce(
                id: "usage-\(primary.id)-\(threshold)-\(Int(primary.resetsAt.timeIntervalSince1970))",
                title: "Codex 사용량 \(threshold)% 도달",
                body: "\(primary.resetText)에 리셋될 예정입니다."
            )
        }
        let remaining = primary.resetsAt.timeIntervalSinceNow
        if remaining > 0, remaining <= 3_600 {
            notifyOnce(
                id: "reset-soon-\(primary.id)-\(Int(primary.resetsAt.timeIntervalSince1970))",
                title: "Codex 사용량 리셋 임박",
                body: "약 \(Int(remaining / 60))분 후 사용량이 리셋됩니다."
            )
        }
    }

    private func notifyOnce(id: String, title: String, body: String) {
        let key = "notified.\(id)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
        UserDefaults.standard.set(true, forKey: key)
    }

    private func recordResets(newLimits: [UsageLimit]) {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        let previous = defaults.data(forKey: snapshotKey).flatMap { try? decoder.decode([UsageLimit].self, from: $0) } ?? []
        var reports = defaults.data(forKey: reportKey).flatMap { try? decoder.decode([ResetReport].self, from: $0) } ?? []

        for new in newLimits {
            guard let old = previous.first(where: { $0.id == new.id }) else { continue }
            let resetPassed = old.resetsAt <= Date() && new.resetsAt > old.resetsAt
            let usageDropped = old.usedPercent - new.usedPercent >= 20
            if resetPassed || usageDropped {
                reports.insert(ResetReport(date: Date(), message: "\(new.title) 리셋 감지 · \(Int(old.usedPercent))% → \(Int(new.usedPercent))%"), at: 0)
            }
        }
        reports = Array(reports.prefix(30))
        if let data = try? JSONEncoder().encode(reports) { defaults.set(data, forKey: reportKey) }
        if let data = try? JSONEncoder().encode(newLimits) { defaults.set(data, forKey: snapshotKey) }
    }
}
