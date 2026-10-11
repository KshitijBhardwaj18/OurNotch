import SwiftUI

/// Our pet, drawn from soft round shapes like Pip and Bun, on a 100-point grid scaled to `size`.
/// `time` drives breathing, blinking and the tail; the caller adds tricks and hops on top.
struct PetDrawing: View {
    let kind: PetKind
    let look: PetLook
    let feeling: PetFeeling
    let stage: PetStage
    var time: Double = 0
    var size: CGFloat = 120

    var body: some View {
        let breathe = 1 + 0.025 * sin(time * 2.2)
        ZStack {
            tail
            Ellipse().fill(coat).frame(width: 56, height: 40).position(x: 50, y: 74) // body
            Ellipse().fill(belly).frame(width: 30, height: 22).position(x: 50, y: 78)
            paws
            head.scaleEffect(stage == .baby ? 1.08 : 1, anchor: .bottom)
            if look.accessory == .scarf { scarf }
        }
        .frame(width: 100, height: 100)
        .scaleEffect(y: breathe, anchor: .bottom)
        .saturation(feeling == .sick ? 0.55 : 1)
        .scaleEffect(scale * size / 100)
        .frame(width: size, height: size)
    }

    // MARK: Parts

    private var head: some View {
        ZStack {
            ears
            Ellipse().fill(coat).frame(width: 62, height: 54).position(x: 50, y: 44)
            if kind == .dog { Ellipse().fill(belly).frame(width: 28, height: 19).position(x: 50, y: 57) } // snout
            cheeks
            eyes
            if stage == .wise { glasses }
            nose
            mouth
            if kind == .cat { whiskers }
            if feeling == .sick { plaster }
            accessory
        }
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(feeling == .lonely ? -6 : 3 * sin(time * 0.9)), anchor: .bottom)
    }

    @ViewBuilder private var ears: some View {
        switch kind {
        case .cat:
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    Triangle().fill(coat).frame(width: 22, height: 24)
                    Triangle().fill(Color(hex: 0xFFB3C2)).frame(width: 11, height: 12).offset(y: 4)
                }
                .rotationEffect(.degrees(side * (feeling == .lonely || feeling == .sick ? 28 : 14)))
                .position(x: 50 + side * 19, y: 22)
            }
        case .dog:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse().fill(shade).frame(width: 18, height: 32)
                    .rotationEffect(.degrees(side * (14 + 4 * sin(time * 2.2))))
                    .position(x: 50 + side * 29, y: 44)
            }
        }
    }

    private var cheeks: some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Ellipse().fill(Color(hex: 0xFF8FA3).opacity(feeling == .sick ? 0.15 : 0.45))
                .frame(width: 10, height: 6).position(x: 50 + side * 19, y: 53)
        }
    }

    /// Open, happy ^ ^, or closed for sleep and blinks.
    @ViewBuilder private var eyes: some View {
        let blink = (time.truncatingRemainder(dividingBy: 4.3)) < 0.13
        ForEach([-1.0, 1.0], id: \.self) { side in
            Group {
                switch feeling {
                case .sleeping: Arc(up: false).stroke(ink, style: line(2.2)).frame(width: 9, height: 4)
                case .happy where !blink: Arc(up: true).stroke(ink, style: line(2.4)).frame(width: 9, height: 5)
                case .sick, .recovering: Capsule().fill(ink).frame(width: 8, height: 2.4)
                default:
                    if blink {
                        Arc(up: false).stroke(ink, style: line(2.2)).frame(width: 8, height: 3)
                    } else {
                        ZStack {
                            Circle().fill(ink).frame(width: 7.5, height: 7.5)
                            Circle().fill(.white).frame(width: 2.6, height: 2.6).offset(x: 1.4, y: -1.4)
                        }
                    }
                }
            }
            .position(x: 50 + side * 11, y: 42)
        }
        if feeling == .lonely {
            Capsule().fill(Color(hex: 0x8EC9FF)).frame(width: 3, height: 6).position(x: 63, y: 50) // a tear
        }
    }

    private var nose: some View {
        Group {
            if kind == .cat {
                Triangle().fill(Color(hex: 0xFF8FA3)).frame(width: 6, height: 4).rotationEffect(.degrees(180))
            } else {
                Ellipse().fill(ink).frame(width: 9, height: 6)
            }
        }
        .position(x: 50, y: kind == .cat ? 50 : 53)
    }

    @ViewBuilder private var mouth: some View {
        let y: CGFloat = kind == .cat ? 54 : 59
        switch feeling {
        case .hungry:
            Ellipse().fill(ink).frame(width: 5, height: 5).position(x: 50, y: y + 1)
        case .lonely, .sick:
            Arc(up: true).stroke(ink, style: line(1.6)).frame(width: 8, height: 3).position(x: 50, y: y + 2)
        default:
            ZStack {
                Arc(up: false).stroke(ink, style: line(1.6)).frame(width: 6, height: 3).offset(x: -3)
                Arc(up: false).stroke(ink, style: line(1.6)).frame(width: 6, height: 3).offset(x: 3)
                if kind == .dog, feeling == .happy {
                    Capsule().fill(Color(hex: 0xFF7A93)).frame(width: 6, height: 7).offset(y: 4)
                }
            }
            .position(x: 50, y: y)
        }
    }

    private var whiskers: some View {
        Canvas { context, _ in
            for side in [-1.0, 1.0] {
                for (dy, tilt) in [(-2.0, -2.0), (1.5, 1.5)] {
                    var path = Path()
                    path.move(to: CGPoint(x: 50 + side * 14, y: 52 + dy))
                    path.addLine(to: CGPoint(x: 50 + side * 27, y: 52 + dy + tilt))
                    context.stroke(path, with: .color(ink.opacity(0.45)), lineWidth: 1)
                }
            }
        }
        .frame(width: 100, height: 100)
    }

    private var glasses: some View {
        ZStack {
            Circle().stroke(ink, lineWidth: 1.4).frame(width: 13, height: 13).offset(x: -11)
            Circle().stroke(ink, lineWidth: 1.4).frame(width: 13, height: 13).offset(x: 11)
            Capsule().fill(ink).frame(width: 9, height: 1.4)
        }
        .position(x: 50, y: 42)
    }

    /// A little plaster while it's poorly.
    private var plaster: some View {
        RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xF3D3B0))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: 0xD9B48C), lineWidth: 0.8))
            .frame(width: 14, height: 6).rotationEffect(.degrees(-30)).position(x: 64, y: 28)
    }

    @ViewBuilder private var accessory: some View {
        switch look.accessory {
        case .none, .scarf: EmptyView()
        case .bow:
            HStack(spacing: -2) {
                Triangle().fill(Color.notchPink).frame(width: 10, height: 10).rotationEffect(.degrees(90))
                Circle().fill(Color.notchPinkPressed).frame(width: 5, height: 5)
                Triangle().fill(Color.notchPink).frame(width: 10, height: 10).rotationEffect(.degrees(-90))
            }
            .rotationEffect(.degrees(-15)).position(x: 68, y: 22)
        case .flower:
            ZStack {
                ForEach(0..<5) { i in
                    Circle().fill(Color(hex: 0xFFD6E0)).frame(width: 6, height: 6).offset(y: -3.5)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: 0xFFC94D)).frame(width: 4, height: 4)
            }
            .position(x: 31, y: 24)
        case .cap:
            ZStack {
                Ellipse().fill(Color(hex: 0x5B8DEF)).frame(width: 34, height: 18).offset(y: -2)
                Capsule().fill(Color(hex: 0x3F6FD6)).frame(width: 22, height: 5).offset(x: 12, y: 5)
            }
            .position(x: 50, y: 19)
        }
    }

    private var scarf: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xFF5A6E)).frame(width: 46, height: 9)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xE84459)).frame(width: 8, height: 14).offset(x: 12, y: 8)
        }
        .position(x: 50, y: 70)
    }

    private var paws: some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Ellipse().fill(coat).frame(width: 15, height: 10).position(x: 50 + side * 12, y: 92)
        }
    }

    /// Behind the body; wags faster when happy, droops when sad.
    private var tail: some View {
        let speed = feeling == .happy ? 9.0 : feeling == .sleeping || feeling == .sick ? 0 : 3.5
        let wag = 14 * sin(time * speed)
        return Group {
            if kind == .cat {
                Arc(up: true).stroke(coat, style: line(7)).frame(width: 26, height: 30)
                    .rotationEffect(.degrees(-30 + wag), anchor: .bottomLeading)
                    .position(x: 84, y: 64)
            } else {
                Capsule().fill(coat).frame(width: 8, height: 18)
                    .rotationEffect(.degrees(40 + wag), anchor: .bottom)
                    .position(x: 78, y: 66)
            }
        }
    }

    // MARK: Style

    private var scale: CGFloat {
        switch stage {
        case .baby: 0.72
        case .young: 0.86
        case .grown, .wise: 1
        }
    }

    private var palette: (coat: UInt32, shade: UInt32, belly: UInt32) {
        switch look.coat {
        case .peach: (0xF7BE91, 0xE39A66, 0xFCE3CF)
        case .cream: (0xF4E3C1, 0xD9BC8C, 0xFFF6E6)
        case .grey: (0xC3C8D2, 0x9AA0AD, 0xEEF0F4)
        case .choco: (0xA8775A, 0x7D5139, 0xD9B79F)
        }
    }

    private var coat: Color { Color(hex: palette.coat) }
    private var shade: Color { Color(hex: palette.shade) }
    private var belly: Color { Color(hex: palette.belly) }
    private var ink: Color { Color(hex: 0x3A2B2B) }
    private func line(_ width: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: width, lineCap: .round) }
}

/// A soft-cornered triangle pointing up (ears, bows, the cat's nose).
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.08))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.midY))
        return path
    }
}

/// A half-ellipse curve: ∩ when `up`, ∪ otherwise (eyes, the ω mouth, the cat's tail).
struct Arc: Shape {
    let up: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: up ? rect.maxY : rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: up ? rect.maxY : rect.minY),
                          control: CGPoint(x: rect.midX, y: up ? rect.minY - rect.height : rect.maxY + rect.height))
        return path
    }
}
