import SwiftUI

// MARK: - Category Entry

/// Score entry screen for one category across all players.
/// For trade categories, the user enters icon counts and sees the calculated VP.
/// Scores are written back to the model on disappear (navigation pop).
struct CategoryEntryView: View {
    let category: ScoreCategory
    @Environment(GameModel.self) private var game

    @State private var values: [Int] = []

    var body: some View {
        Form {
            Section {
                ForEach(game.players.indices, id: \.self) { i in
                    PlayerScoreRow(
                        playerName: game.players[i].name,
                        category: category,
                        value: Binding(
                            get: { i < values.count ? values[i] : 0 },
                            set: { if i < values.count { values[i] = $0 } }
                        )
                    )
                }
            } header: {
                Label(category.rawValue, systemImage: category.systemImage)
                    .font(.subheadline.bold())
                    .textCase(nil)
            } footer: {
                if let hint = category.tradeThresholdHint {
                    // Trade scoring formula
                    Text(hint)
                        .font(.caption)
                } else {
                    // Direct VP entry hint
                    entryHint
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            values = game.players.map { $0.rawInput(for: category) }
        }
        .onDisappear {
            for (i, val) in values.enumerated() {
                game.updateRawInput(playerIndex: i, category: category, value: val)
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var entryHint: some View {
        switch category {
        case .spaces:
            Text("1 VP per controlled space (house = 2, ties = 0).")
                .font(.caption)
        case .islands:
            Text("1 VP if you control more spaces on an island than any other player.")
                .font(.caption)
        case .cardVP:
            Text("Sum of all card objective VPs you earned this game.")
                .font(.caption)
        case .expansion:
            Text("Sea Serpents, Feuds, Mountains, Shrines, Values, or other expansion VPs.")
                .font(.caption)
        default:
            EmptyView()
        }
    }
}

// MARK: - Player Score Row

private struct PlayerScoreRow: View {
    let playerName: String
    let category: ScoreCategory
    @Binding var value: Int

    private var calculatedVP: Int {
        category.victoryPoints(for: value)
    }

    var body: some View {
        HStack {
            Label(playerName, systemImage: "person.circle.fill")
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 6) {
                Button {
                    value = max(0, value - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.85))
                }
                .buttonStyle(.plain)

                // Input field + optional VP badge for trade categories
                VStack(spacing: 2) {
                    TextField("0", value: $value, format: .number)
                        .keyboardType(.numberPad)
                        .frame(width: 52)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)

                    if category.scoringType == .trade {
                        Text("\(calculatedVP) VP")
                            .font(.caption2.bold())
                            .foregroundStyle(calculatedVP > 0 ? .green : .secondary)
                            .animation(.easeInOut(duration: 0.15), value: calculatedVP)
                    }
                }

                Button {
                    value += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, category.scoringType == .trade ? 4 : 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let g = GameModel()
        g.setupPlayers(count: 3, names: ["Alice", "Bob", "Carol"])
        return CategoryEntryView(category: .cooking)
            .environment(g)
    }
}
