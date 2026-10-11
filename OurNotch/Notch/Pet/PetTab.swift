import SwiftUI

/// The pet you share: its little playground on the left, how it's doing and what you can do on the right.
/// Before either of you adopts, the same space invites you to.
struct PetTab: View {
    let state: AppState
    @Binding var isEditing: Bool
    @Environment(\.isShownTab) private var isShown

    var body: some View {
        if let pet = state.pet {
            PetHome(state: state, pet: pet, isShown: isShown)
        } else {
            Adoption(state: state, isEditing: $isEditing, isShown: isShown)
        }
    }
}

// MARK: Living with it

private struct PetHome: View {
    let state: AppState
    let pet: Pet
    let isShown: Bool
    /// What just happened, for the little animations: a snack, hearts, a ball, a trick.
    @State private var reaction: (care: PetCare, at: Date)?
    @State private var tricks = 0
    @State private var customizing = false

    var body: some View {
        let side = Config.Notch.contentSize.height
        HStack(spacing: 10) {
            TimelineView(.animation(paused: !isShown)) { context in
                Playground(pet: pet, now: context.date, reaction: reaction, trick: tricks)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                header
                if customizing { LookPicker(state: state, pet: pet) } else { needs }
                Spacer(minLength: 6)
                if !customizing { actions }
            }
            .cardStyle()
        }
        // The partner's care plays here too.
        .onChange(of: pet.care.last?.action) { old, new in
            guard let new, old != nil, new.at > Date.now.addingTimeInterval(-30) else { return }
            react(new.care)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: pet.adoption.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(stageLine).font(.system(size: 11.5, weight: .medium)).foregroundStyle(Color.secondaryLabel)
            }
            Spacer()
            Button { withAnimation(.snappy(duration: 0.2)) { customizing.toggle() } } label: {
                Image(systemName: customizing ? "checkmark" : "paintbrush.pointed.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(customizing ? Color.white : .notchBlush)
                    .frame(width: 28, height: 28)
                    .background(customizing ? Color.notchPink : .notchField, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(customizing ? Text("Done") : Text("Dress up"))
        }
    }

    private var needs: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(feelingLine).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                .padding(.top, 8)
            Meter(label: String(localized: "Food"), symbol: "fork.knife", value: pet.fullness())
            Meter(label: String(localized: "Love"), symbol: "heart.fill", value: pet.love())
            if let last = pet.care.last {
                Text(careLine(last))
                    .font(.system(size: 11)).foregroundStyle(Color.tertiaryLabel).lineLimit(1)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 6) {
            CareButton(emoji: pet.adoption.kind == .cat ? "🐟" : "🦴", label: String(localized: "Feed")) { act(.feed) }
            CareButton(emoji: "🤍", label: String(localized: "Pet")) { act(.pet) }
            CareButton(emoji: pet.adoption.kind == .cat ? "🧶" : "🎾", label: String(localized: "Play")) { act(.play) }
            CareButton(emoji: "✨", label: String(localized: "Trick")) { act(.trick) }
        }
        .disabled(pet.feeling() == .sleeping)
        .opacity(pet.feeling() == .sleeping ? 0.5 : 1)
    }

    private func act(_ care: PetCare) {
        state.care(care)
        react(care)
    }

    private func react(_ care: PetCare) {
        if care == .trick { tricks += 1 }
        reaction = (care, .now)
    }

    // MARK: Words

    private var stageLine: String {
        let days = pet.ageInDays()
        let kind = pet.adoption.kind
        let stage: String = switch pet.stage() {
        case .baby: kind == .cat ? String(localized: "kitten") : String(localized: "puppy")
        case .young: String(localized: "little one")
        case .grown: String(localized: "all grown up")
        case .wise: String(localized: "wise old friend")
        }
        return days == 0 ? String(localized: "\(stage) · new today") : String(localized: "\(stage) · \(days) days with you")
    }

    private var feelingLine: String {
        let name = pet.adoption.name
        return switch pet.feeling() {
        case .sick: String(localized: "\(name) is poorly ♡ a meal will help")
        case .recovering: String(localized: "\(name) is getting better")
        case .sleeping: String(localized: "\(name) is fast asleep, shh")
        case .hungry: String(localized: "\(name) is hungry")
        case .lonely: String(localized: "\(name) misses you both")
        case .content: String(localized: "\(name) is doing fine")
        case .happy: String(localized: "\(name) is so happy")
        }
    }

    private func careLine(_ last: (action: PetAction, mine: Bool)) -> String {
        let who = last.mine ? String(localized: "you") : state.partnerName.lowercased()
        let ago = Date.now.timeIntervalSince(last.action.at) < 60 ? String(localized: "just now") : shortAgo(last.action.at)
        return switch last.action.care {
        case .feed: String(localized: "\(who) fed \(pet.adoption.name) \(ago)")
        case .pet: String(localized: "\(who) cuddled \(pet.adoption.name) \(ago)")
        case .play: String(localized: "\(who) played with \(pet.adoption.name) \(ago)")
        case .trick: String(localized: "\(who) taught \(pet.adoption.name) a trick \(ago)")
        }
    }
}

/// The pet's little world: sky by day, stars by night, grass, a bowl, a ball and a bed.
private struct Playground: View {
    let pet: Pet
    let now: Date
    let reaction: (care: PetCare, at: Date)?
    let trick: Int

    var body: some View {
        let feeling = pet.feeling(now: now)
        let night = feeling == .sleeping
        let t = now.timeIntervalSinceReferenceDate
        let since = reaction.map { now.timeIntervalSince($0.at) } ?? 99
        ZStack {
            LinearGradient(colors: night ? [Color(hex: 0x1B2340), Color(hex: 0x2B2350)] : [Color(hex: 0xBFE3FF), Color(hex: 0xFFE3EC)],
                           startPoint: .top, endPoint: .bottom)
            sky(night: night, t: t)
            // Grass, a soft hill.
            Ellipse().fill(night ? Color(hex: 0x2E5A45) : Color(hex: 0x9EDB9A)).frame(width: 340, height: 120).offset(y: 108)
            Ellipse().fill(night ? Color(hex: 0x29503D) : Color(hex: 0x8BD08A)).frame(width: 200, height: 60).offset(x: -90, y: 100)
            bed.offset(x: 72, y: 66)
            bowl(full: pet.fullness(now: now) > 0.3).offset(x: -78, y: 82)
            Text(verbatim: pet.adoption.kind == .cat ? "🧶" : "🎾").font(.system(size: 18))
                .offset(x: 88 + (reaction?.care == .play ? -40 * bounceArc(since) : 0), y: 92 - 30 * bounceArc(since))
            petView(feeling: feeling, t: t, since: since).offset(y: 34)
            floaters(since: since)
            if night {
                Text(verbatim: "z").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                    .offset(x: 30 + 6 * sin(t), y: -14 - (t.truncatingRemainder(dividingBy: 3)) * 8)
                    .opacity(1 - (t.truncatingRemainder(dividingBy: 3)) / 3)
            }
        }
    }

    @ViewBuilder private func sky(night: Bool, t: Double) -> some View {
        if night {
            ForEach(0..<9) { i in
                Circle().fill(.white).frame(width: 2.5, height: 2.5)
                    .opacity(0.4 + 0.5 * abs(sin(t * 0.8 + Double(i))))
                    .offset(x: CGFloat((i * 53) % 200) - 100, y: CGFloat((i * 37) % 90) - 100)
            }
            Circle().fill(Color(hex: 0xFFF3C4)).frame(width: 26, height: 26).offset(x: 78, y: -82)
        } else {
            Circle().fill(Color(hex: 0xFFD65C)).frame(width: 30, height: 30).offset(x: 78, y: -80)
            Capsule().fill(.white.opacity(0.85)).frame(width: 46, height: 14).offset(x: -60 + 6 * sin(t * 0.2), y: -72)
            Capsule().fill(.white.opacity(0.7)).frame(width: 30, height: 10).offset(x: -30 + 4 * sin(t * 0.3), y: -86)
        }
    }

    /// Hops when fed or played with, wiggles when petted; tricks take turns: a spin, a jump, a roll.
    private func petView(feeling: PetFeeling, t: Double, since: Double) -> some View {
        let care = reaction?.care
        let hop = (care == .feed || care == .play) ? 16 * bounceArc(since) : 0
        let trickKind = trick % 3
        let p = care == .trick ? min(1, since / 0.9) : 1
        let spin = care == .trick && trickKind == 0 ? 360 * ease(p) : 0
        let jump = care == .trick && trickKind == 1 ? 46 * sin(.pi * p) : 0
        let roll = care == .trick && trickKind == 2 ? 360 * ease(p) : 0
        let wiggle = care == .pet && since < 1 ? 6 * sin(since * 30) * (1 - since) : 0
        return PetDrawing(kind: pet.adoption.kind, look: pet.look, feeling: since < 2.5 && care != nil && feeling != .sleeping ? .happy : feeling,
                          stage: pet.stage(now: now), time: t, size: 130)
            .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
            .rotationEffect(.degrees(roll + wiggle))
            .offset(x: care == .trick && trickKind == 2 ? 30 * sin(.pi * p) : 0, y: -hop - jump)
    }

    /// Food, hearts, a star: rising and fading over the pet.
    @ViewBuilder private func floaters(since: Double) -> some View {
        if let care = reaction?.care, since < 1.6 {
            let symbols: [String] = switch care {
            case .feed: [pet.adoption.kind == .cat ? "🐟" : "🦴", "😋"]
            case .pet: ["💕", "💗", "💞"]
            case .play: ["✨", "💛"]
            case .trick: ["⭐️", "✨", "🌟"]
            }
            ForEach(Array(symbols.enumerated()), id: \.offset) { i, symbol in
                let delay = Double(i) * 0.15, p = max(0, min(1, (since - delay) / 1.3))
                Text(symbol).font(.system(size: 18))
                    .offset(x: CGFloat(i - symbols.count / 2) * 26, y: -10 - 70 * p)
                    .opacity(p == 0 ? 0 : 1 - p)
                    .scaleEffect(0.6 + 0.5 * p)
            }
        }
    }

    private func bowl(full: Bool) -> some View {
        ZStack {
            if full {
                Ellipse().fill(Color(hex: 0xC98B5B)).frame(width: 26, height: 9).offset(y: -5)
            }
            UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10)
                .fill(Color.notchPink).frame(width: 32, height: 13)
        }
    }

    private var bed: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xB59BDB)).frame(width: 52, height: 18)
            Capsule().fill(Color(hex: 0xD9C8F2)).frame(width: 40, height: 10).offset(y: -3)
        }
    }

    /// 0 → 1 → 0 over 0.6 s.
    private func bounceArc(_ since: Double) -> Double { since < 0.6 ? sin(.pi * since / 0.6) : 0 }
    private func ease(_ p: Double) -> Double { p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2 }
}

// MARK: Dressing up

private struct LookPicker: View {
    let state: AppState
    let pet: Pet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coat").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Color.secondaryLabel).padding(.top, 10)
            HStack(spacing: 8) {
                ForEach(PetCoat.allCases, id: \.self) { coat in
                    Button { state.setPetLook(coat: coat) } label: {
                        PetDrawing(kind: pet.adoption.kind, look: PetLook(coat: coat, accessory: .none), feeling: .content, stage: .grown, size: 34)
                            .frame(width: 44, height: 44)
                            .background(Color.notchField, in: Circle())
                            .overlay(Circle().strokeBorder(pet.look.coat == coat ? Color.notchPink : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Wear").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Color.secondaryLabel)
            HStack(spacing: 6) {
                ForEach(PetAccessory.allCases, id: \.self) { item in
                    Button { state.setPetLook(accessory: item) } label: {
                        Text(item.symbol).font(.system(size: 16))
                            .frame(width: 36, height: 30)
                            .background(pet.look.accessory == item ? Color.notchPressed : .notchField, in: Capsule())
                            .overlay(Capsule().strokeBorder(pet.look.accessory == item ? Color.notchPink.opacity(0.7) : .clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.label)
                }
            }
        }
    }
}

extension PetAccessory {
    var symbol: String {
        switch self {
        case .none: "∅"
        case .bow: "🎀"
        case .flower: "🌸"
        case .scarf: "🧣"
        case .cap: "🧢"
        }
    }

    var label: String {
        switch self {
        case .none: String(localized: "Nothing")
        case .bow: String(localized: "Bow")
        case .flower: String(localized: "Flower")
        case .scarf: String(localized: "Scarf")
        case .cap: String(localized: "Cap")
        }
    }
}

// MARK: Adopting

private struct Adoption: View {
    let state: AppState
    @Binding var isEditing: Bool
    let isShown: Bool
    @State private var kind: PetKind = .cat
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        let side = Config.Notch.contentSize.height
        HStack(spacing: 10) {
            TimelineView(.animation(paused: !isShown)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xBFE3FF), Color(hex: 0xFFE3EC)], startPoint: .top, endPoint: .bottom)
                    Ellipse().fill(Color(hex: 0x9EDB9A)).frame(width: 340, height: 120).offset(y: 108)
                    HStack(spacing: -6) {
                        ForEach(PetKind.allCases, id: \.self) { each in
                            Button { kind = each } label: {
                                PetDrawing(kind: each, look: PetLook(), feeling: kind == each ? .happy : .content, stage: .baby, time: t, size: 110)
                                    .offset(y: kind == each ? -6 : 0)
                                    .opacity(kind == each ? 1 : 0.6)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(each.label)
                        }
                    }
                    .offset(y: 46)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: kind)
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Adopt a little one together").font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Feed it, cuddle it, teach it tricks, from both your Macs. It grows up with you two.")
                    .font(.system(size: 12)).foregroundStyle(Color.secondaryLabel).fixedSize(horizontal: false, vertical: true)
                SmallSegmented(options: PetKind.allCases, selection: $kind, label: \.label)
                TextField("", text: $name, prompt: Text(verbatim: Config.Pet.names[kind]!).foregroundStyle(Color.tertiaryLabel))
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white)
                    .focused($focused)
                    .onSubmit(adopt)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(Color.notchField, in: Capsule())
                Spacer(minLength: 0)
                Button(action: adopt) {
                    Label("Adopt", systemImage: "pawprint.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.notchPink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .cardStyle()
        }
        .onChange(of: focused) { _, now in isEditing = now }
        .onChange(of: isShown) { _, shown in if !shown { focused = false } }
    }

    private func adopt() {
        focused = false
        state.adoptPet(kind, name: name)
    }
}

// MARK: Bits

private struct Meter: View {
    let label: String
    let symbol: String
    let value: Double

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.notchBlush).frame(width: 14)
            Text(label).font(.system(size: 11.5, weight: .medium)).foregroundStyle(Color.secondaryLabel).frame(width: 36, alignment: .leading)
            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.notchField)
                    Capsule().fill(value < 0.3 ? Color(hex: 0xFF9F5A) : .notchPink)
                        .frame(width: max(8, bar.size.width * value))
                }
            }
            .frame(height: 8)
        }
        .animation(.snappy(duration: 0.3), value: value)
    }
}

private struct CareButton: View {
    let emoji: String
    let label: String
    let action: () -> Void
    @State private var pressed = 0

    var body: some View {
        Button { pressed += 1; action() } label: {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 20))
                    .phaseAnimator([1.0, 1.3, 1.0], trigger: pressed) { view, scale in view.scaleEffect(scale) }
                Text(label).font(.system(size: 10.5, weight: .medium)).foregroundStyle(Color.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.notchField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
