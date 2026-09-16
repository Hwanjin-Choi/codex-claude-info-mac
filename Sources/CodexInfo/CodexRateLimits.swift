import Foundation

enum CodexRateLimits {
    static let weekMinutes = 7 * 24 * 60

    static func weekly(in limits: [UsageLimit]) -> UsageLimit? {
        limits.first {
            ($0.id == "codex-primary" || $0.id == "codex-secondary") && $0.windowMinutes == weekMinutes
        }
    }

    static func menuTitle(for limits: [UsageLimit]) -> String {
        guard let weekly = weekly(in: limits) else { return "Codex 주간 —" }
        return "Codex 주간 \(Int(weekly.usedPercent.rounded()))%"
    }

    static func parse(_ result: [String: Any]) -> [UsageLimit] {
        var buckets = result["rateLimitsByLimitId"] as? [String: Any] ?? [:]
        if let legacy = result["rateLimits"] as? [String: Any] {
            let id = legacy["limitId"] as? String ?? "codex"
            if buckets[id] == nil { buckets[id] = legacy }
        }
        return buckets.keys.sorted {
            let lhs = priority($0), rhs = priority($1)
            return lhs == rhs ? $0 < $1 : lhs < rhs
        }.flatMap { id -> [UsageLimit] in
            guard let bucket = buckets[id] as? [String: Any] else { return [] }
            let suppliedName = (bucket["limitName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = id == "codex" ? "Codex"
                : id == "base_model_inference" ? "Luna Reserve (예비)"
                : suppliedName.flatMap { $0.isEmpty ? nil : $0 } ?? id
            return ["primary", "secondary"].compactMap { key -> UsageLimit? in
                guard let value = bucket[key] as? [String: Any],
                      let used = (value["usedPercent"] as? NSNumber)?.doubleValue, used.isFinite,
                      let mins = (value["windowDurationMins"] as? NSNumber)?.intValue, mins > 0,
                      let reset = (value["resetsAt"] as? NSNumber)?.doubleValue, reset.isFinite else { return nil }
                return UsageLimit(id: "\(id)-\(key)", title: "\(name) · \(periodTitle(mins))", usedPercent: used,
                                  windowMinutes: mins, resetsAt: Date(timeIntervalSince1970: reset))
            }.sorted {
                if ($0.windowMinutes == weekMinutes) != ($1.windowMinutes == weekMinutes) {
                    return $0.windowMinutes == weekMinutes
                }
                return $0.windowMinutes == $1.windowMinutes ? $0.id < $1.id : $0.windowMinutes < $1.windowMinutes
            }
        }
    }

    private static func priority(_ id: String) -> Int {
        id == "codex" ? 0 : id == "base_model_inference" ? 2 : 1
    }

    private static func periodTitle(_ minutes: Int) -> String {
        if minutes == weekMinutes { return "주간 사용량" }
        if minutes.isMultiple(of: 1_440) { return "\(minutes / 1_440)일 사용량" }
        if minutes.isMultiple(of: 60) { return "\(minutes / 60)시간 사용량" }
        return "\(minutes)분 사용량"
    }
}
