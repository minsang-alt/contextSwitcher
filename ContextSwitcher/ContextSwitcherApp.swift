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
