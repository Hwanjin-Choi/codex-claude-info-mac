import Foundation

@main
enum CheckAppServer {
    static func main() async throws {
        let files = FileManager.default
        let applications = files.temporaryDirectory.appendingPathComponent("codex-discovery-\(UUID().uuidString)")
        defer { try? files.removeItem(at: applications) }
        for app in ["Codex.app", "ChatGPT.app"] {
            for layout in ["Contents/Resources/codex", "Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"] {
                let executable = applications.appendingPathComponent("\(app)/\(layout)")
                try files.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
                try files.copyItem(atPath: CommandLine.arguments[1], toPath: executable.path)
                let found = try CodexAppServer.findCodex(applicationsDirectory: applications.path)
                precondition(found == executable.path, "Must discover and prefer the current desktop bundle layout")
            }
        }
        print("Current and legacy ChatGPT/Codex executable discovery: passed")

        let server = CodexAppServer(executable: CommandLine.arguments[1], responseTimeout: .seconds(1))
        async let first = server.request("first")
        async let second = server.request("second")
        let results = try await [first, second]
        precondition(results.allSatisfy { $0.value["ok"] as? Bool == true })
        do {
            _ = try await server.request("unsupported")
            fatalError("An unsupported method must fail")
        } catch AppServerError.rpc {} catch { throw error }
        do {
            _ = try await server.request("hang")
            fatalError("An unanswered request must time out")
        } catch AppServerError.timedOut {} catch { throw error }
        let recovered = try await server.request("reconnect")
        precondition(recovered.value["ok"] as? Bool == true)
        await server.stop()
        print("Concurrent startup, optional RPC failure, timeout and reconnect: passed")
    }
}
