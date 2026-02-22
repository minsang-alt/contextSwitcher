import SwiftUI

/// 메뉴바 팝오버의 루트 뷰
struct MenuBarContentView: View {
    @State private var accessibilityGranted = AccessibilityService.shared.isAccessibilityGranted

    var body: some View {
        VStack(spacing: 0) {
            if !accessibilityGranted {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("Accessibility permission required")
                        .font(.caption)
                    Spacer()
                    Button("Grant") {
                        AccessibilityService.shared.requestAccessibilityPermission()
                    }
                    .font(.caption)
                }
                .padding(10)
                .background(Color.yellow.opacity(0.1))

                Divider()
            }

            WorkspaceListView()
        }
        .frame(width: 300, height: accessibilityGranted ? 380 : 420)
        .onAppear {
            // 권한 상태를 주기적으로 확인
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                let granted = AccessibilityService.shared.isAccessibilityGranted
                if granted != accessibilityGranted {
                    accessibilityGranted = granted
                    if granted {
                        ShortcutService.shared.start()
                    }
                }
                if granted { timer.invalidate() }
            }
        }
    }
}
