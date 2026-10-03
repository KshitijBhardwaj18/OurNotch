import SwiftUI

/// What grows below the header when the notch opens: the current tab (or Settings) and the tab bar.
struct OpenNotchView: View {
    let state: AppState
    @Binding var tab: NotchTab
    @Binding var showsSettings: Bool
    @Binding var isEditing: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if showsSettings {
                    SettingsPanel()
                } else {
                    switch tab {
                    case .home: HomeTab(state: state)
                    case .note: NoteTab(state: state, isEditing: $isEditing)
                    case .emoji: EmojiTab(state: state)
                    case .photo: PhotoTab(state: state)
                    }
                }
            }
            .frame(width: Config.Notch.contentSize.width, height: Config.Notch.contentSize.height)

            Spacer(minLength: 0)
            // Picking a tab also leaves Settings.
            NotchTabBar(selection: Binding(get: { tab }, set: { tab = $0; showsSettings = false }),
                        dimmed: showsSettings)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}
