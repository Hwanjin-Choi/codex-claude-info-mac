import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PetView: View {
    let state: PetState
    let size: Double
    let speed: Double
    let animated: Bool
    @AppStorage("customPetPath") private var customPetPath = ""
    @AppStorage("customPetRevision") private var customPetRevision = 0

    var body: some View {
        Group {
            if !customPetPath.isEmpty,
               FileManager.default.fileExists(atPath: customPetPath) {
                AnimatedPetImage(
                    url: URL(fileURLWithPath: customPetPath),
                    animated: animated
                )
                .id("\(customPetPath)-\(customPetRevision)-\(animated)")
            } else {
                TimelineView(.animation(minimumInterval: frameDuration, paused: !animated)) { timeline in
                    let frame = animated
                        ? Int(timeline.date.timeIntervalSinceReferenceDate / frameDuration) % state.frameCount
                        : 0
                    if let image = PetSprites.frame(row: state.row, column: frame) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } else {
                        Image(systemName: "pawprint.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                            .padding(24)
                    }
                }
            }
        }
        .frame(width: size, height: size * 1.08)
        .clipped()
        .accessibilityLabel(customPetPath.isEmpty ? "짱구 코디" : "사용자 펫")
    }

    private var frameDuration: Double { 0.22 - (min(max(speed, 0.5), 2) - 0.5) * 0.08 }
}

struct PetPickerControls: View {
    @AppStorage("customPetPath") private var customPetPath = ""
    @AppStorage("customPetName") private var customPetName = "짱구 코디"
    @AppStorage("customPetRevision") private var customPetRevision = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button("펫 이미지 선택") {
                    switch CustomPetStore.choose() {
                    case .success(let pet):
                        customPetPath = pet.path
                        customPetName = pet.name
                        customPetRevision += 1
                        errorMessage = nil
                    case .failure(let error):
                        if error != .cancelled { errorMessage = error.localizedDescription }
                    }
                }
                if !customPetPath.isEmpty {
                    Button("기본 펫 복원") {
                        CustomPetStore.reset(path: customPetPath)
                        customPetPath = ""
                        customPetName = "짱구 코디"
                        customPetRevision += 1
                        errorMessage = nil
                    }
                }
                Spacer()
            }
            Text(customPetPath.isEmpty ? "PNG, JPG, WebP, GIF · 최대 15MB" : customPetName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let errorMessage {
                Text(errorMessage).font(.caption2).foregroundStyle(.red)
            }
        }
    }
}

private struct AnimatedPetImage: NSViewRepresentable {
    let url: URL
    let animated: Bool

    final class Coordinator {
        var loadedURL: URL?
        var animated: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSImageView {
        let view = PetImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageAlignment = .alignCenter
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        view.animates = animated
        view.image = NSImage(contentsOf: url)
        context.coordinator.loadedURL = url
        context.coordinator.animated = animated
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        if context.coordinator.loadedURL != url {
            view.image = NSImage(contentsOf: url)
            context.coordinator.loadedURL = url
        }
        if context.coordinator.animated != animated {
            view.animates = animated
            context.coordinator.animated = animated
        }
    }
}

private final class PetImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
}

@MainActor
private enum CustomPetStore {
    struct Pet {
        let path: String
        let name: String
    }

    enum StoreError: LocalizedError, Equatable {
        case cancelled
        case unsupported
        case tooLarge
        case copyFailed

        var errorDescription: String? {
            switch self {
            case .cancelled: nil
            case .unsupported: "PNG, JPG, WebP 또는 GIF 이미지를 선택해 주세요."
            case .tooLarge: "펫 이미지는 15MB 이하여야 합니다."
            case .copyFailed: "펫 이미지를 앱 저장소에 복사하지 못했습니다."
            }
        }
    }

    static func choose() -> Result<Pet, StoreError> {
        let panel = NSOpenPanel()
        panel.title = "펫 이미지 선택"
        panel.prompt = "펫으로 사용"
        panel.allowedContentTypes = [.png, .jpeg, .webP, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let source = panel.url else {
            return .failure(.cancelled)
        }

        let supported = ["png", "jpg", "jpeg", "webp", "gif"]
        let fileExtension = source.pathExtension.lowercased()
        guard supported.contains(fileExtension) else { return .failure(.unsupported) }
        let size = (try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= 15 * 1024 * 1024 else { return .failure(.tooLarge) }

        let fileManager = FileManager.default
        let directory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Codex & Claude Info", isDirectory: true)
        let destination = directory.appendingPathComponent("custom-pet-\(UUID().uuidString).\(fileExtension)")
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: source, to: destination)
            let oldPath = UserDefaults.standard.string(forKey: "customPetPath") ?? ""
            reset(path: oldPath)
            return .success(Pet(
                path: destination.path,
                name: source.deletingPathExtension().lastPathComponent
            ))
        } catch {
            try? fileManager.removeItem(at: destination)
            return .failure(.copyFailed)
        }
    }

    static func reset(path: String) {
        guard !path.isEmpty else { return }
        let fileManager = FileManager.default
        let directory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Codex & Claude Info", isDirectory: true)
            .standardizedFileURL.path
        let target = URL(fileURLWithPath: path).standardizedFileURL.path
        guard target.hasPrefix(directory + "/custom-pet-") else { return }
        try? fileManager.removeItem(atPath: target)
    }
}

enum PetState {
    case idle, working, waiting, failed

    var row: Int {
        switch self {
        case .idle: 0
        case .working: 7
        case .waiting: 6
        case .failed: 5
        }
    }

    var frameCount: Int {
        switch self {
        case .idle, .working, .waiting: 6
        case .failed: 8
        }
    }
}

private enum PetSprites {
    private static let sheet: CGImage? = {
        guard let url = Bundle.main.url(forResource: "jjanggu-codi", withExtension: "webp"),
              let image = NSImage(contentsOf: url) else { return nil }
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }()

    static func frame(row: Int, column: Int) -> NSImage? {
        guard let sheet else { return nil }
        let cellWidth = sheet.width / 8
        let cellHeight = sheet.height / 9
        let rect = CGRect(
            x: column * cellWidth,
            y: sheet.height - ((row + 1) * cellHeight),
            width: cellWidth,
            height: cellHeight
        )
        guard let cropped = sheet.cropping(to: rect) else { return nil }
        return NSImage(cgImage: cropped, size: NSSize(width: cellWidth, height: cellHeight))
    }
}
