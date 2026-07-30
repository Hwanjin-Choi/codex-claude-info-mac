import Charts
import SwiftUI

struct MenuContent: View {
    @EnvironmentObject private var monitor: CodexMonitor
    @EnvironmentObject private var claudeMonitor: ClaudeMonitor
    @AppStorage("selectedProvider") private var selectedProvider = "codex"
    @AppStorage("petSize") private var petSize = 88.0
    @AppStorage("petSpeed") private var petSpeed = 1.0
    @AppStorage("petAnimated") private var petAnimated = true
    @AppStorage("customPetName") private var customPetName = "짱구 코디"
    @AppStorage("usageAlerts") private var usageAlerts = true
    @State private var settingsExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("서비스", selection: $selectedProvider) {
                Text("Codex").tag("codex")
                Text("Claude").tag("claude")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            ScrollView {
                if selectedProvider == "claude" {
                    ClaudeDashboard()
                        .environmentObject(claudeMonitor)
                } else {
                    codexDashboard
                }
            }
        }
        .frame(width: 390, height: 620)
        .task { await monitor.start() }
        .task { await claudeMonitor.start() }
    }

    private var codexDashboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            workStatus

            if let error = monitor.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }

            ForEach(monitor.limits) { limit in
                LimitCard(limit: limit)
            }

            resetReport
            todaySummary
            modelCard
            weeklyReport
            petSettings
            footer
        }
        .padding(16)
    }

    private var header: some View {
        HStack {
            PetView(state: petState, size: petSize, speed: petSpeed, animated: petAnimated)
            VStack(alignment: .leading, spacing: 3) {
                Text("Codex Info").font(.title3.weight(.bold))
                Text(customPetName).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    .lineLimit(1)
                Label(monitor.health.title, systemImage: monitor.health.symbol)
                    .font(.caption2).foregroundStyle(monitor.health.color)
            }
            Spacer()
        }
    }

    private var workStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: monitor.workState.symbol)
                .font(.title3)
                .foregroundStyle(monitor.workState == .working ? .blue : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.workState.title).font(.subheadline.weight(.semibold))
                Text(monitor.currentTaskTitle)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if monitor.workState == .working { ProgressView().controlSize(.small) }
        }
        .cardStyle()
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("어제 사용량", symbol: "chart.bar.fill")
            HStack(spacing: 0) {
                Metric(value: monitor.yesterdayTokens.compactTokens, label: "어제 토큰")
                Metric(value: "\(monitor.usageSummary.currentStreakDays)일", label: "연속 사용")
                Metric(value: monitor.usageSummary.longestTurnSeconds.durationText, label: "최장 작업")
            }
        }
        .cardStyle()
    }

    private var resetReport: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.title2)
                .foregroundStyle(monitor.latestResetReport == nil ? Color.secondary : Color.green)
            VStack(alignment: .leading, spacing: 3) {
                Text("최근 초기화").font(.subheadline.weight(.semibold))
                Text(monitor.latestReport)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("모델", symbol: "cpu")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monitor.modelName).font(.subheadline.weight(.semibold))
                    Text("현재 작업 모델").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(monitor.reasoningEffort)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.blue.opacity(0.12), in: Capsule())
            }
        }
        .cardStyle()
    }

    private var weeklyReport: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionTitle("최근 7일", symbol: "calendar")
                Spacer()
                Text("\(monitor.weekTokens.compactTokens) tokens")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if monitor.dailyUsage.isEmpty {
                Text("사용량 데이터가 아직 없습니다.")
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 70)
            } else {
                Chart(monitor.dailyUsage) { item in
                    BarMark(
                        x: .value("요일", item.weekday),
                        y: .value("토큰", item.tokens)
                    )
                    .foregroundStyle(Calendar.current.isDateInToday(item.date) ? Color.blue : Color.blue.opacity(0.38))
                    .cornerRadius(3)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in AxisValueLabel().font(.caption2) }
                }
                .frame(height: 92)
            }
        }
        .cardStyle()
    }

    private var petSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { settingsExpanded.toggle() }
            } label: {
                HStack {
                    SectionTitle("펫 설정", symbol: "pawprint.fill")
                    Spacer()
                    Image(systemName: settingsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if settingsExpanded {
                PetPickerControls()
                Toggle("애니메이션", isOn: $petAnimated)
                Toggle("사용량·리셋 알림", isOn: $usageAlerts)
                LabeledContent("크기") {
                    Slider(value: $petSize, in: 64...112, step: 8).frame(width: 145)
                }
                LabeledContent("속도") {
                    Slider(value: $petSpeed, in: 0.5...2, step: 0.25).frame(width: 145)
                }
                .disabled(!petAnimated)
            }
        }
        .font(.caption)
        .cardStyle()
    }

    private var footer: some View {
        HStack {
            Text(monitor.lastUpdatedText).font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Button {
                Task { await monitor.refresh() }
            } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
            .disabled(monitor.isRefreshing)
            Button("종료") { NSApplication.shared.terminate(nil) }
        }
    }

    private var petState: PetState {
        if case .degraded = monitor.health { return .failed }
        return monitor.workState == .working || monitor.isRefreshing ? .working : .idle
    }
}

private struct ClaudeDashboard: View {
    @EnvironmentObject private var monitor: ClaudeMonitor
    @AppStorage("petSize") private var petSize = 88.0
    @AppStorage("petSpeed") private var petSpeed = 1.0
    @AppStorage("petAnimated") private var petAnimated = true
    @AppStorage("customPetName") private var customPetName = "짱구 코디"
    @State private var settingsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            integrationCard
            workCard

            ForEach(monitor.limits) { LimitCard(limit: $0) }

            resetCard
            usageCard
            modelCard
            weeklyCard
            petSettings
            footer
        }
        .padding(16)
    }

    private var header: some View {
        HStack {
            PetView(state: petState, size: petSize, speed: petSpeed, animated: petAnimated)
            VStack(alignment: .leading, spacing: 3) {
                Text("Claude Info").font(.title3.weight(.bold))
                Text(customPetName).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    .lineLimit(1)
                Label(monitor.integration.title, systemImage: monitor.integrationIsInstalled ? "checkmark.circle.fill" : "link.badge.plus")
                    .font(.caption2)
                    .foregroundStyle(monitor.integrationIsInstalled ? .green : .orange)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var integrationCard: some View {
        if !monitor.integrationIsInstalled {
            HStack(spacing: 10) {
                Image(systemName: "link.badge.plus").font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude Code 연동 필요").font(.subheadline.weight(.semibold))
                    Text("기존 설정을 백업하고 상태줄과 hooks를 안전하게 연결합니다.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button("연동 설치") { monitor.installIntegration() }
                    .disabled(monitor.isInstalling)
            }
            .cardStyle()
        }
    }

    private var workCard: some View {
        HStack(spacing: 10) {
            Image(systemName: monitor.workState.symbol)
                .font(.title3)
                .foregroundStyle(monitor.workState == .working ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(claudeWorkTitle).font(.subheadline.weight(.semibold))
                Text(monitor.taskTitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if monitor.workState == .working { ProgressView().controlSize(.small) }
        }
        .cardStyle()
    }

    private var resetCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.counterclockwise.circle.fill").font(.title2).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("최근 초기화").font(.subheadline.weight(.semibold))
                Text(monitor.latestReport).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .cardStyle()
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("어제 사용량", symbol: "chart.bar.fill")
            HStack(spacing: 0) {
                Metric(value: monitor.yesterdayTokens.compactTokens, label: "어제 토큰")
                Metric(value: monitor.contextText, label: "현재 세션")
                Metric(value: sessionDuration, label: "작업 시간")
            }
        }
        .cardStyle()
    }

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("모델", symbol: "cpu")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monitor.modelName).font(.subheadline.weight(.semibold))
                    Text(monitor.capturedState?.thinkingEnabled == true ? "확장 사고 켜짐" : "현재 Claude 모델")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(monitor.effort)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.orange.opacity(0.14), in: Capsule())
            }
        }
        .cardStyle()
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionTitle("최근 7일", symbol: "calendar")
                Spacer()
                Text("\(monitor.weekTokens.compactTokens) tokens")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if monitor.dailyUsage.isEmpty {
                Text("로컬 Claude 사용 기록이 아직 없습니다.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 70)
            } else {
                Chart(monitor.dailyUsage.suffix(7)) { item in
                    BarMark(x: .value("요일", item.weekday), y: .value("토큰", item.tokens))
                        .foregroundStyle(.orange.opacity(0.75))
                        .cornerRadius(3)
                }
                .chartYAxis(.hidden)
                .frame(height: 92)
            }
        }
        .cardStyle()
    }

    private var petSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { settingsExpanded.toggle() }
            } label: {
                HStack {
                    SectionTitle("펫 설정", symbol: "pawprint.fill")
                    Spacer()
                    Image(systemName: settingsExpanded ? "chevron.up" : "chevron.down")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if settingsExpanded {
                PetPickerControls()
                Toggle("애니메이션", isOn: $petAnimated)
                LabeledContent("크기") { Slider(value: $petSize, in: 64...112, step: 8).frame(width: 145) }
                LabeledContent("속도") { Slider(value: $petSpeed, in: 0.5...2, step: 0.25).frame(width: 145) }
                    .disabled(!petAnimated)
            }
        }
        .font(.caption)
        .cardStyle()
    }

    private var footer: some View {
        HStack {
            Text(monitor.capturedState?.updatedAt.formatted(date: .omitted, time: .shortened) ?? "Claude 데이터 대기 중")
                .font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Button { Task { await monitor.refresh() } } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
            Button("종료") { NSApplication.shared.terminate(nil) }
        }
    }

    private var petState: PetState {
        switch monitor.workState {
        case .working: .working
        case .waiting: .waiting
        case .failed: .failed
        default: .idle
        }
    }

    private var claudeWorkTitle: String {
        switch monitor.workState {
        case .working: "Claude 작업 중"
        case .waiting: "Claude 승인·입력 대기"
        case .recentlyCompleted: "Claude 작업 완료"
        case .failed: "Claude 작업 오류"
        case .checking: "Claude 상태 확인 중"
        case .idle: "Claude 대기 중"
        }
    }

    private var sessionDuration: String {
        let seconds = (monitor.capturedState?.durationMS ?? 0) / 1_000
        return seconds.durationText
    }
}

private struct LimitCard: View {
    let limit: UsageLimit

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(limit.title).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(limit.usedPercent.rounded()))% 사용")
                        .font(.caption.monospacedDigit())
                }
                ProgressView(value: min(max(limit.usedPercent, 0), 100), total: 100)
                    .tint(limit.usedPercent >= 90 ? .red : limit.usedPercent >= 70 ? .orange : .blue)
                HStack {
                    Text(limit.windowText)
                    Spacer()
                    if limit.resetKnown == false {
                        Label("리셋 시각 확인 중", systemImage: "timer")
                    } else {
                        Label(countdown(to: limit.resetsAt, now: context.date), systemImage: "timer")
                    }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
            .cardStyle()
        }
    }

    private func countdown(to date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        if seconds >= 86_400 { return "\(seconds / 86_400)일 \((seconds % 86_400) / 3_600)시간" }
        if seconds >= 3_600 { return "\(seconds / 3_600)시간 \((seconds % 3_600) / 60)분" }
        return "\(seconds / 60)분 \(seconds % 60)초 후 리셋"
    }
}

private struct Metric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.bold).monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionTitle: View {
    let title: String
    let symbol: String

    init(_ title: String, symbol: String) {
        self.title = title
        self.symbol = symbol
    }

    var body: some View {
        Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
    }
}

private extension View {
    func cardStyle() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }
}

private extension Int {
    var compactTokens: String {
        if self >= 100_000_000 {
            let eok = self / 100_000_000
            let man = (self % 100_000_000) / 10_000
            return man > 0 ? "\(eok)억 \(man.formatted())만" : "\(eok)억"
        }
        if self >= 10_000 {
            return "\((self / 10_000).formatted())만"
        }
        return self.formatted()
    }

    var durationText: String {
        if self >= 3_600 { return "\(self / 3_600)시간" }
        if self >= 60 { return "\(self / 60)분" }
        return "\(self)초"
    }
}
