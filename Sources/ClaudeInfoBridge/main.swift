import Foundation
import Darwin

struct ClaudeLimit: Codable {
    var usedPercentage: Double
    var resetsAt: Date
}

struct ClaudeBridgeState: Codable {
    var updatedAt = Date()
    var sessionID: String?
    var sessionName: String?
    var modelID: String?
    var modelName: String?
    var effort: String?
    var thinkingEnabled: Bool?
    var contextPercentage: Double?
    var fiveHour: ClaudeLimit?
    var sevenDay: ClaudeLimit?
    var totalCostUSD: Double?
    var durationMS: Int?
    var workState = "idle"
    var lastError: String?
}

@main
enum ClaudeInfoBridge {
    static func main() {
        if CommandLine.arguments.contains("--install") {
            do {
                try installIntegration()
                print("installed")
            } catch {
                FileHandle.standardError.write(Data(error.localizedDescription.utf8))
                exit(1)
            }
            return
        }

        let input = FileHandle.standardInput.readDataToEndOfFile()
        guard let object = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else { return }

        var state = loadState()
        state.updatedAt = Date()

        if CommandLine.arguments.contains("--capture-status") {
            updateStatus(&state, from: object)
            save(state)
            passthroughOrPrint(input: input, state: state)
        } else if CommandLine.arguments.contains("--capture-hook") {
            updateHook(&state, from: object)
            save(state)
        }
    }

    private static func updateStatus(_ state: inout ClaudeBridgeState, from json: [String: Any]) {
        state.sessionID = json["session_id"] as? String ?? state.sessionID
        state.sessionName = json["session_name"] as? String ?? state.sessionName
        if let model = json["model"] as? [String: Any] {
            state.modelID = model["id"] as? String ?? state.modelID
            state.modelName = model["display_name"] as? String ?? state.modelName
        }
        if let effort = json["effort"] as? [String: Any] {
            state.effort = effort["level"] as? String ?? state.effort
        }
        if let thinking = json["thinking"] as? [String: Any] {
            state.thinkingEnabled = thinking["enabled"] as? Bool ?? state.thinkingEnabled
        }
        if let context = json["context_window"] as? [String: Any] {
            state.contextPercentage = (context["used_percentage"] as? NSNumber)?.doubleValue ?? state.contextPercentage
        }
        if let cost = json["cost"] as? [String: Any] {
            state.totalCostUSD = (cost["total_cost_usd"] as? NSNumber)?.doubleValue ?? state.totalCostUSD
            state.durationMS = (cost["total_duration_ms"] as? NSNumber)?.intValue ?? state.durationMS
        }
        if let limits = json["rate_limits"] as? [String: Any] {
            state.fiveHour = parseLimit(limits["five_hour"]) ?? state.fiveHour
            state.sevenDay = parseLimit(limits["seven_day"]) ?? state.sevenDay
        }
    }

    private static func updateHook(_ state: inout ClaudeBridgeState, from json: [String: Any]) {
        state.sessionID = json["session_id"] as? String ?? state.sessionID
        if let model = json["model"] as? String {
            state.modelID = model
            state.modelName = model
        }
        let event = json["hook_event_name"] as? String ?? ""
        switch event {
        case "UserPromptSubmit", "PreToolUse", "PostToolUse":
            state.workState = "working"
            state.lastError = nil
        case "PermissionRequest", "Notification":
            state.workState = "waiting"
        case "Stop":
            state.workState = "completed"
            state.lastError = nil
        case "StopFailure":
            state.workState = "failed"
            state.lastError = json["error"] as? String ?? "Claude 작업이 오류로 종료되었습니다."
        case "SessionStart":
            state.workState = "idle"
            state.lastError = nil
        case "SessionEnd":
            if state.lastError == nil { state.workState = "idle" }
        default:
            break
        }
    }

    private static func parseLimit(_ value: Any?) -> ClaudeLimit? {
        guard let object = value as? [String: Any],
              let percentage = (object["used_percentage"] as? NSNumber)?.doubleValue,
              let timestamp = (object["resets_at"] as? NSNumber)?.doubleValue else { return nil }
        return ClaudeLimit(usedPercentage: percentage, resetsAt: Date(timeIntervalSince1970: timestamp))
    }

    private static var supportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Claude Info", isDirectory: true)
    }

    private static var stateURL: URL { supportDirectory.appendingPathComponent("state.json") }

    private static func loadState() -> ClaudeBridgeState {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(ClaudeBridgeState.self, from: data) else {
            return ClaudeBridgeState()
        }
        return state
    }

    private static func save(_ state: ClaudeBridgeState) {
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }

    private static func passthroughOrPrint(input: Data, state: ClaudeBridgeState) {
        let commandURL = supportDirectory.appendingPathComponent("original-statusline-command.txt")
        if let command = try? String(contentsOf: commandURL, encoding: .utf8),
           !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let process = Process()
            let stdin = Pipe()
            let stdout = Pipe()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", command]
            process.standardInput = stdin
            process.standardOutput = stdout
            process.standardError = FileHandle.standardError
            do {
                try process.run()
                try? stdin.fileHandleForWriting.write(contentsOf: input)
                try? stdin.fileHandleForWriting.close()
                process.waitUntilExit()
                FileHandle.standardOutput.write(stdout.fileHandleForReading.readDataToEndOfFile())
                return
            } catch {}
        }

        var parts = ["Claude Info", state.modelName ?? "Claude"]
        if let five = state.fiveHour { parts.append("5h \(Int(five.usedPercentage.rounded()))%") }
        if let week = state.sevenDay { parts.append("7d \(Int(week.usedPercentage.rounded()))%") }
        print(parts.joined(separator: " · "))
    }

    private static func installIntegration() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)

        let currentExecutable = URL(fileURLWithPath: CommandLine.arguments[0])
        let installedBridge = supportDirectory.appendingPathComponent("ClaudeInfoBridge")
        if currentExecutable.standardizedFileURL != installedBridge.standardizedFileURL {
            if fileManager.fileExists(atPath: installedBridge.path) {
                try fileManager.removeItem(at: installedBridge)
            }
            try fileManager.copyItem(at: currentExecutable, to: installedBridge)
        }
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installedBridge.path)

        let claudeDirectory = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude", isDirectory: true)
        try fileManager.createDirectory(at: claudeDirectory, withIntermediateDirectories: true)
        let settingsURL = claudeDirectory.appendingPathComponent("settings.json")
        var settings: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL) {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "ClaudeInfo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Claude settings.json 형식이 올바르지 않습니다."])
            }
            settings = parsed
            let backups = claudeDirectory.appendingPathComponent("backups", isDirectory: true)
            try fileManager.createDirectory(at: backups, withIntermediateDirectories: true)
            try data.write(
                to: backups.appendingPathComponent("settings-before-claude-info-\(Int(Date().timeIntervalSince1970)).json"),
                options: .atomic
            )
        }

        if let original = settings["statusLine"] as? [String: Any],
           let command = original["command"] as? String,
           !command.contains("ClaudeInfoBridge") {
            try command.write(
                to: supportDirectory.appendingPathComponent("original-statusline-command.txt"),
                atomically: true,
                encoding: .utf8
            )
        }

        let quotedBridge = "'\(installedBridge.path.replacingOccurrences(of: "'", with: "'\\''"))'"
        settings["statusLine"] = [
            "type": "command",
            "command": "\(quotedBridge) --capture-status",
            "refreshInterval": 2
        ]

        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        for event in ["SessionStart", "UserPromptSubmit", "PermissionRequest", "Notification", "Stop", "StopFailure", "SessionEnd"] {
            var groups = hooks[event] as? [[String: Any]] ?? []
            let exists = groups.contains {
                guard let commands = $0["hooks"] as? [[String: Any]] else { return false }
                return commands.contains { ($0["command"] as? String)?.contains("ClaudeInfoBridge") == true }
            }
            if !exists {
                groups.append(["hooks": [[
                    "type": "command",
                    "command": "\(quotedBridge) --capture-hook"
                ]]])
            }
            hooks[event] = groups
        }
        settings["hooks"] = hooks

        let output = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try output.write(to: settingsURL, options: .atomic)
    }
}
