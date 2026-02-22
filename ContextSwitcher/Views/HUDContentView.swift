import SwiftUI

/// 플로팅 HUD에 표시되는 워크스페이스 목록
struct HUDContentView: View {
    @ObservedObject private var store = WorkspaceStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.secondary)
                Text("Workspaces")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 8)

            if store.workspaces.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No workspaces yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(store.workspaces) { workspace in
                            WorkspaceHUDRow(workspace: workspace)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                }
            }
        }
        .frame(
            width: 260,
            height: min(CGFloat(max(store.workspaces.count, 1) * 44 + 60), 320)
        )
        .hudBackground(cornerRadius: 14)
    }
}

struct WorkspaceHUDRow: View {
    @ObservedObject var workspace: WorkspaceConfiguration

    var body: some View {
        Button {
            WorkspaceStore.shared.activate(workspace)
            WorkspaceSwitchService.shared.switchTo(workspace: workspace)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(workspace.isActive ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(workspace.name)
                            .font(.system(size: 13, weight: workspace.isActive ? .semibold : .regular))
                            .foregroundStyle(.primary)
                        if let shortcutText = workspace.shortcut?.displayString {
                            Text(shortcutText)
                                .font(.system(size: 9, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(3)
                        }
                    }
                    Text("\(workspace.windowIdentifiers.count) apps")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if workspace.isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(workspace.isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}
