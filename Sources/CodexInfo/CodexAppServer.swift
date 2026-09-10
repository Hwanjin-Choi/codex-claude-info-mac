import Foundation

struct JSONDictionary: @unchecked Sendable {
    let value: [String: Any]
    init(_ value: [String: Any] = [:]) { self.value = value }
}

enum AppServerError: LocalizedError {
    case codexNotFound
    case launchFailed(String)
    case disconnected
    case invalidResponse
    case timedOut
    case rpc(String)

    var errorDescription: String? {
        switch self {
        case .codexNotFound: "Codex CLI를 찾을 수 없습니다."
        case .launchFailed(let detail): "Codex 실행 실패: \(detail)"
        case .disconnected: "Codex 연결이 종료되었습니다."
        case .invalidResponse: "Codex 응답 형식이 올바르지 않습니다."
        case .timedOut: "Codex 응답 시간이 초과되었습니다. 다음 갱신에서 다시 연결합니다."
        case .rpc(let detail): detail
        }
    }
}

actor CodexAppServer {
    private var process: Process?
    private var input: FileHandle?
    private var responses: [Int: CheckedContinuation<[String: Any], Error>] = [:]
    private var nextID = 1
    private var startup: Task<Void, Error>?
    private var timeouts: [Int: Task<Void, Never>] = [:]
    private let executableOverride: String?
    private let responseTimeout: Duration

    init(executable: String? = nil, responseTimeout: Duration = .seconds(15)) {
        executableOverride = executable
        self.responseTimeout = responseTimeout
    }

    func stop() {
        if let processID = process?.processIdentifier { disconnect(processID: processID) }
    }

    func start() async throws {
        if let startup { return try await startup.value }
        if process?.isRunning == true { return }
        let task = Task { try await launch() }
        startup = task
        defer { startup = nil }
        try await task.value
    }

    private func launch() async throws {
        let executable = try executableOverride ?? findCodex()
        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["app-server"]
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { throw AppServerError.launchFailed(error.localizedDescription) }
        self.process = process
        self.input = stdinPipe.fileHandleForWriting
        let processID = process.processIdentifier

        let output = stdoutPipe.fileHandleForReading
        Task.detached { [weak self] in
            var buffer = Data()
            do {
                for try await byte in output.bytes {
                    if byte == 10 {
                        if !buffer.isEmpty { await self?.receive(buffer) }
                        buffer.removeAll(keepingCapacity: true)
                    } else {
                        buffer.append(byte)
                        if buffer.count > 8 * 1024 * 1024 {
                            await self?.disconnect(processID: processID)
                            return
                        }
                    }
                }
            } catch {}
            await self?.disconnect(processID: processID)
        }

        do {
            _ = try await connectedRequest("initialize", params: JSONDictionary([
                "clientInfo": ["name": "codex-claude-info", "title": "Codex & Claude Info", "version": "1.0.0"],
                "capabilities": ["experimentalApi": true]
            ]))
            try sendNotification("initialized", params: [:])
        } catch {
            disconnect(processID: processID)
            throw error
        }
    }

    func request(_ method: String, params: JSONDictionary = JSONDictionary()) async throws -> JSONDictionary {
        try await start()
        return try await connectedRequest(method, params: params)
    }

    private func connectedRequest(_ method: String, params: JSONDictionary) async throws -> JSONDictionary {
        guard let processID = process?.processIdentifier else { throw AppServerError.disconnected }
        let id = nextID
        nextID += 1
        let message: [String: Any] = ["id": id, "method": method, "params": params.value]
        let result: [String: Any] = try await withCheckedThrowingContinuation { continuation in
            responses[id] = continuation
            do {
                try write(message)
                let timeout = responseTimeout
                timeouts[id] = Task { [weak self] in
                    do { try await Task.sleep(for: timeout) } catch { return }
                    await self?.disconnect(processID: processID, error: .timedOut)
                }
            } catch {
                responses.removeValue(forKey: id)?.resume(throwing: error)
            }
        }
        return JSONDictionary(result)
    }

    private func sendNotification(_ method: String, params: [String: Any]) throws {
        try write(["method": method, "params": params])
    }

    private func write(_ object: [String: Any]) throws {
        guard let input else { throw AppServerError.disconnected }
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(10)
        try input.write(contentsOf: data)
    }

    private func receive(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = object["id"] as? Int,
              let continuation = responses.removeValue(forKey: id) else { return }
        timeouts.removeValue(forKey: id)?.cancel()
        if let error = object["error"] as? [String: Any] {
            continuation.resume(throwing: AppServerError.rpc(error["message"] as? String ?? "Codex 요청 실패"))
        } else if let result = object["result"] as? [String: Any] {
            continuation.resume(returning: result)
        } else {
            continuation.resume(throwing: AppServerError.invalidResponse)
        }
    }

    private func disconnect(processID: Int32, error: AppServerError = .disconnected) {
        guard process?.processIdentifier == processID else { return }
        for task in timeouts.values { task.cancel() }
        timeouts.removeAll()
        for continuation in responses.values {
            continuation.resume(throwing: error)
        }
        responses.removeAll()
        try? input?.close()
        if process?.isRunning == true { process?.terminate() }
        process = nil
        input = nil
    }

    private func findCodex() throws -> String {
        let candidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex", "/usr/local/bin/codex",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.local/bin/codex"
        ]
        if let found = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) { return found }
        let envPaths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":")
        if let found = envPaths.map({ "\($0)/codex" }).first(where: { FileManager.default.isExecutableFile(atPath: $0) }) { return found }
        throw AppServerError.codexNotFound
    }
}
