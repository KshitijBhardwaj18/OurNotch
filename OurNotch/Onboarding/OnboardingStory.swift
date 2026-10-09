import SwiftUI

/// The left half of onboarding: a slow carousel of what OurNotch does, starring Pip and Bun from the
/// website. Each slide is a little scene on a Mac screen card, the notch doing what the slide is about. It moves on every 8 s; a swipe picks a slide and restarts the clock.
/// The onboarding window owns `index` so the steps side can take on the slide's colour.
struct OnboardingStory: View {
    @Binding var index: Int

    @State private var forward = true

    var body: some View {
        ZStack {
            page(Slide.allCases[index])
                .id(index)
                .transition(.push(from: forward ? .trailing : .leading))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 20).onEnded { drag in
            if drag.translation.width < -30 { show(index + 1) } else if drag.translation.width > 30 { show(index - 1) }
        })
        .task(id: index) {
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            show(index + 1)
        }
    }

    /// One whole slide (colour, scene and words), so the carousel moves it as a single card.
    private func page(_ slide: Slide) -> some View {
        VStack(spacing: 0) {
            // A little Mac screen, below the window buttons, with the notch hanging from its top edge.
            TimelineView(.animation) { context in
                Scene(slide: slide, t: context.date.timeIntervalSinceReferenceDate)
            }
            .frame(height: 236)
            .background(.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1))
            .shadow(color: Color(hex: 0x5A1E32).opacity(0.12), radius: 14, y: 8)
            .padding(.horizontal, 22)
            .padding(.top, 46)
            .padding(.bottom, 22)
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
            Spacer(minLength: 0)
        }
        .foregroundStyle(Ink.main)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(slide.color)
    }

    private func show(_ i: Int) {
        let count = Slide.allCases.count
        forward = i >= index
        withAnimation(.smooth(duration: 0.9)) { index = (i + count) % count }
    }

    enum Slide: CaseIterable {
        case love, whispers, emoji, mood, seconds, together

        var title: LocalizedStringKey {
            switch self {
            case .love: "Send love, notch to notch."
            case .whispers: "Whispers, just between you."
            case .emoji: "One tap, many hearts."
            case .mood: "How you are, at a glance."
            case .seconds: "Every second, counted."
            case .together: "Just for the two of you."
            }
        }

        var body: LocalizedStringKey {
            switch self {
            case .love: "Your love lives at the top of your screen. Whatever you send appears in their notch."
            case .whispers: "Sweet little notes scroll across their notch, and your last few stay as a tiny conversation."
            case .emoji: "Tap a heart or a kiss, and it pours out of their notch."
            case .mood: "Pick a mood. It shows in their notch all day, right beside your face."
            case .seconds: "Your time together, ticking up in pink. Plus days, weekends and the countdown to your anniversary."
            case .together: "End-to-end encrypted, no account, no sign-up. One purchase for both Macs."
            }
        }

        var color: Color {
            switch self {
            case .love: Color(hex: 0xFFD3DC)
            case .whispers: Color(hex: 0xFFE9A6)
            case .emoji: Color(hex: 0xCFE3FF)
            case .mood: Color(hex: 0xCFEFDF)
            case .seconds: Color(hex: 0xFFDCC8)
            case .together: Color(hex: 0xFFE4EC)
            }
        }
    }

    private enum Ink {
        static let main = Color(hex: 0x16141A)
        static let soft = Color(hex: 0x5E5A66)
    }
}

/// One slide's picture at time `t` (seconds): the notch at the top doing what the slide is about, Pip and
/// Bun at the bottom. Each scene loops on its own clock.
private struct Scene: View {
    let slide: OnboardingStory.Slide
    let t: Double

    private static let pink = Color(hex: 0xFF375F)

    var body: some View {
        GeometryReader { box in
            let w = box.size.width, h = box.size.height
            let pip = CGPoint(x: w * 0.27, y: h - 54), bun = CGPoint(x: w * 0.73, y: h - 54)
            ZStack {
                switch slide {
                case .love: love(width: w, pip: pip, bun: bun)
                case .whispers: whispers(width: w)
                case .emoji: pouring(width: w); closedNotch().position(x: w / 2, y: 14)
                case .mood: closedNotch { mood }.position(x: w / 2, y: 14)
                case .seconds: notch(width: 230, height: 62) { counter }.position(x: w / 2, y: 31)
                case .together: closedNotch { locked }.position(x: w / 2, y: 14)
                }
                buddy("pip", mood: slide == .mood || slide == .seconds ? "love" : "happy", phase: 0).position(pip)
                buddy("bun", mood: slide == .whispers || slide == .together ? "happy" : "love", phase: 1.3).position(bun)
            }
        }
        .padding(.horizontal, 12)
    }

    /// The black notch hanging from the screen's top edge, with something inside.
    private func notch(width: CGFloat, height: CGFloat, @ViewBuilder _ content: () -> some View) -> some View {
        UnevenRoundedRectangle(bottomLeadingRadius: height > 40 ? 18 : 13, bottomTrailingRadius: height > 40 ? 18 : 13)
            .fill(.black)
            .frame(width: width, height: height)
            .overlay(alignment: .top) { content() }
    }

    /// The closed notch as it really looks: your love's avatar on the left, and on the right the beating
    /// heart (or whatever the slide puts there).
    private func closedNotch(width: CGFloat = 206, banner: Bool = false,
                             @ViewBuilder right: () -> some View = { heart }) -> some View {
        notch(width: width, height: banner ? 50 : 28) {
            HStack(spacing: 0) {
                Circle().fill(Color(hex: 0xFF8FAB)).frame(width: 17, height: 17)
                    .overlay(Text(verbatim: "p").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(.white))
                Spacer()
                right()
            }
            .padding(.horizontal, 11)
            .frame(height: 28)
        }
    }

    private static var heart: some View {
        TimelineView(.animation) { context in
            Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(pink)
                .scaleEffect(1 + 0.18 * max(0, sin(context.date.timeIntervalSinceReferenceDate * 4.8)))
        }
    }

    // MARK: Love: a heart goes up into Pip's side of the notch, and pours out onto Bun.

    @ViewBuilder private func love(width w: CGFloat, pip: CGPoint, bun: CGPoint) -> some View {
        let p = (t / 3.4).truncatingRemainder(dividingBy: 1)
        closedNotch().position(x: w / 2, y: 14)

        // Up from Pip into the notch.
        let up = min(1, p / 0.34)
        Image(systemName: "heart.fill")
            .font(.system(size: 22))
            .foregroundStyle(Self.pink)
            .scaleEffect(1 - 0.5 * up)
            .opacity(p < 0.34 ? 1 : 0)
            .position(x: pip.x + (w / 2 - pip.x) * up, y: pip.y - 40 - (pip.y - 40 - 16) * up + sin(up * .pi) * -20)

        // Out of the notch, down onto Bun.
        ForEach(0..<5, id: \.self) { i in
            let q = max(0, (p - 0.42 - Double(i) * 0.06) / 0.4)
            Image(systemName: "heart.fill")
                .font(.system(size: 11 + CGFloat(i % 3) * 5))
                .foregroundStyle(i % 2 == 0 ? Self.pink : Color(hex: 0xFF8FAB))
                .rotationEffect(.degrees(Double(i - 2) * 12))
                .opacity(q > 0 && q < 1 ? 1 - q * 0.5 : 0)
                .position(x: w / 2 + (bun.x - w / 2) * q.squareRoot() + CGFloat(i - 2) * 9, y: 30 + (bun.y - 70) * q * q)
        }
    }

    // MARK: Whispers: one arrives scrolling under the notch, then the notch opens on your little conversation.

    @ViewBuilder private func whispers(width w: CGFloat) -> some View {
        let p = (t / 7.6).truncatingRemainder(dividingBy: 1)
        let open = smooth(p, 0.55, 0.62)
        ZStack(alignment: .top) {
            closedNotch(banner: true) { Self.heart }
                .overlay(alignment: .bottom) { banner.frame(width: 180).padding(.bottom, 5) }
                .opacity(1 - open)
            notch(width: 236, height: 104) { conversation }
                .opacity(open)
        }
        .position(x: w / 2, y: 52)
    }

    /// The whisper scrolling under the closed notch, the sender's name in pink, like the real banner.
    private var banner: some View {
        let x = 190 - (t * 34).truncatingRemainder(dividingBy: 400)
        return (Text(verbatim: "pip").foregroundColor(Self.pink) + Text(verbatim: "  ") + Text("lunch at 1? i'll bring dumplings 🥟").foregroundColor(.white))
            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            .fixedSize()
            .offset(x: x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 14)
            .clipped()
    }

    /// The open notch's conversation, the bubbles popping in one by one.
    private var conversation: some View {
        let step = ((t / 7.6).truncatingRemainder(dividingBy: 1) - 0.6) / 0.1 // after the notch opens, one bubble per step
        let lines: [(LocalizedStringKey, Bool)] = [("lunch at 1? 🥟", false), ("yes please!! ❤️", true), ("see you soon 😘", false)]
        return VStack(spacing: 5) {
            ForEach(lines.indices, id: \.self) { i in
                let shown = step >= Double(i + 1)
                HStack {
                    if lines[i].1 { Spacer(minLength: 0) }
                    Text(lines[i].0)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(lines[i].1 ? Self.pink : Color(hex: 0x2C2C2E), in: Capsule())
                    if !lines[i].1 { Spacer(minLength: 0) }
                }
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown ? 1 : 0.8, anchor: lines[i].1 ? .trailing : .leading)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: shown)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Emoji: hearts and kisses pour out of the notch.

    private func pouring(width w: CGFloat) -> some View {
        let glyphs = ["❤️", "💋", "🥰", "❤️", "💋", "😘", "❤️", "🥰", "💋"]
        return ForEach(glyphs.indices, id: \.self) { i in
            let p = ((t + Double(i) * 0.37) / 2.2).truncatingRemainder(dividingBy: 1)
            let drift = sin(Double(i) * 1.7) * 70 * p
            Text(verbatim: glyphs[i])
                .font(.system(size: 13 + CGFloat(i % 3) * 5))
                .rotationEffect(.degrees(sin(Double(i) + t * 2) * 18))
                .opacity(1 - p)
                .position(x: w / 2 + drift, y: 26 + p * 120)
        }
    }

    // MARK: Mood: the closed notch as in the app, the avatar on the left, the mood on the right.

    private var mood: some View {
        let moods = ["🥺", "🍕", "😴"]
        let current = moods[Int(t / 1.8) % moods.count]
        return HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(verbatim: current).font(.system(size: 13))
                Text((Config.moodLabel(current) ?? "").lowercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .id(current)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: current)
    }

    // MARK: Seconds: the counter ticking up in pink.

    private var counter: some View {
        VStack(spacing: 1) {
            Text((115_235_000 + Int(t) % 100_000).formatted())
                .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Self.pink)
                .contentTransition(.numericText())
            HStack(spacing: 3) {
                Text("seconds of us, and counting")
                Image(systemName: "heart.fill").font(.system(size: 7)).foregroundStyle(Self.pink)
                    .scaleEffect(1 + 0.2 * max(0, sin(t * 5)))
            }
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 6)
    }

    // MARK: Together: locked, just you two.

    private var locked: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 9.5)).foregroundStyle(.white.opacity(0.85))
            Text("just you two").font(.system(size: 10.5, weight: .semibold, design: .rounded)).foregroundStyle(.white)
        }
    }

    /// 0 before `a`, 1 after `b`, eased in between.
    private func smooth(_ p: Double, _ a: Double, _ b: Double) -> Double {
        let x = min(1, max(0, (p - a) / (b - a)))
        return x * x * (3 - 2 * x)
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
