import SwiftUI

/// 메뉴바 팝오버에서 워크스페이스를 관리하는 목록 뷰
struct WorkspaceListView: View {
    @ObservedObject private var store = WorkspaceStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Workspaces")
                    .font(.headline)
                Spacer()
                Button {
                    CaptureWindowController.shared.show()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            if store.workspaces.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No workspaces")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Click + to capture your current layout")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                List {
                    ForEach(store.workspaces) { workspace in
                        WorkspaceRow(workspace: workspace)
                    }
                    .onDelete { offsets in
                        store.remove(at: offsets)
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            Button {
                WorkspaceSwitchService.shared.showAllApps()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                    Text("Show All Apps")
                        .font(.caption)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            Divider()

            HStack {
                Button("Toggle HUD") {
                    HUDController.shared.toggle()
                }
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }
}

struct WorkspaceRow: View {
    @ObservedObject var workspace: WorkspaceConfiguration

    var body: some View {
        HStack(spacing: 10) {
            // 전환 버튼 (좌측 인디케이터)
            Button {
                WorkspaceStore.shared.activate(workspace)
                WorkspaceSwitchService.shared.switchTo(workspace: workspace)
            } label: {
                Circle()
                    .fill(workspace.isActive ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .buttonStyle(.plain)

            // 편집 버튼 (이름+앱 수 영역)
            Button {
                CaptureWindowController.shared.showEdit(workspace)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(workspace.name)
                            .font(.system(size: 13, weight: workspace.isActive ? .semibold : .regular))
                        if let shortcutText = workspace.shortcut?.displayString {
                            Text(shortcutText)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(3)
                        }
                    }
                    Text("\(workspace.windowIdentifiers.count) apps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .buttonStyle(.plain)

            // 전환 아이콘
            Button {
                WorkspaceStore.shared.activate(workspace)
                WorkspaceSwitchService.shared.switchTo(workspace: workspace)
            } label: {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
