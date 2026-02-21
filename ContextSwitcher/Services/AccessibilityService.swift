import AppKit
import ApplicationServices

/// Accessibility API를 통해 발견된 창 정보
struct DiscoveredWindow: Identifiable {
    let appName: String
    let bundleIdentifier: String
    let pid: pid_t
    let windowTitle: String
    let windowElement: AXUIElement
    let appElement: AXUIElement
    let isMinimized: Bool
    /// 앱 내 윈도우 순서 (0-based). 탭/파일 전환에도 안정적
    let windowIndex: Int

    /// bundleIdentifier + 윈도우 인덱스 기반 ID (탭/파일 전환에 영향 안 받음)
    var id: String { "\(bundleIdentifier):\(windowIndex)" }

    /// 탭/파일 전환에도 안정적인 식별 이름 (저장 및 매칭용)
    var stableIdentityName: String {
        // Chrome 계열: "페이지제목 - Chrome - 프로필명" → 프로필명 추출
        if bundleIdentifier == "com.google.Chrome" ||
           bundleIdentifier == "com.google.Chrome.canary" ||
           bundleIdentifier == "com.brave.Browser" ||
           bundleIdentifier == "com.microsoft.edgemac" {
            if let range = windowTitle.range(of: " - Chrome - ", options: .backwards) ??
                           windowTitle.range(of: " - Brave - ", options: .backwards) ??
                           windowTitle.range(of: " - Edge - ", options: .backwards) {
                return String(windowTitle[range.upperBound...])
            }
        }

        // JetBrains IDE: IntelliJTitleParser 사용
        if bundleIdentifier.hasPrefix("com.jetbrains.") {
            return IntelliJTitleParser.extractProjectName(from: windowTitle)
        }

        return windowTitle
    }

    /// UI 표시용 이름 (안정적 이름 + 현재 컨텍스트)
    var displayName: String {
        let stable = stableIdentityName
        if stable == windowTitle || windowTitle.isEmpty {
            return windowTitle
        }
        // "프로필명 · 현재탭제목" 또는 "프로젝트명 · 현재파일"
        // 현재 컨텍스트 부분 추출
        if let range = windowTitle.range(of: " - Chrome - ", options: .backwards) ??
                       windowTitle.range(of: " - Brave - ", options: .backwards) ??
                       windowTitle.range(of: " - Edge - ", options: .backwards) {
            let tabTitle = String(windowTitle[..<range.lowerBound])
            return "\(stable) · \(tabTitle)"
        }
        if bundleIdentifier.hasPrefix("com.jetbrains.") {
            let enDash: Character = "\u{2013}"
            if let dashIdx = windowTitle.firstIndex(of: enDash) {
                let fileName = String(windowTitle[windowTitle.index(after: dashIdx)...])
                    .trimmingCharacters(in: .whitespaces)
                return "\(stable) · \(fileName)"
            }
        }
        return windowTitle
    }
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
                        isMinimized: false,
                        windowIndex: 0
                    ))
                } else {
                    for (index, window) in windows.enumerated() {
                        let title: String = axValue(window, kAXTitleAttribute) ?? ""
                        let isMinimized: Bool = axValue(window, kAXMinimizedAttribute) ?? false

                        results.append(DiscoveredWindow(
                            appName: appName,
                            bundleIdentifier: bundleID,
                            pid: pid,
                            windowTitle: title,
                            windowElement: window,
                            appElement: appElement,
                            isMinimized: isMinimized,
                            windowIndex: index
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
                    isMinimized: false,
                    windowIndex: 0
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
