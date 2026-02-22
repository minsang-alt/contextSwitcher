import SwiftUI

/// 현재 실행 중인 창들을 캡처하여 워크스페이스에 추가/편집하는 뷰
struct CaptureView: View {
    var onDismiss: () -> Void
    /// nil이면 신규 생성, 값이 있으면 편집 모드
    var editingWorkspace: WorkspaceConfiguration?

    @State private var workspaceName = ""
    @State private var discoveredWindows: [DiscoveredWindow] = []
    @State private var selectedWindowIDs: Set<String> = []
    @State private var shortcut: KeyShortcut?
    /// 신규 생성 시 임시로 사용할 워크스페이스 ID
    @State private var pendingWorkspaceID = UUID()

    private var isEditing: Bool { editingWorkspace != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Workspace" : "Capture Current Layout")
                .font(.headline)

            TextField("Workspace name", text: $workspaceName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Shortcut")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ShortcutRecorderView(shortcut: $shortcut)
            }

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
                .frame(maxHeight: 250)
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
        .frame(width: 400, height: 480)
        .onAppear {
            // 이미 스캔된 상태면 재스캔하지 않음 (앱 전환 후 돌아와도 체크 유지)
            guard discoveredWindows.isEmpty else { return }

            if let ws = editingWorkspace {
                workspaceName = ws.name
                shortcut = ws.shortcut
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
        let windowIDs = Set(group.windows.map(\.id))
        let selectedCount = windowIDs.filter { selectedWindowIDs.contains($0) }.count
        let allSelected = selectedCount == windowIDs.count
        let noneSelected = selectedCount == 0

        VStack(alignment: .leading, spacing: 0) {
            // 앱 헤더 — Button으로 구현 (Toggle 바인딩 연쇄 호출 방지)
            Button {
                if allSelected {
                    selectedWindowIDs.subtract(windowIDs)
                } else {
                    selectedWindowIDs.formUnion(windowIDs)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: allSelected ? "checkmark.square.fill" :
                            noneSelected ? "square" : "minus.square.fill")
                        .foregroundColor(noneSelected ? .secondary : .accentColor)
                    Text(group.appName)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)

            // 창이 2개 이상이면 개별 창 체크박스 표시
            if group.windows.count > 1 {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(group.windows) { window in
                        Button {
                            if selectedWindowIDs.contains(window.id) {
                                selectedWindowIDs.remove(window.id)
                            } else {
                                selectedWindowIDs.insert(window.id)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedWindowIDs.contains(window.id) ?
                                        "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedWindowIDs.contains(window.id) ? .accentColor : .secondary)
                                Text(window.displayName.isEmpty ? "(제목 없음)" : window.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
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
                            identifier.matches(window: window)
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

        // 앱별 전체 창 개수와 선택된 창 개수 캐싱
        var totalCounts: [String: Int] = [:]
        var selectedCounts: [String: Int] = [:]
        for window in discoveredWindows {
            totalCounts[window.bundleIdentifier, default: 0] += 1
        }
        for window in selectedWindows {
            selectedCounts[window.bundleIdentifier, default: 0] += 1
        }

        // Chrome/Brave/Edge: 탭 제목이 아닌 프로필명이 stableIdentityName이라서
        // 부분 선택 시 전체 프로필 창이 매칭되는 문제를 방지하기 위해 원본 창 제목을 사용
        let chromiumBundleIDs: Set<String> = [
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "com.brave.Browser",
            "com.microsoft.edgemac"
        ]

        var identifiers: [WindowIdentifier] = []
        var processedBundleIDs: Set<String> = []

        for window in selectedWindows {
            let bundleID = window.bundleIdentifier
            let total = totalCounts[bundleID] ?? 0
            let selected = selectedCounts[bundleID] ?? 0

            if processedBundleIDs.contains(bundleID) && selected == total {
                continue
            }

            if selected == total {
                identifiers.append(WindowIdentifier(bundleIdentifier: bundleID, titlePattern: ""))
                processedBundleIDs.insert(bundleID)
            } else {
                let pattern: String
                if chromiumBundleIDs.contains(bundleID) {
                    pattern = window.windowTitle.isEmpty ? window.stableIdentityName : window.windowTitle
                } else {
                    pattern = window.stableIdentityName
                }

                if !pattern.isEmpty {
                    identifiers.append(WindowIdentifier(
                        bundleIdentifier: bundleID,
                        titlePattern: pattern,
                        windowID: window.id
                    ))
                }
            }
        }

        return identifiers
    }

    private func saveWorkspace() {
        let identifiers = buildIdentifiers()

        if let ws = editingWorkspace {
            WorkspaceStore.shared.update(ws, name: workspaceName, identifiers: identifiers, shortcut: shortcut)
        } else {
            let workspace = WorkspaceConfiguration(
                id: pendingWorkspaceID,
                name: workspaceName,
                windowIdentifiers: identifiers,
                shortcut: shortcut
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
