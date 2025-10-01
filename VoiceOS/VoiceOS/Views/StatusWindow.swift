import AppKit
import SwiftUI

enum StatusState {
  case recording
  case transcribing
  case success
  case error

  var color: Color {
    switch self {
    case .recording:
      return .red
    case .transcribing:
      return .blue
    case .success:
      return .green
    case .error:
      return .orange
    }
  }

  var icon: String {
    switch self {
    case .recording:
      return "mic.fill"
    case .transcribing:
      return "waveform.circle.fill"
    case .success:
      return "checkmark.circle.fill"
    case .error:
      return "exclamationmark.triangle.fill"
    }
  }
}

struct StatusView: View {
  let message: String
  let state: StatusState
  @State private var scale: CGFloat = 0.8
  @State private var opacity: Double = 0.0

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: state.icon)
        .font(.system(size: 20))
        .foregroundColor(state.color)

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.primary)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    )
    .scaleEffect(scale)
    .opacity(opacity)
    .onAppear {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        scale = 1.0
        opacity = 1.0
      }
    }
  }
}

class StatusWindowController: NSObject {
  private var window: NSWindow?
  private var hostingView: NSHostingView<StatusView>?

  func show(message: String, state: StatusState) {
    // Create or update window
    if window == nil {
      let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 300, height: 60),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
      )

      panel.isFloatingPanel = true
      panel.level = .floating
      panel.backgroundColor = .clear
      panel.isOpaque = false
      panel.hasShadow = false
      panel.collectionBehavior = [.canJoinAllSpaces, .stationary]

      window = panel
    }

    // Update content
    let statusView = StatusView(message: message, state: state)
    hostingView = NSHostingView(rootView: statusView)
    window?.contentView = hostingView

        // Position at center of screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window!.frame
            let xPosition = screenRect.midX - windowRect.width / 2
            let yPosition = screenRect.midY + screenRect.height / 3
            window?.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        }

    window?.orderFrontRegardless()
  }

  func hide() {
    // Fade out animation
    NSAnimationContext.runAnimationGroup(
      { context in
        context.duration = 0.3
        window?.animator().alphaValue = 0
      },
      completionHandler: {
        self.window?.orderOut(nil)
        self.window?.alphaValue = 1
      })
  }
}
