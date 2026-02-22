import SwiftUI

@main
struct ContextSwitcherApp: App {
    init() {
        let granted = AccessibilityService.shared.isAccessibilityGranted
        print("[ContextSwitcher] Starting... Accessibility permission: \(granted)")

        if !granted {
            print("[ContextSwitcher] Requesting accessibility permission...")
            AccessibilityService.shared.requestAccessibilityPermission()
        }

        // 글로벌 키보드 단축키 서비스 시작 (Accessibility 권한 필요)
        if granted {
            ShortcutService.shared.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            Image(systemName: "square.grid.2x2")
        }
        .menuBarExtraStyle(.window)
    }
}
