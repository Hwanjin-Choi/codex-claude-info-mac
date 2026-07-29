import Foundation

actor ClaudeUsageReader {
    func readLastEightDays() -> [DailyUsage] {
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects", isDirectory: true)
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let cutoff = Calendar.current.date(byAdding: .day, value: -8, to: Calendar.current.startOfDay(for: Date())) ?? .distantPast
        var totals: [Date: Int] = [:]

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl",
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  values.contentModificationDate ?? .distantPast >= cutoff else { continue }
            aggregate(url: url, cutoff: cutoff, into: &totals)
        }

        return totals.map { DailyUsage(date: $0.key, tokens: $0.value) }
            .sorted { $0.date < $1.date }
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
