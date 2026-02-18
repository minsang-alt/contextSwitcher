import Foundation

/// 워크스페이스 설정 - JSON 파일로 저장
final class WorkspaceConfiguration: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var windowIdentifiers: [WindowIdentifier]
    @Published var isActive: Bool
    @Published var displayOrder: Int
    let createdAt: Date

    init(
        name: String,
        windowIdentifiers: [WindowIdentifier] = [],
        isActive: Bool = false,
        displayOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.windowIdentifiers = windowIdentifiers
        self.isActive = isActive
        self.displayOrder = displayOrder
        self.createdAt = Date()
    }

    // MARK: - Codable (Published 프로퍼티 수동 구현)

    enum CodingKeys: String, CodingKey {
        case id, name, windowIdentifiers, isActive, displayOrder, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        windowIdentifiers = try container.decode([WindowIdentifier].self, forKey: .windowIdentifiers)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(windowIdentifiers, forKey: .windowIdentifiers)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(displayOrder, forKey: .displayOrder)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
