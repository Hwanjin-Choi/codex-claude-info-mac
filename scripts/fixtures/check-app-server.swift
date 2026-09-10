import Foundation

@main
enum CheckAppServer {
    static func main() async throws {
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
