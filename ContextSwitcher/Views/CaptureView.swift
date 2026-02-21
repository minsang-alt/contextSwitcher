import SwiftUI

/// 현재 실행 중인 창들을 캡처하여 워크스페이스에 추가/편집하는 뷰
struct CaptureView: View {
    var onDismiss: () -> Void
    /// nil이면 신규 생성, 값이 있으면 편집 모드
    var editingWorkspace: WorkspaceConfiguration?

    @State private var workspaceName = ""
    @State private var discoveredWindows: [DiscoveredWindow] = []
    @State private var selectedWindowIDs: Set<String> = []

    private var isEditing: Bool { editingWorkspace != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Workspace" : "Capture Current Layout")
                .font(.headline)

            TextField("Workspace name", text: $workspaceName)
                .textFieldStyle(.roundedBorder)

            Divider()

            if discoveredWindows.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Scanning windows...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Text("Select apps to include (\(selectedAppCount)/\(groupedByApp.count)):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(groupedByApp, id: \.bundleID) { group in
                            appGroupView(group)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }

            Divider()

            HStack {
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if isEditing {
                    Button("Delete", role: .destructive) { deleteWorkspace() }
                        .foregroundStyle(.red)
                }
                Button(isEditing ? "Save Changes" : "Save Workspace") { saveWorkspace() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(workspaceName.isEmpty || selectedWindowIDs.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 450)
        .onAppear {
            // 이미 스캔된 상태면 재스캔하지 않음 (앱 전환 후 돌아와도 체크 유지)
            guard discoveredWindows.isEmpty else { return }

            if let ws = editingWorkspace {
                workspaceName = ws.name
            } else {
                let count = WorkspaceStore.shared.workspaces.count + 1
                workspaceName = "Workspace \(count)"
            }
            scanWindows()
        }
    }

    // MARK: - 앱 그룹 뷰

    @ViewBuilder
    private func appGroupView(_ group: AppGroup) -> some View {
        let windowIDs = group.windows.map(\.id)
        let allSelected = windowIDs.allSatisfy { selectedWindowIDs.contains($0) }

        VStack(alignment: .leading, spacing: 0) {
            // 앱 헤더 토글
            Toggle(isOn: Binding(
                get: { allSelected },
                set: { isOn in
                    if isOn {
                        selectedWindowIDs.formUnion(windowIDs)
                    } else {
                        selectedWindowIDs.subtract(windowIDs)
                    }
                }
            )) {
                Text(group.appName)
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.checkbox)
            .padding(.vertical, 4)

            // 창이 2개 이상이면 개별 창 체크박스 표시
            if group.windows.count > 1 {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(group.windows) { window in
                        Toggle(isOn: Binding(
                            get: { selectedWindowIDs.contains(window.id) },
                            set: { isOn in
                                if isOn {
                                    selectedWindowIDs.insert(window.id)
                                } else {
                                    selectedWindowIDs.remove(window.id)
                                }
                            }
                        )) {
                            Text(window.displayName.isEmpty ? "(제목 없음)" : window.displayName)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .toggleStyle(.checkbox)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, 20)
            } else if let window = group.windows.first, !window.displayName.isEmpty {
                // 창이 1개면 표시
                Text(window.displayName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.leading, 20)
            }
        }
    }

    // MARK: - 앱별 그룹핑

    private struct AppGroup {
        let appName: String
        let bundleID: String
        let windows: [DiscoveredWindow]
    }

    private var groupedByApp: [AppGroup] {
        var groups: [String: (name: String, windows: [DiscoveredWindow])] = [:]
        for window in discoveredWindows {
            let key = window.bundleIdentifier
            if groups[key] == nil {
                groups[key] = (name: window.appName, windows: [])
            }
            groups[key]?.windows.append(window)
        }
        return groups.map {
            AppGroup(appName: $0.value.name, bundleID: $0.key, windows: $0.value.windows)
        }
        .sorted { $0.appName < $1.appName }
    }

    /// 1개 이상의 창이 선택된 앱 수
    private var selectedAppCount: Int {
        let selectedBundleIDs = discoveredWindows
            .filter { selectedWindowIDs.contains($0.id) }
            .map(\.bundleIdentifier)
        return Set(selectedBundleIDs).count
    }

    // MARK: - 액션

    private func scanWindows() {
        DispatchQueue.global(qos: .userInitiated).async {
            let windows = AccessibilityService.shared.enumerateAllWindows()
            DispatchQueue.main.async {
                discoveredWindows = windows

                if let ws = editingWorkspace {
                    // 편집 모드: 기존 워크스페이스에 매칭되는 창만 선택
                    // stableIdentityName과 windowTitle 모두 매칭 시도 (기존 데이터 호환)
                    selectedWindowIDs = Set(windows.filter { window in
                        ws.windowIdentifiers.contains { identifier in
                            identifier.matches(bundleID: window.bundleIdentifier, windowTitle: window.windowTitle) ||
                            identifier.matches(bundleID: window.bundleIdentifier, windowTitle: window.stableIdentityName)
                        }
                    }.map(\.id))
                } else {
                    // 신규: 전체 선택
                    selectedWindowIDs = Set(windows.map(\.id))
                }
            }
        }
    }

    private func buildIdentifiers() -> [WindowIdentifier] {
        let selectedWindows = discoveredWindows.filter { selectedWindowIDs.contains($0.id) }
        var appWindowCounts: [String: Int] = [:]
        for window in discoveredWindows {
            appWindowCounts[window.bundleIdentifier, default: 0] += 1
        }

        var identifiers: [WindowIdentifier] = []
        var processedBundleIDs: Set<String> = []

        for window in selectedWindows {
            let bundleID = window.bundleIdentifier
            let totalWindows = appWindowCounts[bundleID] ?? 0
            let selectedCount = selectedWindows.filter { $0.bundleIdentifier == bundleID }.count

            if processedBundleIDs.contains(bundleID) && selectedCount == totalWindows {
                continue
            }

            if selectedCount == totalWindows {
                identifiers.append(WindowIdentifier(bundleIdentifier: bundleID, titlePattern: ""))
                processedBundleIDs.insert(bundleID)
            } else {
                let pattern = window.stableIdentityName
                if !pattern.isEmpty {
                    identifiers.append(WindowIdentifier(
                        bundleIdentifier: bundleID,
                        titlePattern: pattern
                    ))
                }
            }
        }

        return identifiers
    }

    private func saveWorkspace() {
        let identifiers = buildIdentifiers()

        if let ws = editingWorkspace {
            WorkspaceStore.shared.update(ws, name: workspaceName, identifiers: identifiers)
        } else {
            let workspace = WorkspaceConfiguration(
                name: workspaceName,
                windowIdentifiers: identifiers
            )
            WorkspaceStore.shared.add(workspace)
        }
        onDismiss()
    }

    private func deleteWorkspace() {
        if let ws = editingWorkspace {
            WorkspaceStore.shared.remove(ws)
        }
        onDismiss()
    }
}
