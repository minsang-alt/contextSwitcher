import Foundation

/// IntelliJ 창 제목에서 프로젝트 이름을 추출하는 유틸리티
enum IntelliJTitleParser {
    /// IntelliJ 창 제목에서 프로젝트명을 추출
    /// 형식: "ProjectName \u{2013} File.java [Module]" 또는 "ProjectName"
    static func extractProjectName(from windowTitle: String) -> String {
        let enDash: Character = "\u{2013}"

        if let dashIndex = windowTitle.firstIndex(of: enDash) {
            var projectPart = String(windowTitle[..<dashIndex])
                .trimmingCharacters(in: .whitespaces)

            // "[main]" 같은 브랜치 주석 제거
            if let bracketIndex = projectPart.firstIndex(of: "[") {
                projectPart = String(projectPart[..<bracketIndex])
                    .trimmingCharacters(in: .whitespaces)
            }

            return projectPart
        }

        return windowTitle.trimmingCharacters(in: .whitespaces)
    }
}
