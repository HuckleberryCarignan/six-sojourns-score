import SwiftUI

struct PlayerSetupView: View {
    @Environment(GameModel.self) private var game

    @State private var names: [String] = (1...4).map { "Player \($0)" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Names") {
                    ForEach(0..<4, id: \.self) { i in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            TextField("Player \(i + 1)", text: $names[i])
                                .autocorrectionDisabled()
                        }
                    }
                }

                Section {
                    Button("Start Game") {
                        game.setupPlayers(
                            count: 2,
                            names: names
                        )
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Six Sojourns")
        }
    }
}

#Preview {
    PlayerSetupView()
        .environment(GameModel())
}
