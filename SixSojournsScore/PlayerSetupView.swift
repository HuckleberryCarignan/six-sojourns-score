import SwiftUI

struct PlayerSetupView: View {
    @Environment(GameModel.self) private var game

    @State private var count: Int = 2
    @State private var names: [String] = (1...4).map { "Player \($0)" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Number of Players") {
                    Picker("Players", selection: $count) {
                        ForEach(1...4, id: \.self) { n in
                            Text(n == 1 ? "1 Player" : "\(n) Players").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Player Names") {
                    ForEach(0..<count, id: \.self) { i in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.accent)
                            TextField("Player \(i + 1)", text: $names[i])
                                .autocorrectionDisabled()
                        }
                    }
                }

                Section {
                    Button("Start Game") {
                        game.setupPlayers(
                            count: count,
                            names: Array(names.prefix(count))
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
