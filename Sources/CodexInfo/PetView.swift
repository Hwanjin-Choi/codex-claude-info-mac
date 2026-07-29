import SwiftUI

struct PetView: View {
    let state: PetState
    let size: Double
    let speed: Double
    let animated: Bool

    var body: some View {
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
        .frame(width: size, height: size * 1.08)
        .accessibilityLabel("짱구 코디")
    }

    private var frameDuration: Double { 0.22 - (min(max(speed, 0.5), 2) - 0.5) * 0.08 }
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
