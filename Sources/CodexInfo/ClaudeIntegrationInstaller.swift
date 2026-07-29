import Foundation

enum ClaudeIntegrationError: LocalizedError {
    case bridgeMissing
    case installationFailed(String)

    var errorDescription: String? {
        switch self {
        case .bridgeMissing: "앱 번들에서 Claude 연동 도구를 찾지 못했습니다."
        case .installationFailed(let detail): "Claude 연동 실패: \(detail)"
        }
    }
}

enum ClaudeIntegrationInstaller {
    static func install() throws {
        let fallback = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/ClaudeInfoBridge")
        guard let bridge = Bundle.main.url(forAuxiliaryExecutable: "ClaudeInfoBridge")
                ?? (FileManager.default.isExecutableFile(atPath: fallback.path) ? fallback : nil) else {
            throw ClaudeIntegrationError.bridgeMissing
        }
        let process = Process()
        let errorPipe = Pipe()
        process.executableURL = bridge
        process.arguments = ["--install"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let detail = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "알 수 없는 오류"
            throw ClaudeIntegrationError.installationFailed(detail)
        }
    }
}
