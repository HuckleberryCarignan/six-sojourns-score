import SwiftUI

// MARK: - Scoreboard

struct ScoreboardView: View {
    @Environment(GameModel.self) private var game
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ScoreCategory.allCases) { category in
                        NavigationLink(value: category) {
                            CategoryRow(category: category)
                        }
                    }
                } header: {
                    PlayerNamesHeader()
                }
            }
            .listStyle(.plain)
            // Total VP bar pinned to the bottom of the screen
            .safeAreaInset(edge: .bottom) {
                TotalsFooter()
            }
            .navigationTitle("Six Sojourns")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ScoreCategory.self) { category in
                CategoryEntryView(category: category)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showResetAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
            .alert("Reset Game?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) { game.resetGame() }
            } message: {
                Text("All scores will be cleared and you will return to player setup.")
            }
        }
    }
}

// MARK: - Header row (player names)

private struct PlayerNamesHeader: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        HStack(spacing: 0) {
            Text("Category")
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(game.players) { player in
                Text(player.name)
                    .frame(width: scoreColumnWidth, alignment: .center)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.primary)
        .textCase(nil)
        .padding(.vertical, 4)
    }
}

// MARK: - Category row

private struct CategoryRow: View {
    let category: ScoreCategory
    @Environment(GameModel.self) private var game

    var body: some View {
        HStack(spacing: 0) {
            // Category label with an optional "icons" badge for trade rows
            HStack(spacing: 6) {
                Label(category.rawValue, systemImage: category.systemImage)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if category.scoringType == .trade {
                    Text("icons")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(game.players) { player in
                let vp = player.victoryPoints(for: category)
                let raw = player.rawInput(for: category)

                VStack(spacing: 1) {
                    // Show the VP value
                    Text(vp == 0 ? "–" : "\(vp)")
                        .foregroundStyle(vp == 0 ? .secondary : .primary)

                    // For trades: also show the raw icon count beneath the VP
                    if category.scoringType == .trade && raw > 0 {
                        Text("(\(raw))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: scoreColumnWidth, alignment: .center)
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Totals footer

private struct TotalsFooter: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        HStack(spacing: 0) {
            Text("Total VP")
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(game.players) { player in
                Text("\(player.total)")
                    .frame(width: scoreColumnWidth, alignment: .center)
                    .fontWeight(.bold)
            }
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Layout constant

/// Width of each player score column. Fits 4 players on an iPhone.
private let scoreColumnWidth: CGFloat = 64

// MARK: - Preview

#Preview {
    let g = GameModel()
    g.setupPlayers(count: 3, names: ["Alice", "Bob", "Carol"])
    g.updateRawInput(playerIndex: 0, category: .cooking, value: 5)
    g.updateRawInput(playerIndex: 1, category: .cooking, value: 9)
    g.updateRawInput(playerIndex: 0, category: .spaces, value: 8)
    return ScoreboardView()
        .environment(g)
}
