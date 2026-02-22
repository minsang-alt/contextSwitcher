import Foundation

/// 워크스페이스에 포함된 앱+창을 식별하기 위한 패턴
struct WindowIdentifier: Codable, Hashable, Identifiable {
    var id: String { windowID ?? "\(bundleIdentifier):\(titlePattern)" }

    /// 앱의 Bundle ID (예: "com.jetbrains.intellij")
    let bundleIdentifier: String

    /// 창 제목에 포함되어야 할 텍스트 (contains 매칭)
    /// 빈 문자열이면 해당 앱의 모든 창과 매칭
    let titlePattern: String

    /// 특정 실행 중인 창을 지칭하기 위한 내부 ID (bundleID:pid:windowIndex)
    /// 앱 재실행 시 달라질 수 있으므로 titlePattern과 함께 사용
    let windowID: String?

    init(bundleIdentifier: String, titlePattern: String, windowID: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.titlePattern = titlePattern
        self.windowID = windowID
    }

    /// 주어진 창이 이 식별자와 매칭되는지 확인
    func matches(window: DiscoveredWindow) -> Bool {
        guard window.bundleIdentifier == bundleIdentifier else { return false }

        // 1) 정확한 창 ID 우선 매칭 (동일 실행 세션에서 탭 이동/제목 변경 보호)
        if let windowID, window.id == windowID {
            return true
        }

        // 2) 제목 패턴 매칭
        if titlePattern.isEmpty { return true }
        return window.windowTitle.localizedCaseInsensitiveContains(titlePattern) ||
               window.stableIdentityName.localizedCaseInsensitiveContains(titlePattern)
    }
}
