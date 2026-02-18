import AppKit

/// 워크스페이스 전환 로직을 담당하는 서비스
final class WorkspaceSwitchService {
    static let shared = WorkspaceSwitchService()

    private let accessibility = AccessibilityService.shared

    /// 숨기지 않을 시스템 앱 Bundle ID 목록
    private let systemExcludeList: Set<String> = [
        "com.apple.finder",
        "com.apple.systempreferences",
        "com.apple.SystemPreferences",
    ]

    private init() {}

    /// 모든 앱을 unhide하여 보이게 만들기
    func showAllApps() {
        let myPID = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            guard app.processIdentifier != myPID else { continue }

            app.unhide()
        }

        // 최소화된 창도 복원
        if accessibility.isAccessibilityGranted {
            let windows = accessibility.enumerateAllWindows()
            for window in windows where window.isMinimized {
                accessibility.raiseWindow(window)
            }
        }

        // 활성 워크스페이스 해제
        WorkspaceStore.shared.deactivateAll()

        print("[ContextSwitcher] Show all apps")
    }

    /// 지정된 워크스페이스로 전환
    func switchTo(workspace: WorkspaceConfiguration) {
        let identifiers = workspace.windowIdentifiers
        let matchedBundleIDs: Set<String> = Set(identifiers.map(\.bundleIdentifier))

        // titlePattern이 있는 식별자 (개별 창 매칭용)
        let specificIdentifiers = identifiers.filter { !$0.titlePattern.isEmpty }

        print("[ContextSwitcher] Switching to '\(workspace.name)'")
        print("[ContextSwitcher]   matched bundle IDs: \(matchedBundleIDs)")
        if !specificIdentifiers.isEmpty {
            print("[ContextSwitcher]   specific windows: \(specificIdentifiers.map { "\($0.bundleIdentifier):\($0.titlePattern)" })")
        }

        let myPID = ProcessInfo.processInfo.processIdentifier
        var hiddenCount = 0
        var shownCount = 0

        // 1단계: NSRunningApplication 기반 hide/unhide (권한 불필요)
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            guard app.processIdentifier != myPID else { continue }

            let bundleID = app.bundleIdentifier ?? ""
            if systemExcludeList.contains(bundleID) { continue }

            if matchedBundleIDs.contains(bundleID) {
                app.unhide()
                app.activate()
                shownCount += 1
                print("[ContextSwitcher]   SHOW: \(app.localizedName ?? "?") (\(bundleID))")
            } else {
                app.hide()
                hiddenCount += 1
                print("[ContextSwitcher]   HIDE: \(app.localizedName ?? "?") (\(bundleID))")
            }
        }

        print("[ContextSwitcher]   Result: showed \(shownCount), hid \(hiddenCount)")

        // 2단계: AXUIElement 기반 창 raise (Accessibility 권한 필요, 선택적)
        if accessibility.isAccessibilityGranted {
            let windows = accessibility.enumerateAllWindows()
            for window in windows {
                guard matchedBundleIDs.contains(window.bundleIdentifier) else { continue }

                // 이 앱에 특정 창 패턴이 있는지 확인
                let appSpecific = specificIdentifiers.filter { $0.bundleIdentifier == window.bundleIdentifier }

                if appSpecific.isEmpty {
                    // titlePattern 없음 → 앱의 모든 창 raise (기존 동작)
                    accessibility.raiseWindow(window)
                } else {
                    // titlePattern 있음 → 매칭되는 창만 raise, 나머지는 minimize
                    let matched = appSpecific.contains { $0.matches(bundleID: window.bundleIdentifier, windowTitle: window.windowTitle) }
                    if matched {
                        accessibility.raiseWindow(window)
                        print("[ContextSwitcher]   RAISE specific: \(window.windowTitle)")
                    } else {
                        accessibility.minimizeWindow(window)
                        print("[ContextSwitcher]   MINIMIZE: \(window.windowTitle)")
                    }
                }
            }
        }
    }
}
