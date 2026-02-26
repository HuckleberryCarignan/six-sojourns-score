import SwiftUI

/// Root router — shows player setup until the game is configured,
/// then shows the live scoreboard.
struct ContentView: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        if game.isSetupComplete {
            ScoreboardView()
        } else {
            PlayerSetupView()
        }
    }
}
