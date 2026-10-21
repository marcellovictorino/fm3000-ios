import Foundation

public struct CardAction: Codable, Equatable, Identifiable {
    public let id: String
    public let label: String
    public let variant: String?
    public let `default`: Bool?
    public let keepsOpen: Bool?
    public var isDefault: Bool { `default` == true }
}

public struct Card: Codable, Equatable, Identifiable {
    public let id: String
    public let taskId: String?
    public let author: String
    public let priority: Double
    public let title: String
    public let meta: String
    public let body: String
    public let actions: [CardAction]
    public let status: String
    public let createdAt: Double
    public let holdsPlace: Bool?
    public let asking: Bool?
}

public struct ThreadMessage: Codable, Equatable, Identifiable {
    public let id: Double
    public let cardId: String
    public let who: String
    public let text: String
    public let at: Double
}

public struct CardThread: Codable, Equatable {
    public let cardId: String
    public let messages: [ThreadMessage]
}

/// What `fm:cards:act` answers: the effect only a Mac window can show, or the Mac's refusal.
public struct ActResult: Codable, Equatable {
    public struct Effect: Codable, Equatable { public let kind: String; public let target: String? }
    public let effect: Effect?
    public let refusal: String?
}

public struct FeedLine: Codable, Equatable, Identifiable {
    public let kind: String
    public let text: String
    public let at: Double
    public let taskKey: String?
    public let event: String?
    public var id: String { "\(at)-\(text)" }
}

public struct BoardTask: Codable, Equatable, Identifiable {
    public let id: String
    public let key: String
    public let projectId: String
    public let title: String
    public let kind: String
    public let status: String
    public let activity: String?
    public let assignee: String?
    public let model: String?
    public let waitingCardId: String?
    public let updatedAt: Double
}

public struct BoardProject: Codable, Equatable, Identifiable {
    public struct Counts: Codable, Equatable { public let needsYou: Int; public let open: Int; public let active: Int }
    public let id: String
    public let key: String
    public let name: String
    public let archived: Bool
    public let counts: Counts
}

public struct Board: Codable, Equatable {
    public let projects: [BoardProject]
    public let tasks: [BoardTask]
}
