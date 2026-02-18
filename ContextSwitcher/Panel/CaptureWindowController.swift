import AppKit
import SwiftUI

/// CaptureView를 독립 윈도우로 띄우는 컨트롤러
final class CaptureWindowController {
    static let shared = CaptureWindowController()

    private var window: NSWindow?

    private init() {}

    /// 신규 워크스페이스 캡처 윈도우 표시
    func show() {
        showWindow(editing: nil)
    }

    /// 기존 워크스페이스 편집 윈도우 표시
    func showEdit(_ workspace: WorkspaceConfiguration) {
        showWindow(editing: workspace)
    }

    private func showWindow(editing workspace: WorkspaceConfiguration?) {
        // 이미 열려있으면 닫고 새로 열기
        window?.close()
        window = nil

        let captureView = CaptureView(
            onDismiss: { [weak self] in
                self?.window?.close()
                self?.window = nil
                // 윈도우가 닫힐 때 accessory로 복원
                NSApp.setActivationPolicy(.accessory)
            },
            editingWorkspace: workspace
        )

        let hostingView = NSHostingView(rootView: captureView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = hostingView
        newWindow.title = workspace != nil ? "Edit Workspace" : "Capture Current Layout"
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating

        // 메뉴바 앱에서 TextField가 키보드 입력을 받으려면
        // 앱을 regular로 전환 후 활성화해야 함
        // 윈도우가 열려있는 동안 .regular 유지 (accessory 전환 시 포커스 이동으로 @State 리셋됨)
        NSApp.setActivationPolicy(.regular)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }
}
