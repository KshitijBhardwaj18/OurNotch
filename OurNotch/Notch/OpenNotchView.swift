import SwiftUI

/// What grows below the header when the notch opens: the current tab (488 × 184) and the tab bar.
struct OpenNotchView: View {
    let state: AppState
    @Binding var tab: NotchTab
    @Binding var isEditing: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .home: HomeTab(state: state)
                case .note: NoteTab(state: state, isEditing: $isEditing)
                case .emoji: EmojiTab(state: state)
                case .photo: PhotoTab(state: state)
                }
            }
            .frame(width: 488, height: 184)

            Spacer(minLength: 0)
            NotchTabBar(selection: $tab)
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}
