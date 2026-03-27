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
        let cfg = defaultTradeVPConfig
        return "< \(cfg.midThreshold) icons = 0 VP  •  \(cfg.midThreshold)–\(cfg.highThreshold - 1) icons = \(cfg.midVP) VP  •  \(cfg.highThreshold)+ icons = \(cfg.highVP) VP"
    }

    /// Calculate VP from the raw input value stored in Player.
    func victoryPoints(for rawInput: Int, config: TradeVPConfig? = nil) -> Int {
        switch scoringType {
        case .direct:
            return rawInput
        case .trade:
            let cfg = config ?? defaultTradeVPConfig
            if rawInput >= cfg.highThreshold { return cfg.highVP }
            if rawInput >= cfg.midThreshold { return cfg.midVP }
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

    /// The default trade VP config for this category (unique thresholds per trade good).
    var defaultTradeVPConfig: TradeVPConfig {
        switch self {
        case .cooking:    return TradeVPConfig(midThreshold: 5, highThreshold: 9, midVP: 4, highVP: 7)
        case .carpentry:  return TradeVPConfig(midThreshold: 5, highThreshold: 8, midVP: 4, highVP: 7)
        case .sewing:     return TradeVPConfig(midThreshold: 5, highThreshold: 7, midVP: 4, highVP: 7)
        case .shoemaking: return TradeVPConfig(midThreshold: 4, highThreshold: 6, midVP: 4, highVP: 7)
        case .art:        return TradeVPConfig(midThreshold: 4, highThreshold: 5, midVP: 4, highVP: 7)
        case .smithing:   return TradeVPConfig(midThreshold: 3, highThreshold: 5, midVP: 4, highVP: 7)
        case .jewelry:    return TradeVPConfig(midThreshold: 3, highThreshold: 4, midVP: 4, highVP: 7)
        default:          return .defaultConfig
        }
    }

    /// Asset catalog image name, if a custom icon exists for this category.
    var imageName: String? {
        switch self {
        case .cooking:    return "cooking"
        case .carpentry:  return "carpentry"
        case .sewing:     return "sewing"
        case .shoemaking: return "shoemaking"
        case .art:        return "art"
        case .smithing:   return "smithing"
        case .jewelry:    return "jewelry"
        default:          return nil
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
    func victoryPoints(for category: ScoreCategory, config: TradeVPConfig? = nil) -> Int {
        category.victoryPoints(for: rawInput(for: category), config: config)
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

/// Stores the VP values and icon thresholds for a trade category.
struct TradeVPConfig: Codable, Equatable {
    var midThreshold: Int  // minimum icons for mid VP
    var highThreshold: Int // minimum icons for high VP
    var midVP: Int         // VP awarded at mid threshold
    var highVP: Int        // VP awarded at high threshold

    /// Generic fallback — each category should use its own default via ScoreCategory.defaultTradeVPConfig.
    static let defaultConfig = TradeVPConfig(midThreshold: 5, highThreshold: 9, midVP: 4, highVP: 7)
}

@Observable
final class GameModel {
    var players: [Player] = [] {
        didSet { save() }
    }
    var isSetupComplete: Bool = false {
        didSet { save() }
    }
    /// Per-category VP config for trade goods. Keyed by ScoreCategory.rawValue.
    var tradeVPConfigs: [String: TradeVPConfig] = [:] {
        didSet { save() }
    }

    private let saveKey: String

    init(saveKey: String = "SixSojournsGameState") {
        self.saveKey = saveKey
        load()
    }

    func setupPlayers(count: Int, names: [String]) {
        players = (0..<count).map { Player(name: names[$0]) }
        isSetupComplete = true
    }

    /// Adjust the number of players while preserving existing scores.
    /// New players get default names; removed players are trimmed from the end.
    func setPlayerCount(_ count: Int) {
        let clamped = max(1, min(4, count))
        if clamped > players.count {
            for i in players.count..<clamped {
                players.append(Player(name: "Player \(i + 1)"))
            }
        } else if clamped < players.count {
            players = Array(players.prefix(clamped))
        }
    }

    /// Compute total VP for a player using the configured trade VP values.
    func totalVP(for player: Player) -> Int {
        ScoreCategory.allCases.map { cat in
            player.victoryPoints(for: cat, config: tradeVPConfig(for: cat))
        }.reduce(0, +)
    }

    func tradeVPConfig(for category: ScoreCategory) -> TradeVPConfig {
        tradeVPConfigs[category.rawValue] ?? category.defaultTradeVPConfig
    }

    func setTradeVPConfig(_ config: TradeVPConfig, for category: ScoreCategory) {
        tradeVPConfigs[category.rawValue] = config
    }

    func updateRawInput(playerIndex: Int, category: ScoreCategory, value: Int) {
        guard playerIndex < players.count else { return }
        players[playerIndex].setRawInput(value, for: category)
    }

    func resetGame() {
        let count = max(players.count, 2)
        let names = (1...4).map { "Player \($0)" }
        players = (0..<count).map { Player(name: names[$0]) }
    }

    // MARK: Persistence

    private struct SavedState: Codable {
        var players: [Player]
        var isSetupComplete: Bool
        var tradeVPConfigs: [String: TradeVPConfig]?
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(
            SavedState(players: players, isSetupComplete: isSetupComplete, tradeVPConfigs: tradeVPConfigs)
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
        tradeVPConfigs = state.tradeVPConfigs ?? [:]
    }
}
