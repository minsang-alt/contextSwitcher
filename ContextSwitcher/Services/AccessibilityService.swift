import AppKit
import ApplicationServices

/// Accessibility API를 통해 발견된 창 정보
struct DiscoveredWindow: Identifiable {
    let id = UUID()
    let appName: String
    let bundleIdentifier: String
    let pid: pid_t
    let windowTitle: String
    let windowElement: AXUIElement
    let appElement: AXUIElement
    let isMinimized: Bool
}

/// macOS Accessibility API 래퍼
final class AccessibilityService {
    static let shared = AccessibilityService()

    private init() {}

    // MARK: - 권한 관리

    /// Accessibility 권한이 부여되었는지 확인
    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Accessibility 권한을 요청 (시스템 다이얼로그 표시)
    func requestAccessibilityPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// 권한이 부여될 때까지 폴링
    func waitForPermission(completion: @escaping () -> Void) {
        if isAccessibilityGranted {
            completion()
            return
        }

        requestAccessibilityPermission()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                DispatchQueue.main.async { completion() }
            }
        }
    }

    // MARK: - 창 열거

    /// 현재 실행 중인 모든 일반 앱의 창을 열거
    /// Accessibility 권한이 없으면 NSRunningApplication 기반으로 앱 목록만 반환
    func enumerateAllWindows() -> [DiscoveredWindow] {
        var results: [DiscoveredWindow] = []
        let myPID = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            guard app.processIdentifier != myPID else { continue }

            let pid = app.processIdentifier
            let appName = app.localizedName ?? "Unknown"
            let bundleID = app.bundleIdentifier ?? ""

            if isAccessibilityGranted {
                // AX 권한 있으면 개별 창 열거
                let appElement = AXUIElementCreateApplication(pid)
                let windows = axWindows(of: appElement)

                if windows.isEmpty {
                    // 창이 없는 앱도 목록에 포함 (앱 단위 관리용)
                    results.append(DiscoveredWindow(
                        appName: appName,
                        bundleIdentifier: bundleID,
                        pid: pid,
                        windowTitle: "",
                        windowElement: appElement,
                        appElement: appElement,
                        isMinimized: false
                    ))
                } else {
                    for window in windows {
                        let title: String = axValue(window, kAXTitleAttribute) ?? ""
                        let isMinimized: Bool = axValue(window, kAXMinimizedAttribute) ?? false

                        results.append(DiscoveredWindow(
                            appName: appName,
                            bundleIdentifier: bundleID,
                            pid: pid,
                            windowTitle: title,
                            windowElement: window,
                            appElement: appElement,
                            isMinimized: isMinimized
                        ))
                    }
                }
            } else {
                // AX 권한 없으면 앱 단위로만 추가
                let appElement = AXUIElementCreateSystemWide()
                results.append(DiscoveredWindow(
                    appName: appName,
                    bundleIdentifier: bundleID,
                    pid: pid,
                    windowTitle: "",
                    windowElement: appElement,
                    appElement: appElement,
                    isMinimized: false
                ))
            }
        }

        print("[ContextSwitcher] Enumerated \(results.count) windows from \(Set(results.map(\.bundleIdentifier)).count) apps (AX: \(isAccessibilityGranted))")
        return results
    }

    /// 특정 창을 최상단으로 올리기
    func raiseWindow(_ window: DiscoveredWindow) {
        // 최소화 해제
        if window.isMinimized {
            AXUIElementSetAttributeValue(
                window.windowElement,
                kAXMinimizedAttribute as CFString,
                false as CFTypeRef
            )
        }

        // 창을 앱 내에서 최상단으로
        AXUIElementPerformAction(window.windowElement, kAXRaiseAction as CFString)

        // 메인 윈도우로 설정
        AXUIElementSetAttributeValue(
            window.windowElement,
            kAXMainAttribute as CFString,
            true as CFTypeRef
        )

        // 앱 활성화
        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.activate()
        }
    }

    /// 특정 창을 최소화
    func minimizeWindow(_ window: DiscoveredWindow) {
        AXUIElementSetAttributeValue(
            window.windowElement,
            kAXMinimizedAttribute as CFString,
            true as CFTypeRef
        )
    }

    // MARK: - AXUIElement 헬퍼

    private func axValue<T>(_ element: AXUIElement, _ attribute: String) -> T? {
        var ref: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success
        else { return nil }
        return ref as? T
    }

    private func axWindows(of appElement: AXUIElement) -> [AXUIElement] {
        var ref: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &ref
        ) == .success else { return [] }
        return ref as? [AXUIElement] ?? []
    }
}
