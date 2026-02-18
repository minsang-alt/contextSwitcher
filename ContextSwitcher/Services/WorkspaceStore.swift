import Foundation
import Combine

/// JSON 파일 기반 워크스페이스 저장소
final class WorkspaceStore: ObservableObject {
    static let shared = WorkspaceStore()

    @Published var workspaces: [WorkspaceConfiguration] = []

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("ContextSwitcher", isDirectory: true)

        // 디렉토리 생성
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        fileURL = appSupport.appendingPathComponent("workspaces.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            workspaces = try JSONDecoder().decode([WorkspaceConfiguration].self, from: data)
        } catch {
            print("Failed to load workspaces: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save workspaces: \(error)")
        }
    }

    func add(_ workspace: WorkspaceConfiguration) {
        workspace.displayOrder = workspaces.count
        workspaces.append(workspace)
        save()
    }

    func remove(at offsets: IndexSet) {
        workspaces.remove(atOffsets: offsets)
        save()
    }

    func remove(_ workspace: WorkspaceConfiguration) {
        workspaces.removeAll { $0.id == workspace.id }
        save()
    }

    func deactivateAll() {
        for ws in workspaces {
            ws.isActive = false
        }
    }

    func update(_ workspace: WorkspaceConfiguration, name: String, identifiers: [WindowIdentifier]) {
        workspace.name = name
        workspace.windowIdentifiers = identifiers
        save()
    }

    func activate(_ workspace: WorkspaceConfiguration) {
        deactivateAll()
        workspace.isActive = true
        save()
    }
}
