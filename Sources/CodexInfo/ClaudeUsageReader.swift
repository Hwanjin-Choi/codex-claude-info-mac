import Foundation

actor ClaudeUsageReader {
    func readLastEightDays() -> [DailyUsage] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -8, to: Calendar.current.startOfDay(for: Date())) ?? .distantPast
        var totals: [Date: Int] = [:]
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            home.appendingPathComponent(".claude/projects", isDirectory: true),
            home.appendingPathComponent("Library/Application Support/Claude/local-agent-mode-sessions", isDirectory: true)
        ]

        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                guard url.pathExtension == "jsonl",
                      let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                      values.isRegularFile == true,
                      values.contentModificationDate ?? .distantPast >= cutoff else { continue }
                aggregate(url: url, cutoff: cutoff, into: &totals)
            }
        }

        return totals.map { DailyUsage(date: $0.key, tokens: $0.value) }
            .sorted { $0.date < $1.date }
    }

    func readDesktopSnapshot() -> ClaudeDesktopSnapshot? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let support = home.appendingPathComponent("Library/Application Support/Claude", isDirectory: true)
        var snapshot = newestDesktopSession(
            under: support.appendingPathComponent("claude-code-sessions", isDirectory: true)
        )

        let usageURL = support.appendingPathComponent("plan-usage-history.json")
        if let data = try? Data(contentsOf: usageURL),
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let samples = root["samples"] as? [[String: Any]],
           let sample = samples.max(by: {
               ($0["t"] as? NSNumber)?.doubleValue ?? 0 < ($1["t"] as? NSNumber)?.doubleValue ?? 0
           }),
           let usage = sample["u"] as? [String: Any] {
            if snapshot == nil {
                snapshot = ClaudeDesktopSnapshot(updatedAt: Date(), sessionID: nil, sessionName: nil,
                                                  modelID: nil, effort: nil,
                                                  fiveHourPercentage: nil, sevenDayPercentage: nil)
            }
            snapshot?.fiveHourPercentage = (usage["fh"] as? NSNumber)?.doubleValue
            snapshot?.sevenDayPercentage = (usage["sd"] as? NSNumber)?.doubleValue
            if let milliseconds = (sample["t"] as? NSNumber)?.doubleValue {
                let previousUpdate = snapshot?.updatedAt ?? .distantPast
                snapshot?.updatedAt = max(
                    previousUpdate,
                    Date(timeIntervalSince1970: milliseconds / 1_000)
                )
            }
        }
        return snapshot
    }

    private func newestDesktopSession(under root: URL) -> ClaudeDesktopSnapshot? {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var newest: (date: Date, json: [String: Any])?
        for case let url as URL in enumerator {
            guard url.pathExtension == "json",
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  modified > newest?.date ?? .distantPast,
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["sessionId"] is String else { continue }
            newest = (modified, json)
        }
        guard let newest else { return nil }
        let milliseconds = (newest.json["lastActivityAt"] as? NSNumber)?.doubleValue
        return ClaudeDesktopSnapshot(
            updatedAt: milliseconds.map { Date(timeIntervalSince1970: $0 / 1_000) } ?? newest.date,
            sessionID: newest.json["cliSessionId"] as? String ?? newest.json["sessionId"] as? String,
            sessionName: newest.json["title"] as? String,
            modelID: newest.json["model"] as? String,
            effort: newest.json["effort"] as? String,
            fiveHourPercentage: nil,
            sevenDayPercentage: nil
        )
    }

    private func aggregate(url: URL, cutoff: Date, into totals: inout [Date: Int]) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") {
            guard let data = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  object["type"] as? String == "assistant",
                  let timestamp = object["timestamp"] as? String,
                  let date = ISO8601DateFormatter().date(from: timestamp),
                  date >= cutoff,
                  let message = object["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any] else { continue }

            let keys = ["input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"]
            let tokens = keys.reduce(0) { $0 + ((usage[$1] as? NSNumber)?.intValue ?? 0) }
            let day = Calendar.current.startOfDay(for: date)
            totals[day, default: 0] += tokens
        }
    }
}
