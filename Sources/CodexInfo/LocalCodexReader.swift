import Foundation

struct LocalCodexStatus: Sendable {
    let workState: WorkState
    let taskTitle: String
    let model: String?
    let effort: String?
}

actor LocalCodexReader {
    func readStatus() -> LocalCodexStatus {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let database = "\(home)/.codex/state_5.sqlite"
        let rows = sqlite(database: database, query: """
        SELECT updated_at, replace(replace(title, char(10), ' '), '|', ' '),
               coalesce(model,''), coalesce(reasoning_effort,'')
        FROM threads ORDER BY updated_at DESC LIMIT 1;
        """).split(separator: "|", omittingEmptySubsequences: false)

        guard rows.count >= 4, let updated = TimeInterval(rows[0]) else {
            return LocalCodexStatus(workState: .idle, taskTitle: "최근 작업 없음", model: nil, effort: nil)
        }

        let age = Date().timeIntervalSince1970 - updated
        let state: WorkState = age < 20 ? .working : age < 180 ? .recentlyCompleted : .idle
        return LocalCodexStatus(
            workState: state,
            taskTitle: String(rows[1]).isEmpty ? "제목 없는 작업" : String(rows[1]),
            model: rows[2].isEmpty ? nil : String(rows[2]),
            effort: rows[3].isEmpty ? nil : String(rows[3])
        )
    }

    private func sqlite(database: String, query: String) -> String {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = ["-readonly", "-noheader", database, query]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }
}
