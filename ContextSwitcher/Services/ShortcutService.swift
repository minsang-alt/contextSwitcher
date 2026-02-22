import Foundation
import AppKit

/// CGEvent tap을 사용한 글로벌 키보드 단축키 서비스
final class ShortcutService {
    static let shared = ShortcutService()

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    /// 앱 시작 시 호출하여 글로벌 이벤트 탭 설정
    func start() {
        guard eventTap == nil else { return }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: shortcutEventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[ContextSwitcher] Failed to create event tap (Accessibility permission required)")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[ContextSwitcher] Global shortcut service started")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// 키 이벤트 처리. 매칭되면 true 반환하여 이벤트 소비
    func handleKeyEvent(_ event: CGEvent) -> Bool {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // modifier 없는 단일 키는 무시 (일반 타이핑 방해 방지)
        let relevantFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
        guard !flags.intersection(relevantFlags).isEmpty else { return false }

        for workspace in WorkspaceStore.shared.workspaces {
            guard let shortcut = workspace.shortcut else { continue }
            if shortcut.matches(keyCode: keyCode, cgFlags: flags) {
                DispatchQueue.main.async {
                    WorkspaceStore.shared.activate(workspace)
                    WorkspaceSwitchService.shared.switchTo(workspace: workspace)
                }
                return true
            }
        }
        return false
    }
}

// MARK: - CGEvent tap 콜백 (C 함수)

private func shortcutEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // 이벤트 탭이 비활성화되면 재활성화
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let service = Unmanaged<ShortcutService>.fromOpaque(userInfo).takeUnretainedValue()
            if let tap = service.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown, let userInfo = userInfo else {
        return Unmanaged.passRetained(event)
    }

    let service = Unmanaged<ShortcutService>.fromOpaque(userInfo).takeUnretainedValue()

    if service.handleKeyEvent(event) {
        return nil  // 이벤트 소비 (다른 앱에 전달하지 않음)
    }
    return Unmanaged.passRetained(event)
}
