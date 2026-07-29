import Foundation

@MainActor
final class ClaudeMonitor: ObservableObject {
    @Published var integration: ClaudeIntegrationState = .checking
    @Published var capturedState: ClaudeCapturedState?
    @Published var limits: [UsageLimit] = []
    @Published var dailyUsage: [DailyUsage] = []
    @Published var latestReport = "아직 감지된 초기화가 없습니다."
    @Published var isInstalling = false
    @Published var errorMessage: String?

    private let usageReader = ClaudeUsageReader()
    private var pollingTask: Task<Void, Never>?
    private var lastUsageRead = Date.distantPast
    private let reportsKey = "claudeResetReports"
    private let snapshotKey = "claudeUsageSnapshot"

    var menuTitle: String {
        guard let first = limits.first else { return "Claude" }
        return "Claude \(Int(first.usedPercent.rounded()))%"
    }

    var modelName: String { capturedState?.modelName ?? "Claude 모델 대기 중" }
    var effort: String { capturedState?.effort?.capitalized ?? "기본 추론" }
    var contextText: String {
        guard let value = capturedState?.contextPercentage else { return "컨텍스트 대기 중" }
        return "컨텍스트 \(Int(value.rounded()))%"
    }

    var workState: WorkState {
        guard integrationIsInstalled else { return .checking }
        guard let state = capturedState else { return .idle }
        if state.lastError != nil { return .failed }
        switch state.workState {
        case "working": return .working
        case "waiting": return .waiting
        case "completed": return .recentlyCompleted
        case "failed": return .failed
        default: return .idle
        }
    }

    var taskTitle: String {
        if capturedState?.lastError == "authentication_failed" {
            return "Claude 로그인이 만료되었습니다. claude auth login이 필요합니다."
        }
        if let error = capturedState?.lastError, !error.isEmpty { return error }
        return capturedState?.sessionName
            ?? capturedState?.sessionID.map { "세션 \($0.prefix(8))" }
            ?? "Claude를 실행해 데이터를 받아오세요."
    }

    var yesterdayTokens: Int {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        return dailyUsage.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })?.tokens ?? 0
    }

    var weekTokens: Int { dailyUsage.reduce(0) { $0 + $1.tokens } }
    var integrationIsInstalled: Bool {
        if case .installed = integration { return true }
        return false
    }

    func start() async {
        guard pollingTask == nil else { return }
        checkIntegration()
        await refresh()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        loadCapturedState()
        if Date().timeIntervalSince(lastUsageRead) >= 30 {
            dailyUsage = await usageReader.readLastEightDays()
            lastUsageRead = Date()
        }
    }

    func installIntegration() {
        guard !isInstalling else { return }
        isInstalling = true
        defer { isInstalling = false }
        do {
            try ClaudeIntegrationInstaller.install()
            integration = .installed
            errorMessage = nil
        } catch {
            integration = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    private func checkIntegration() {
        let settings = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
        guard let data = try? Data(contentsOf: settings),
              let text = String(data: data, encoding: .utf8) else {
            integration = .notInstalled
            return
        }
        integration = text.contains("ClaudeInfoBridge") ? .installed : .notInstalled
    }

    private func loadCapturedState() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Claude Info/state.json")
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(ClaudeCapturedState.self, from: data) else { return }
        capturedState = state
        limits = [
            state.fiveHour.map {
                UsageLimit(id: "claude-five-hour", title: "5시간 사용량", usedPercent: $0.usedPercentage,
                           windowMinutes: 300, resetsAt: $0.resetsAt)
            },
            state.sevenDay.map {
                UsageLimit(id: "claude-seven-day", title: "7일 사용량", usedPercent: $0.usedPercentage,
                           windowMinutes: 10_080, resetsAt: $0.resetsAt)
            }
        ].compactMap { $0 }
        recordResets()
    }

    private func recordResets() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        let old = defaults.data(forKey: snapshotKey).flatMap { try? decoder.decode([UsageLimit].self, from: $0) } ?? []
        var reports = defaults.data(forKey: reportsKey).flatMap { try? decoder.decode([ResetReport].self, from: $0) } ?? []
        for limit in limits {
            guard let previous = old.first(where: { $0.id == limit.id }) else { continue }
            if (previous.resetsAt <= Date() && limit.resetsAt > previous.resetsAt)
                || previous.usedPercent - limit.usedPercent >= 20 {
                reports.insert(ResetReport(
                    date: Date(),
                    message: "\(limit.title) 초기화 감지 · \(Int(previous.usedPercent))% → \(Int(limit.usedPercent))%"
                ), at: 0)
            }
        }
        reports = Array(reports.prefix(30))
        if let data = try? JSONEncoder().encode(reports) { defaults.set(data, forKey: reportsKey) }
        if let data = try? JSONEncoder().encode(limits) { defaults.set(data, forKey: snapshotKey) }
        if let report = reports.first {
            latestReport = "\(report.date.formatted(date: .abbreviated, time: .shortened)) · \(report.message)"
        }
    }
}
