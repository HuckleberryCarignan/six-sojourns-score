import Foundation
import Testing
@testable import SixSojournsScore

// MARK: - ScoreCategory Tests

@Suite("ScoreCategory Tests")
struct ScoreCategoryTests {

    @Test("Direct scoring categories return raw input as VP")
    func directScoringReturnsRawInput() {
        let directCategories: [ScoreCategory] = [.spaces, .islands, .cardVP, .expansion]
        for category in directCategories {
            #expect(category.scoringType == .direct)
            #expect(category.victoryPoints(for: 10) == 10)
            #expect(category.victoryPoints(for: 0) == 0)
            #expect(category.victoryPoints(for: 25) == 25)
        }
    }

    @Test("Trade scoring categories use threshold-based VP")
    func tradeScoringUsesThresholds() {
        let tradeCategories: [ScoreCategory] = [
            .cooking, .carpentry, .sewing, .shoemaking, .art, .smithing, .jewelry
        ]
        for category in tradeCategories {
            #expect(category.scoringType == .trade)
        }
    }

    @Test("Cooking trade thresholds: 0 below 5, 4 at 5-8, 7 at 9+")
    func cookingThresholds() {
        let cat = ScoreCategory.cooking
        #expect(cat.victoryPoints(for: 0) == 0)
        #expect(cat.victoryPoints(for: 4) == 0)
        #expect(cat.victoryPoints(for: 5) == 4)
        #expect(cat.victoryPoints(for: 8) == 4)
        #expect(cat.victoryPoints(for: 9) == 7)
        #expect(cat.victoryPoints(for: 15) == 7)
    }

    @Test("Carpentry trade thresholds: 0 below 5, 4 at 5-7, 7 at 8+")
    func carpentryThresholds() {
        let cat = ScoreCategory.carpentry
        #expect(cat.victoryPoints(for: 4) == 0)
        #expect(cat.victoryPoints(for: 5) == 4)
        #expect(cat.victoryPoints(for: 7) == 4)
        #expect(cat.victoryPoints(for: 8) == 7)
        #expect(cat.victoryPoints(for: 12) == 7)
    }

    @Test("Sewing trade thresholds: 0 below 5, 4 at 5-6, 7 at 7+")
    func sewingThresholds() {
        let cat = ScoreCategory.sewing
        #expect(cat.victoryPoints(for: 4) == 0)
        #expect(cat.victoryPoints(for: 5) == 4)
        #expect(cat.victoryPoints(for: 6) == 4)
        #expect(cat.victoryPoints(for: 7) == 7)
        #expect(cat.victoryPoints(for: 10) == 7)
    }

    @Test("Shoe-Making trade thresholds: 0 below 4, 4 at 4-5, 7 at 6+")
    func shoemakingThresholds() {
        let cat = ScoreCategory.shoemaking
        #expect(cat.victoryPoints(for: 3) == 0)
        #expect(cat.victoryPoints(for: 4) == 4)
        #expect(cat.victoryPoints(for: 5) == 4)
        #expect(cat.victoryPoints(for: 6) == 7)
        #expect(cat.victoryPoints(for: 9) == 7)
    }

    @Test("Art trade thresholds: 0 below 4, 4 at 4, 7 at 5+")
    func artThresholds() {
        let cat = ScoreCategory.art
        #expect(cat.victoryPoints(for: 3) == 0)
        #expect(cat.victoryPoints(for: 4) == 4)
        #expect(cat.victoryPoints(for: 5) == 7)
        #expect(cat.victoryPoints(for: 8) == 7)
    }

    @Test("Smithing trade thresholds: 0 below 3, 4 at 3-4, 7 at 5+")
    func smithingThresholds() {
        let cat = ScoreCategory.smithing
        #expect(cat.victoryPoints(for: 2) == 0)
        #expect(cat.victoryPoints(for: 3) == 4)
        #expect(cat.victoryPoints(for: 4) == 4)
        #expect(cat.victoryPoints(for: 5) == 7)
        #expect(cat.victoryPoints(for: 10) == 7)
    }

    @Test("Jewelry trade thresholds: 0 below 3, 4 at 3, 7 at 4+")
    func jewelryThresholds() {
        let cat = ScoreCategory.jewelry
        #expect(cat.victoryPoints(for: 0) == 0)
        #expect(cat.victoryPoints(for: 2) == 0)
        #expect(cat.victoryPoints(for: 3) == 4)
        #expect(cat.victoryPoints(for: 4) == 7)
        #expect(cat.victoryPoints(for: 10) == 7)
    }

    @Test("Custom TradeVPConfig overrides default thresholds")
    func customConfigOverridesDefaults() {
        let custom = TradeVPConfig(midThreshold: 2, highThreshold: 4, midVP: 10, highVP: 20)
        let cat = ScoreCategory.cooking
        #expect(cat.victoryPoints(for: 1, config: custom) == 0)
        #expect(cat.victoryPoints(for: 2, config: custom) == 10)
        #expect(cat.victoryPoints(for: 3, config: custom) == 10)
        #expect(cat.victoryPoints(for: 4, config: custom) == 20)
    }

    @Test("Trade categories have non-nil threshold hint")
    func tradeThresholdHintExists() {
        for category in ScoreCategory.allCases where category.scoringType == .trade {
            #expect(category.tradeThresholdHint != nil)
        }
    }

    @Test("Direct categories have nil threshold hint")
    func directThresholdHintIsNil() {
        for category in ScoreCategory.allCases where category.scoringType == .direct {
            #expect(category.tradeThresholdHint == nil)
        }
    }

    @Test("All categories have a system image name")
    func allCategoriesHaveSystemImage() {
        for category in ScoreCategory.allCases {
            #expect(!category.systemImage.isEmpty)
        }
    }
}

// MARK: - Player Tests

@Suite("Player Tests")
struct PlayerTests {

    @Test("New player has zero scores for all categories")
    func newPlayerHasZeroScores() {
        let player = Player(name: "Alice")
        for category in ScoreCategory.allCases {
            #expect(player.rawInput(for: category) == 0)
        }
    }

    @Test("Player total with all zeros is zero")
    func totalWithZerosIsZero() {
        let player = Player(name: "Alice")
        #expect(player.total == 0)
    }

    @Test("Setting raw input updates the correct category")
    func setRawInputUpdatesCategory() {
        var player = Player(name: "Alice")
        player.setRawInput(12, for: .spaces)
        #expect(player.rawInput(for: .spaces) == 12)
        #expect(player.rawInput(for: .islands) == 0)
    }

    @Test("Player total sums direct and trade VP correctly")
    func totalSumsCorrectly() {
        var player = Player(name: "Alice")
        // Direct: spaces = 10, islands = 5, cardVP = 3, expansion = 2  => 20
        player.setRawInput(10, for: .spaces)
        player.setRawInput(5, for: .islands)
        player.setRawInput(3, for: .cardVP)
        player.setRawInput(2, for: .expansion)
        // Trade: cooking icons = 9 => 7 VP, jewelry icons = 4 => 7 VP => 14
        player.setRawInput(9, for: .cooking)
        player.setRawInput(4, for: .jewelry)
        // Total = 20 + 14 = 34
        #expect(player.total == 34)
    }

    @Test("Player victoryPoints uses category config when provided")
    func playerVPUsesConfig() {
        var player = Player(name: "Alice")
        player.setRawInput(2, for: .cooking)
        let custom = TradeVPConfig(midThreshold: 1, highThreshold: 3, midVP: 5, highVP: 15)
        #expect(player.victoryPoints(for: .cooking, config: custom) == 5)
    }
}

// MARK: - GameModel Tests

@Suite("GameModel Tests")
struct GameModelTests {

    /// Creates a GameModel with a unique save key so tests don't interfere.
    private func makeModel() -> GameModel {
        let key = "TestGameModel_\(UUID().uuidString)"
        return GameModel(saveKey: key)
    }

    @Test("Setup creates correct number of players with given names")
    func setupCreatesPlayers() {
        let model = makeModel()
        model.setupPlayers(count: 3, names: ["Alice", "Bob", "Charlie"])
        #expect(model.players.count == 3)
        #expect(model.players[0].name == "Alice")
        #expect(model.players[1].name == "Bob")
        #expect(model.players[2].name == "Charlie")
        #expect(model.isSetupComplete == true)
    }

    @Test("setPlayerCount increases players with default names")
    func setPlayerCountIncrease() {
        let model = makeModel()
        model.setupPlayers(count: 2, names: ["Alice", "Bob"])
        model.setPlayerCount(4)
        #expect(model.players.count == 4)
        #expect(model.players[2].name == "Player 3")
        #expect(model.players[3].name == "Player 4")
    }

    @Test("setPlayerCount decreases players by trimming from end")
    func setPlayerCountDecrease() {
        let model = makeModel()
        model.setupPlayers(count: 4, names: ["A", "B", "C", "D"])
        model.setPlayerCount(2)
        #expect(model.players.count == 2)
        #expect(model.players[0].name == "A")
        #expect(model.players[1].name == "B")
    }

    @Test("setPlayerCount clamps to 1-4 range")
    func setPlayerCountClamps() {
        let model = makeModel()
        model.setupPlayers(count: 2, names: ["A", "B"])
        model.setPlayerCount(0)
        #expect(model.players.count == 1)
        model.setPlayerCount(10)
        #expect(model.players.count == 4)
    }

    @Test("updateRawInput sets value for correct player and category")
    func updateRawInput() {
        let model = makeModel()
        model.setupPlayers(count: 2, names: ["Alice", "Bob"])
        model.updateRawInput(playerIndex: 1, category: .spaces, value: 15)
        #expect(model.players[1].rawInput(for: .spaces) == 15)
        #expect(model.players[0].rawInput(for: .spaces) == 0)
    }

    @Test("updateRawInput ignores out-of-bounds index")
    func updateRawInputOutOfBounds() {
        let model = makeModel()
        model.setupPlayers(count: 2, names: ["Alice", "Bob"])
        model.updateRawInput(playerIndex: 5, category: .spaces, value: 15)
        // No crash, scores unchanged
        #expect(model.players[0].rawInput(for: .spaces) == 0)
        #expect(model.players[1].rawInput(for: .spaces) == 0)
    }

    @Test("totalVP uses configured trade VP configs")
    func totalVPUsesConfig() {
        let model = makeModel()
        model.setupPlayers(count: 1, names: ["Alice"])
        model.updateRawInput(playerIndex: 0, category: .cooking, value: 2)
        // Default: 2 icons < 5 midThreshold => 0 VP
        #expect(model.totalVP(for: model.players[0]) == 0)
        // Override config so 2 icons qualifies for midVP
        let custom = TradeVPConfig(midThreshold: 1, highThreshold: 5, midVP: 10, highVP: 20)
        model.setTradeVPConfig(custom, for: .cooking)
        #expect(model.totalVP(for: model.players[0]) == 10)
    }

    @Test("resetGame preserves player count but zeroes scores")
    func resetGamePreservesCount() {
        let model = makeModel()
        model.setupPlayers(count: 3, names: ["Alice", "Bob", "Charlie"])
        model.updateRawInput(playerIndex: 0, category: .spaces, value: 20)
        model.resetGame()
        #expect(model.players.count == 3)
        #expect(model.players[0].rawInput(for: .spaces) == 0)
    }

    @Test("tradeVPConfig returns category default when not overridden")
    func tradeVPConfigDefault() {
        let model = makeModel()
        let config = model.tradeVPConfig(for: .smithing)
        #expect(config == ScoreCategory.smithing.defaultTradeVPConfig)
    }
}

// MARK: - TradeVPConfig Tests

@Suite("TradeVPConfig Tests")
struct TradeVPConfigTests {

    @Test("Default config has expected values")
    func defaultConfigValues() {
        let config = TradeVPConfig.defaultConfig
        #expect(config.midThreshold == 5)
        #expect(config.highThreshold == 9)
        #expect(config.midVP == 4)
        #expect(config.highVP == 7)
    }

    @Test("TradeVPConfig conforms to Equatable")
    func equatable() {
        let a = TradeVPConfig(midThreshold: 3, highThreshold: 5, midVP: 4, highVP: 7)
        let b = TradeVPConfig(midThreshold: 3, highThreshold: 5, midVP: 4, highVP: 7)
        let c = TradeVPConfig(midThreshold: 4, highThreshold: 6, midVP: 4, highVP: 7)
        #expect(a == b)
        #expect(a != c)
    }
}
