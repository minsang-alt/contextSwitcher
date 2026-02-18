import AppKit
import SwiftUI

/// 플로팅 HUD 패널의 생명주기를 관리
final class HUDController {
    static let shared = HUDController()

    private var panel: FloatingPanel?

    private init() {}

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            let newPanel = FloatingPanel()
            newPanel.contentView = NSHostingView(
                rootView: HUDContentView().ignoresSafeArea()
            )
            panel = newPanel
        }

        // 화면 우측 상단에 배치
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelSize = panel!.frame.size
            let x = screenFrame.maxX - panelSize.width - 20
            let y = screenFrame.maxY - panelSize.height - 20
            panel?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel?.orderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
