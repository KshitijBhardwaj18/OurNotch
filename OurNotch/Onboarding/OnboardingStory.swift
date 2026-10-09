import SwiftUI

/// The left half of onboarding: a slow carousel of what OurNotch does, starring Pip and Bun from the
/// website. Each slide is a little scene under a notch that hangs from the window's top edge (the window
/// has no visible title bar); it moves on by itself and the dots jump to one.
struct OnboardingStory: View {
    @State var index = 0

    var body: some View {
        let slide = Slide.allCases[index]
        VStack(spacing: 0) {
            TimelineView(.animation) { context in
                Scene(slide: slide, t: context.date.timeIntervalSinceReferenceDate)
            }
            .frame(height: 270)
            .id(slide)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            VStack(alignment: .leading, spacing: 8) {
                Text(slide.title)
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slide.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .id(slide)
            .transition(.opacity)

            Spacer(minLength: 0)
            HStack(spacing: 7) {
                ForEach(Slide.allCases.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Ink.main : Ink.main.opacity(0.18))
                        .frame(width: i == index ? 20 : 7, height: 7)
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.smooth) { index = i } }
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 22)
        }
        .foregroundStyle(Ink.main)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(slide.color.animation(.smooth(duration: 0.6)))
        .environment(\.colorScheme, .light) // a pastel picture-book page in light and dark mode
        // Each slide stays 5 s; picking one with the dots restarts the clock.
        .task(id: index) {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.6)) { index = (index + 1) % Slide.allCases.count }
        }
    }

    enum Slide: CaseIterable {
        case love, note, emoji, mood, together

        var title: LocalizedStringKey {
            switch self {
            case .love: "Send love, notch to notch."
            case .note: "Ten words or fewer."
            case .emoji: "One tap, many hearts."
            case .mood: "How you are, at a glance."
            case .together: "Just for the two of you."
            }
        }

        var body: LocalizedStringKey {
            switch self {
            case .love: "Your love lives at the top of your screen. Whatever you send appears in their notch."
            case .note: "A short note scrolls across their notch, until they open it."
            case .emoji: "Tap an emoji and it pours out of their notch."
            case .mood: "Pick a mood. It sits next to your face in their notch."
            case .together: "End-to-end encrypted, no account, and none of your iCloud storage. One purchase for both Macs."
            }
        }

        var color: Color {
            switch self {
            case .love: Color(hex: 0xFFD3DC)
            case .note: Color(hex: 0xFFE9A6)
            case .emoji: Color(hex: 0xCFE3FF)
            case .mood: Color(hex: 0xCFEFDF)
            case .together: Color(hex: 0xFFE4EC)
            }
        }
    }

    private enum Ink {
        static let main = Color(hex: 0x16141A)
        static let soft = Color(hex: 0x5E5A66)
    }
}

/// One slide's picture at time `t` (seconds): a notch at the top, Pip and Bun at the bottom.
private struct Scene: View {
    let slide: OnboardingStory.Slide
    let t: Double

    var body: some View {
        GeometryReader { box in
            let w = box.size.width, h = box.size.height
            ZStack {
                notch.position(x: w / 2, y: notchHeight / 2)
                switch slide {
                case .love: flyingHeart(from: CGPoint(x: w * 0.27, y: h - 80), to: CGPoint(x: w * 0.73, y: h - 80))
                case .emoji: pouringHearts(width: w)
                default: EmptyView()
                }
                buddy("pip", mood: slide == .mood ? "love" : (slide == .note ? "open" : "happy"), phase: 0)
                    .position(x: w * 0.27, y: h - 52)
                buddy("bun", mood: slide == .emoji || slide == .love ? "love" : "happy", phase: 1.3)
                    .position(x: w * 0.73, y: h - 52)
            }
        }
        .padding(.horizontal, 24)
    }

    private var notchHeight: CGFloat { slide == .note || slide == .mood ? 34 : 28 }

    private var notch: some View {
        let width: CGFloat = slide == .note || slide == .mood ? 230 : 150
        return UnevenRoundedRectangle(bottomLeadingRadius: 13, bottomTrailingRadius: 13)
            .fill(.black)
            .frame(width: width, height: notchHeight)
            .overlay {
                switch slide {
                case .note: ticker.frame(width: width - 28)
                case .mood:
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: 0xFF8FAB)).frame(width: 18, height: 18)
                            .overlay(Text(verbatim: "P").font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(.white))
                        Text(verbatim: "🥰").font(.system(size: 14))
                        Text("In love").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Color(hex: 0xFF375F))
                            .scaleEffect(1 + 0.15 * max(0, sin(t * 5)))
                    }
                    .padding(.horizontal, 12)
                default: EmptyView()
                }
            }
    }

    /// The note slides in from the right and scrolls across, over and over.
    private var ticker: some View {
        let speed = 38.0, span = 420.0
        let x = 200 - (t * speed).truncatingRemainder(dividingBy: span)
        return Text("lunch at 1? i'll bring dumplings 🥟")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .fixedSize()
            .offset(x: x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
    }

    /// A heart hops from Pip to Bun in an arc every 2.4 s.
    private func flyingHeart(from a: CGPoint, to b: CGPoint) -> some View {
        let p = (t / 2.4).truncatingRemainder(dividingBy: 1)
        let x = a.x + (b.x - a.x) * p, y = a.y + (b.y - a.y) * p - sin(p * .pi) * 70
        return Image(systemName: "heart.fill")
            .font(.system(size: 24))
            .foregroundStyle(Color(hex: 0xFF375F))
            .scaleEffect(0.6 + 0.5 * sin(p * .pi))
            .opacity(sin(p * .pi) * 1.4)
            .position(x: x, y: y)
    }

    /// Hearts in four pastel colours spill out of the notch and fall, fading.
    private func pouringHearts(width w: CGFloat) -> some View {
        let colors = [0xFF375F, 0xFF8FAB, 0xFFB800, 0x7FB2FF, 0x5CC98F].map { Color(hex: $0) }
        return ForEach(0..<9, id: \.self) { i in
            let p = ((t + Double(i) * 0.37) / 2.2).truncatingRemainder(dividingBy: 1)
            let drift = sin(Double(i) * 1.7) * 70 * p
            Image(systemName: "heart.fill")
                .font(.system(size: 12 + CGFloat(i % 3) * 5))
                .foregroundStyle(colors[i % colors.count])
                .rotationEffect(.degrees(sin(Double(i) + t * 2) * 18))
                .opacity(1 - p)
                .position(x: w / 2 + drift, y: 26 + p * 120)
        }
    }

    /// A character bobbing gently, like on the website.
    private func buddy(_ name: String, mood: String, phase: Double) -> some View {
        Image("\(name)-\(mood)")
            .resizable()
            .scaledToFit()
            .frame(width: 92)
            .offset(y: sin((t + phase) * 2.4) * 3)
    }
}
