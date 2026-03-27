import SwiftUI

struct ContentView: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        ScoreboardView()
            .onAppear {
                if !game.isSetupComplete {
                    game.setupPlayers(
                        count: 2,
                        names: ["Player 1", "Player 2", "Player 3", "Player 4"]
                    )
                }
            }
    }
}
