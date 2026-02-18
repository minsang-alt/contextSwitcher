import Foundation

/// 워크스페이스에 포함된 앱+창을 식별하기 위한 패턴
struct WindowIdentifier: Codable, Hashable, Identifiable {
    var id: String { "\(bundleIdentifier):\(titlePattern)" }

    /// 앱의 Bundle ID (예: "com.jetbrains.intellij")
    let bundleIdentifier: String

    /// 창 제목에 포함되어야 할 텍스트 (contains 매칭)
    /// 빈 문자열이면 해당 앱의 모든 창과 매칭
    let titlePattern: String

    /// 주어진 창 제목이 이 식별자와 매칭되는지 확인
    func matches(bundleID: String, windowTitle: String) -> Bool {
        guard bundleID == bundleIdentifier else { return false }
        if titlePattern.isEmpty { return true }
        return windowTitle.localizedCaseInsensitiveContains(titlePattern)
    }
}
