import Carbon.HIToolbox
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var statusWindow: StatusWindowController?
  private let audioRecorder = AudioRecorder()
  private let transcriptionService = TranscriptionService()
  private var hotKeyRef: EventHotKeyRef?

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Hide from Dock
    NSApp.setActivationPolicy(.accessory)

    // Setup menu bar
    setupMenuBar()

    // Setup global shortcut
    setupGlobalShortcut()

    // Setup status window
    statusWindow = StatusWindowController()
  }

  private func setupMenuBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
      // Use a microphone symbol
      button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "VoiceOS")
      button.action = #selector(toggleRecording)
      button.target = self
    }
  }

  private func setupGlobalShortcut() {
    // Register Cmd+Shift+R
    var hotKeyID = EventHotKeyID()
    hotKeyID.signature = OSType(0x766F_7378)  // 'vosx' in hex
    hotKeyID.id = 1

    var eventType = EventTypeSpec()
    eventType.eventClass = OSType(kEventClassKeyboard)
    eventType.eventKind = OSType(kEventHotKeyPressed)

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
                appDelegate.toggleRecording()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

    RegisterEventHotKey(
      UInt32(kVK_ANSI_R),
      UInt32(cmdKey | shiftKey),
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )
  }

  @objc private func toggleRecording() {
    if audioRecorder.isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }

  private func startRecording() {
    statusWindow?.show(message: "Recording...", state: .recording)

    audioRecorder.startRecording { [weak self] result in
      // Recording started successfully or failed
      switch result {
      case .success:
        print("Recording started")
      case .failure(let error):
        DispatchQueue.main.async {
          self?.statusWindow?.show(message: "Error: \(error.localizedDescription)", state: .error)
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self?.statusWindow?.hide()
          }
        }
      }
    }
  }

  private func stopRecording() {
    audioRecorder.stopRecording { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success(let audioURL):
        DispatchQueue.main.async {
          self.statusWindow?.show(message: "Transcribing...", state: .transcribing)
          self.transcribe(audioURL: audioURL)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self.statusWindow?.show(message: "Error: \(error.localizedDescription)", state: .error)
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusWindow?.hide()
          }
        }
      }
    }
  }

  private func transcribe(audioURL: URL) {
    transcriptionService.transcribe(audioURL: audioURL) { [weak self] result in
      guard let self = self else { return }

      DispatchQueue.main.async {
        switch result {
        case .success(let text):
          // Copy to clipboard
          let pasteboard = NSPasteboard.general
          pasteboard.clearContents()
          pasteboard.setString(text, forType: .string)

          self.statusWindow?.show(message: "Copied!", state: .success)

          // Hide after 1.5 seconds
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.statusWindow?.hide()
          }

        case .failure(let error):
          self.statusWindow?.show(message: "Error: \(error.localizedDescription)", state: .error)
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusWindow?.hide()
          }
        }

        // Clean up audio file
        try? FileManager.default.removeItem(at: audioURL)
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    // Cleanup
    if let hotKeyRef = hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
  }
}
