import SwiftUI
import AppKit

/// 키보드 단축키를 녹화하는 SwiftUI 뷰
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyShortcut?
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            if isRecording {
                Text("Press shortcut...")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )

                Button("Cancel") {
                    stopRecording()
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else if let shortcut = shortcut {
                Text(shortcut.displayString)
                    .font(.system(size: 12, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)

                Button {
                    self.shortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button("Change") {
                    startRecording()
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            } else {
                Button("Set Shortcut") {
                    startRecording()
                }
                .font(.system(size: 11))
            }
        }
    }

    private func startRecording() {
        isRecording = true
        // 로컬 이벤트 모니터로 키 입력 캡처 (창이 포커스 상태이므로 local 사용)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = !flags.intersection([.control, .option, .shift, .command]).isEmpty

            // modifier가 없으면 무시 (ESC는 녹화 취소)
            if event.keyCode == 0x35 { // ESC
                stopRecording()
                return nil
            }

            guard hasModifier else { return event }

            let recorded = KeyShortcut(keyCode: event.keyCode, nsFlags: flags)
            shortcut = recorded
            stopRecording()
            return nil  // 이벤트 소비
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
