import SwiftUI

@main
struct SixSojournsScoreApp: App {
    @State private var game = GameModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
        }
    }
}
