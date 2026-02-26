import Foundation
import Observation

// MARK: - Score Categories

enum ScoringType {
    case direct   // raw input == VP (spaces, islands, card objectives, expansion)
    case trade    // icon count → 0 / 4 / 7 VP based on thresholds
}

enum ScoreCategory: String, CaseIterable, Identifiable, Codable {
    // Map / board scoring
    case spaces    = "Spaces"
    case islands   = "Islands"

    // Trade icon scoring (threshold-based)
    case cooking   = "Cooking"
    case carpentry = "Carpentry"
    case sewing    = "Sewing"
    case shoemaking = "Shoe-Making"
    case art       = "Art"
    case smithing  = "Smithing"
    case jewelry   = "Jewelry"

    // Flat VP
    case cardVP    = "Card Objectives"
    case expansion = "Expansion Bonuses"

    var id: String { rawValue }

    var scoringType: ScoringType {
        switch self {
        case .cooking, .carpentry, .sewing, .shoemaking, .art, .smithing, .jewelry:
            return .trade
        default:
            return .direct
        }
    }

    /// Human-readable label for what the user is entering.
    var inputLabel: String {
        switch scoringType {
        case .trade:  return "Icons"
        case .direct: return "VP"
        }
    }

    /// Hint shown in the entry screen footer for trade categories.
    var tradeThresholdHint: String? {
        guard scoringType == .trade else { return nil }
        return "< 4 icons = 0 VP  •  4–8 icons = 4 VP  •  9+ icons = 7 VP"
    }

    /// Calculate VP from the raw input value stored in Player.
    func victoryPoints(for rawInput: Int) -> Int {
        switch scoringType {
        case .direct:
            return rawInput
        case .trade:
            if rawInput >= 9 { return 7 }
            if rawInput >= 4 { return 4 }
            return 0
        }
    }

    var systemImage: String {
        switch self {
        case .spaces:    return "square.grid.3x3"
        case .islands:   return "map.fill"
        case .cooking:   return "fork.knife"
        case .carpentry: return "hammer.fill"
        case .sewing:    return "scissors"
        case .shoemaking: return "figure.walk"
        case .art:       return "paintbrush.fill"
        case .smithing:  return "wrench.and.screwdriver.fill"
        case .jewelry:   return "sparkles"
        case .cardVP:    return "rectangle.on.rectangle"
        case .expansion: return "star.fill"
        }
    }
}

// MARK: - Player

struct Player: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    // Keyed by ScoreCategory.rawValue for Codable compatibility.
    // For trade categories, this is the ICON COUNT (not the VP).
    // For direct categories, this is the VP directly.
    var scores: [String: Int] = [:]

    init(name: String) {
        self.name = name
        for category in ScoreCategory.allCases {
            scores[category.rawValue] = 0
        }
    }

    /// The raw value the user entered (icon count for trades, VP for others).
    func rawInput(for category: ScoreCategory) -> Int {
        scores[category.rawValue] ?? 0
    }

    /// The calculated victory points for this category.
    func victoryPoints(for category: ScoreCategory) -> Int {
        category.victoryPoints(for: rawInput(for: category))
    }

    mutating func setRawInput(_ value: Int, for category: ScoreCategory) {
        scores[category.rawValue] = value
    }

    /// Sum of victory points across all categories.
    var total: Int {
        ScoreCategory.allCases.map { victoryPoints(for: $0) }.reduce(0, +)
    }
}

// MARK: - Game Model

@Observable
final class GameModel {
    var players: [Player] = [] {
        didSet { save() }
    }
    var isSetupComplete: Bool = false {
        didSet { save() }
    }

    private let saveKey = "SixSojournsGameState"

    init() {
        load()
    }

    func setupPlayers(count: Int, names: [String]) {
        players = (0..<count).map { Player(name: names[$0]) }
        isSetupComplete = true
    }

    func updateRawInput(playerIndex: Int, category: ScoreCategory, value: Int) {
        guard playerIndex < players.count else { return }
        players[playerIndex].setRawInput(value, for: category)
    }

    func resetGame() {
        players = []
        isSetupComplete = false
    }

    // MARK: Persistence

    private struct SavedState: Codable {
        var players: [Player]
        var isSetupComplete: Bool
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(
            SavedState(players: players, isSetupComplete: isSetupComplete)
        ) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let state = try? JSONDecoder().decode(SavedState.self, from: data)
        else { return }
        players = state.players
        isSetupComplete = state.isSetupComplete
    }
}
