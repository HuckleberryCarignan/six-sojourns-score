import SwiftUI

// MARK: - Scoreboard

struct ScoreboardView: View {
    @Environment(GameModel.self) private var game
    @State private var showResetAlert = false
    @State private var showSettings = false
    @State private var pendingSettingsPage: SettingsSubPage?
    @State private var showAbout = false
    @State private var showAppSettings = false
    @State private var showLegal = false
    /// Tracks which cell is being edited: (playerIndex, category)
    @State private var editingCell: EditingCell?
    @State private var playerCount: Double = 2

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PlayerCountSlider(playerCount: $playerCount)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(ScoreCategory.allCases.filter { $0.scoringType == .direct }) { category in
                        CategoryRow(
                            category: category,
                            editingCell: $editingCell
                        )
                    }
                } header: {
                    PlayerNamesHeader()
                }

                Section {
                    ForEach(ScoreCategory.allCases.filter { $0.scoringType == .trade }) { category in
                        CategoryRow(
                            category: category,
                            editingCell: $editingCell
                        )
                    }
                } header: {
                    Text("Trade Goods")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .padding(.top, -16)
                }
            }
            .listStyle(.plain)
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListRowHeight, 28)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                editingCell = nil
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
            // Total VP bar pinned to the bottom of the screen
            .safeAreaInset(edge: .bottom) {
                TotalsFooter()
            }
            .background {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.12)
            }
            .navigationTitle("Six Sojourns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showResetAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                switch pendingSettingsPage {
                case .about: showAbout = true
                case .appSettings: showAppSettings = true
                case .legal: showLegal = true
                case nil: break
                }
                pendingSettingsPage = nil
            }) {
                SettingsView(
                    onSelectAbout: { pendingSettingsPage = .about; showSettings = false },
                    onSelectAppSettings: { pendingSettingsPage = .appSettings; showSettings = false },
                    onSelectLegal: { pendingSettingsPage = .legal; showSettings = false }
                )
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    SettingsAboutView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showAbout = false }
                                    .bold()
                            }
                        }
                }
            }
            .sheet(isPresented: $showAppSettings) {
                NavigationStack {
                    SettingsAppView()
                        .environment(game)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showAppSettings = false }
                                    .bold()
                            }
                        }
                }
            }
            .sheet(isPresented: $showLegal) {
                NavigationStack {
                    SettingsLegalView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showLegal = false }
                                    .bold()
                            }
                        }
                }
            }
            .onAppear {
                playerCount = Double(game.players.count)
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

// MARK: - Player count slider

private struct PlayerCountSlider: View {
    @Binding var playerCount: Double
    @Environment(GameModel.self) private var game

    private let range = 1...4

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text("Players")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(playerCount))")
                    .font(.caption.bold())
                    .monospacedDigit()
            }
            TappableSliderTrack(
                value: $playerCount,
                range: range,
                onChange: { newValue in
                    game.setPlayerCount(newValue)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, UIScreen.main.bounds.width / 3)
        .padding(.vertical, -4)
    }
}

// MARK: - Tappable slider track

/// A custom slider track that supports tapping (increment/decrement by 1) and dragging.
private struct TappableSliderTrack: View {
    @Binding var value: Double
    let range: ClosedRange<Int>
    var onChange: (Int) -> Void

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 26

    private var stepCount: Int { range.upperBound - range.lowerBound }

    /// Whether the current gesture has moved enough to count as a drag.
    @State private var isDragging = false
    @State private var dragStartLocation: CGFloat = 0

    private func fraction(for val: Double) -> CGFloat {
        CGFloat(val - Double(range.lowerBound)) / CGFloat(stepCount)
    }

    private func snappedValue(for fraction: CGFloat) -> Int {
        let clamped = min(max(fraction, 0), 1)
        return range.lowerBound + Int((clamped * CGFloat(stepCount)).rounded())
    }

    private func apply(_ newVal: Int) {
        guard newVal != Int(value) else { return }
        value = Double(newVal)
        onChange(newVal)
    }

    @State private var trackWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let currentThumbX = fraction(for: value) * trackWidth

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: trackHeight)

                // Filled track
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, currentThumbX), height: trackHeight)

                // Step dots
                HStack {
                    ForEach(0...stepCount, id: \.self) { step in
                        Circle()
                            .fill(Color(.systemGray3))
                            .frame(width: 5, height: 5)
                        if step < stepCount {
                            Spacer()
                        }
                    }
                }

                // Thumb
                Circle()
                    .fill(.black)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: currentThumbX - thumbSize / 2)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .onAppear { trackWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, w in trackWidth = w }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            let distance = abs(drag.location.x - drag.startLocation.x)
                            if distance > 10 {
                                isDragging = true
                            }
                        }
                        if isDragging {
                            let frac = drag.location.x / trackWidth
                            apply(snappedValue(for: frac))
                        }
                    }
                    .onEnded { drag in
                        if !isDragging {
                            // Tap — increment or decrement by 1
                            let tapX = drag.location.x
                            let currentThumb = fraction(for: value) * trackWidth
                            if tapX > currentThumb {
                                apply(min(Int(value) + 1, range.upperBound))
                            } else {
                                apply(max(Int(value) - 1, range.lowerBound))
                            }
                        }
                        isDragging = false
                    }
            )
        }
        .frame(height: thumbSize)
    }
}

/// Identifies a cell being edited in the grid.
private struct EditingCell: Equatable {
    let playerIndex: Int
    let category: ScoreCategory
}

// MARK: - Header row (player names)

private struct PlayerNamesHeader: View {
    @Environment(GameModel.self) private var game
    @State private var editingIndex: Int?

    var body: some View {
        HStack(spacing: 0) {
            Text("Category")
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
                if editingIndex == index {
                    SelectAllTextField(
                        text: Binding(
                            get: { game.players[index].name },
                            set: { game.players[index].name = $0 }
                        ),
                        onCommit: { editingIndex = nil }
                    )
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: scoreColumnWidth)
                    .autocorrectionDisabled()
                } else {
                    Text(player.name)
                        .frame(width: scoreColumnWidth, alignment: .center)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .onTapGesture {
                            editingIndex = index
                        }
                }
            }
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(.primary)
        .textCase(nil)
        .padding(.vertical, 0)
    }
}

// MARK: - Category row

private struct CategoryRow: View {
    let category: ScoreCategory
    @Binding var editingCell: EditingCell?
    @Environment(GameModel.self) private var game

    var body: some View {
        HStack(spacing: 0) {
            // Category label: icon only for trade categories, icon + text for others
            HStack(spacing: 6) {
                if let imageName = category.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .padding(.leading, 16)
                } else {
                    Image(systemName: category.systemImage)
                        .frame(width: 24, height: 24)
                }

                if category.scoringType == .direct {
                    Text(category.rawValue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
                let isEditing = editingCell == EditingCell(playerIndex: index, category: category)
                let cellHeight: CGFloat = category.scoringType == .trade ? 28 : 24

                if isEditing {
                    InlineScoreField(
                        category: category,
                        playerIndex: index,
                        editingCell: $editingCell
                    )
                    .frame(width: scoreColumnWidth, height: cellHeight, alignment: .center)
                } else {
                    let vp = player.victoryPoints(for: category, config: game.tradeVPConfig(for: category))
                    let raw = player.rawInput(for: category)

                    VStack(spacing: 1) {
                        Text(vp == 0 ? "–" : "\(vp)")
                            .foregroundStyle(vp == 0 ? .secondary : .primary)

                        if category.scoringType == .trade && raw > 0 {
                            Text("(\(raw))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(width: scoreColumnWidth, height: cellHeight, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingCell = EditingCell(playerIndex: index, category: category)
                    }
                }
            }
        }
        .font(.title3)
        .padding(.vertical, category.scoringType == .trade ? -8 : -6)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Inline score field

private struct InlineScoreField: View {
    let category: ScoreCategory
    let playerIndex: Int
    @Binding var editingCell: EditingCell?
    @Environment(GameModel.self) private var game
    @State private var text: String = "0"
    @FocusState private var isFocused: Bool

    private var numericValue: Int {
        Int(text) ?? 0
    }

    private var calculatedVP: Int {
        category.victoryPoints(for: numericValue, config: game.tradeVPConfig(for: category))
    }

    var body: some View {
        VStack(spacing: 2) {
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    // Strip non-digit characters
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        text = filtered
                    }
                    let intValue = Int(filtered) ?? 0
                    game.updateRawInput(playerIndex: playerIndex, category: category, value: intValue)
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        editingCell = nil
                    }
                }

            if category.scoringType == .trade {
                Text("\(calculatedVP) VP")
                    .font(.caption2.bold())
                    .foregroundStyle(calculatedVP > 0 ? .green : .secondary)
            }
        }
        .onAppear {
            let current = game.players[playerIndex].rawInput(for: category)
            text = current == 0 ? "" : "\(current)"
            isFocused = true
        }
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
                Text("\(game.totalVP(for: player))")
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

// MARK: - Select-all text field

/// A TextField that automatically selects all text when it becomes first responder.
private struct SelectAllTextField: UIViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.textAlignment = .center
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.borderStyle = .none
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async {
                uiView.selectAll(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onCommit: () -> Void

        init(text: Binding<String>, onCommit: @escaping () -> Void) {
            _text = text
            self.onCommit = onCommit
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            onCommit()
            return true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            onCommit()
        }
    }
}

// MARK: - Settings

private enum SettingsSubPage {
    case about, appSettings, legal
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelectAbout: () -> Void
    var onSelectAppSettings: () -> Void
    var onSelectLegal: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onSelectAbout()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    Button {
                        onSelectAppSettings()
                    } label: {
                        Label("App Settings", systemImage: "slider.horizontal.3")
                    }
                    Button {
                        onSelectLegal()
                    } label: {
                        Label("Legal", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - About

private struct SettingsAboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image("background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Text("Six Sojourns Score")
                        .font(.title2.bold())
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                Text("A scoring companion app for the Six Sojourns board game greate and published by [Huckleberry Carignan](https://www.linkedin.com/in/huckleberry-carignan-0b407321/). Track victory points for all players across map scoring, trade goods, card objectives, and expansion bonuses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .tint(.blue)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - App Settings (Trade VP chart)

private struct SettingsAppView: View {
    @Environment(GameModel.self) private var game

    private var tradeCategories: [ScoreCategory] {
        ScoreCategory.allCases.filter { $0.scoringType == .trade }
    }

    private func thresholdLabel(for category: ScoreCategory) -> (mid: String, high: String) {
        let cfg = game.tradeVPConfig(for: category)
        let midEnd = cfg.highThreshold - 1
        let midLabel = cfg.midThreshold == midEnd
            ? "\(cfg.midThreshold) icons"
            : "\(cfg.midThreshold)–\(midEnd) icons"
        let highLabel = "\(cfg.highThreshold)+ icons"
        return (midLabel, highLabel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section title
            Text("Trade Goods VP Values")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Chart header
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 44)
                Text("Mid VP")
                    .frame(maxWidth: .infinity)
                Text("High VP")
                    .frame(maxWidth: .infinity)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            Divider()
                .padding(.horizontal, 20)

            // Chart rows
            ForEach(tradeCategories) { category in
                let labels = thresholdLabel(for: category)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        if let imageName = category.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                .frame(width: 44)
                        }

                        VStack(spacing: 2) {
                            Text(labels.mid)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                TextField("4", value: Binding(
                                    get: { game.tradeVPConfig(for: category).midVP },
                                    set: {
                                        var config = game.tradeVPConfig(for: category)
                                        config.midVP = $0
                                        game.setTradeVPConfig(config, for: category)
                                    }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                Text("VP")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 2) {
                            Text(labels.high)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                TextField("7", value: Binding(
                                    get: { game.tradeVPConfig(for: category).highVP },
                                    set: {
                                        var config = game.tradeVPConfig(for: category)
                                        config.highVP = $0
                                        game.setTradeVPConfig(config, for: category)
                                    }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                Text("VP")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Legal

private struct SettingsLegalView: View {
    var body: some View {
        List {
            Section {
                Text("Six Sojourns and all related imagery are trademarks and copyrights of [Red Raven Games](https://www.redravengames.com). This is an unofficial fan-made tool and is not produced by, affiliated with, or supported by [Red Raven Games](https://www.redravengames.com).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .tint(.blue)
            }

            Section("Privacy") {
                Text("This app does not collect, store, or transmit any personal data. All game data is stored locally on your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
