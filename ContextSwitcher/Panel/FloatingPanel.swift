import AppKit
import SwiftUI

/// 항상 최상단에 떠 있는 비활성화(non-activating) 플로팅 패널
final class FloatingPanel: NSPanel {
    init(contentRect: NSRect = NSRect(x: 0, y: 0, width: 280, height: 300)) {
        // nonactivatingPanel은 borderless 없이 사용해야 경고가 없음
        // titled + nonactivatingPanel 조합 사용 후 타이틀바 숨김 처리
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
        ]

        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hasShadow = true

        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        animationBehavior = .utilityWindow
    }

    // 포커스를 훔치지 않음
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
