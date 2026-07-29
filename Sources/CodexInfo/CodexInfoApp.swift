import SwiftUI

@main
struct CodexInfoApp: App {
    @StateObject private var monitor: CodexMonitor

    init() {
        let monitor = CodexMonitor()
        _monitor = StateObject(wrappedValue: monitor)
        Task { await monitor.start() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(monitor)
        } label: {
            HStack(spacing: 4) {
                LucideGauge()
                    .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                    .frame(width: 17, height: 17)
                Text(monitor.menuTitle)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

private struct LucideGauge: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let origin = CGPoint(
            x: rect.midX - 12 * scale,
            y: rect.midY - 12 * scale
        )
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }

        var path = Path()
        path.move(to: point(12, 14))
        path.addLine(to: point(16, 10))
        path.move(to: point(3.34, 19))
        path.addCurve(
            to: point(5.5, 5.7),
            control1: point(0.8, 14.6),
            control2: point(1.6, 9.1)
        )
        path.addCurve(
            to: point(18.5, 5.7),
            control1: point(9.4, 2.3),
            control2: point(14.6, 2.3)
        )
        path.addCurve(
            to: point(20.66, 19),
            control1: point(22.4, 9.1),
            control2: point(23.2, 14.6)
        )
        return path
    }
}
