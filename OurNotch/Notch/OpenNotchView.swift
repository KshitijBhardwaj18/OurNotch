import SwiftUI

/// What grows below the header when the notch opens: the current tab (or Settings) and the tab bar.
struct OpenNotchView: View {
    let state: AppState
    @Binding var tab: NotchTab
    @Binding var showsSettings: Bool
    @Binding var isEditing: Bool
    /// Tabs shown since the notch opened. They stay built (hidden) so switching back costs nothing:
    /// building a tab took 30 to 40 ms, a few dropped frames on every switch.
    @State private var built: Set<NotchTab> = []

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(NotchTab.shown, id: \.self) { each in
                    if built.contains(each) || each == tab {
                        let shown = each == tab && !showsSettings
                        page(each)
                            .opacity(shown ? 1 : 0)
                            .allowsHitTesting(shown)
                            .accessibilityHidden(!shown)
                            .environment(\.isShownTab, shown)
                    }
                }
                if showsSettings { SettingsPanel(state: state) }
            }
            .frame(width: Config.Notch.contentSize.width, height: Config.Notch.contentSize.height)

            Spacer(minLength: 0)
            // Picking a tab also leaves Settings.
            NotchTabBar(selection: Binding(get: { tab }, set: { tab = $0; showsSettings = false }),
                        dimmed: showsSettings, badges: state.unseen)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
        .overlayPreferenceValue(HintKey.self) { HintLayer(hint: $0) } // on top of every card and the tab bar
        .onChange(of: showsSettings ? nil : tab, initial: true) { _, shown in state.show(tab: shown) }
        .onChange(of: tab, initial: true) { _, tab in built.insert(tab) }
        .onDisappear { state.show(tab: nil) }
    }

    @ViewBuilder private func page(_ tab: NotchTab) -> some View {
        switch tab {
        case .home: HomeTab(state: state) { self.tab = $0 }
        case .note: NoteTab(state: state, isEditing: $isEditing)
        case .emoji: EmojiTab(state: state)
        case .mood: MoodTab(state: state)
        case .photo: PhotoTab(state: state)
        case .stats: StatsTab(state: state)
        case .pet: PetTab(state: state, isEditing: $isEditing)
        }
    }
}

extension EnvironmentValues {
    /// False while a tab is kept built but hidden, so its once-a-second clock can rest.
    @Entry var isShownTab = true
}
