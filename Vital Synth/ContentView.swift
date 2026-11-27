//
//  ContentView.swift
//  Vital Synth
//
//  Standalone GUI matching Vital desktop FullInterface layout.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Color Theme

enum VitalColors {
    // Matched to Vital default.vialskin / desktop FullInterface
    static let background   = Color(red: 32/255,  green: 35/255,  blue: 38/255)
    static let body         = Color(red: 52/255,  green: 55/255,  blue: 58/255)
    static let bodyHeading  = Color(red: 44/255,  green: 47/255,  blue: 50/255)
    static let widgetBg     = Color(red: 22/255,  green: 24/255,  blue: 27/255)
    static let headerBg     = Color(red: 26/255,  green: 28/255,  blue: 31/255)
    static let panelEdge    = Color.white.opacity(0.06)
    static let panelInset   = Color.black.opacity(0.28)
    static let accent       = Color(red: 170/255, green: 136/255, blue: 255/255) // osc purple
    static let accentDim    = Color(red: 110/255, green: 114/255, blue: 118/255)
    static let modTeal      = Color(red: 29/255,  green: 233/255, blue: 182/255) // env/lfo/macros
    static let warmOrange   = Color(red: 255/255, green: 176/255, blue: 64/255)  // filters
    static let bodyText     = Color(red: 220/255, green: 223/255, blue: 223/255)
    static let labelText    = Color(red: 120/255, green: 124/255, blue: 128/255)
    static let rotaryBody   = Color(red: 34/255,  green: 37/255,  blue: 40/255)
    static let rotaryBorder = Color(red: 68/255,  green: 71/255,  blue: 74/255)
    static let powerOn      = Color(red: 170/255, green: 136/255, blue: 255/255)
    static let powerOff     = Color(red: 72/255,  green: 74/255,  blue: 77/255)

    // Effect accents (Vital skin)
    static let fxChorus     = Color(red: 170/255, green: 136/255, blue: 255/255)
    static let fxCompressor = Color(red: 29/255,  green: 200/255, blue: 190/255)
    static let fxDelay      = Color(red: 255/255, green: 120/255, blue: 180/255)
    static let fxDistortion = Color(red: 255/255, green: 80/255,  blue: 80/255)
    static let fxEQ         = Color(red: 240/255, green: 230/255, blue: 200/255)
    static let fxFilter     = Color(red: 255/255, green: 160/255, blue: 60/255)
    static let fxFlanger    = Color(red: 255/255, green: 220/255, blue: 80/255)
    static let fxPhaser     = Color(red: 80/255,  green: 220/255, blue: 255/255)
    static let fxReverb     = Color(red: 140/255, green: 120/255, blue: 255/255)
}

// MARK: - Knob

struct VitalKnob: View {
    let label: String
    @Binding var value: Float
    var size: CGFloat = 44
    var color: Color = VitalColors.accent

    @State private var startValue: Float = 0

    private var angle: Double { Double(value) * 270.0 - 135.0 }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(VitalColors.rotaryBorder,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0.0, to: CGFloat(value) * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .fill(VitalColors.rotaryBody)
                    .overlay(Circle().stroke(VitalColors.rotaryBorder, lineWidth: 1))
                    .padding(5)
                Circle()
                    .fill(Color.white)
                    .frame(width: 3, height: 3)
                    .offset(y: -(size / 2 - 9))
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: size, height: size)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let delta = Float(-g.translation.height / 200)
                        value = max(0, min(1, startValue + delta))
                    }
                    .onEnded { _ in startValue = value }
            )
            if !label.isEmpty {
                VitalKnobLabel(label)
            }
        }
    }
}

/// Desktop-style knob caption: light text on a dark recessed tag.
struct VitalKnobLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(Color(white: 0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

/// Vertical module title strip (OSC 1 / SMP) matching desktop Vital.
struct VitalVerticalTitle: View {
    let title: String
    @Binding var isOn: Bool
    var color: Color = VitalColors.accent
    /// Compact mode for short rows (SAMPLE) so the power LED isn't clipped.
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 0) {
            Circle()
                .fill(isOn ? color : VitalColors.powerOff)
                .frame(width: compact ? 9 : 8, height: compact ? 9 : 8)
                .shadow(color: isOn ? color.opacity(0.85) : .clear, radius: 4)
                .frame(width: 20, height: compact ? 20 : 24)
                .contentShape(Rectangle())
                .onTapGesture { isOn.toggle() }
                .padding(.top, compact ? 4 : 6)

            if !compact { Spacer(minLength: 2) }

            Text(title)
                .font(.system(size: compact ? 9 : 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(isOn ? VitalColors.bodyText : VitalColors.labelText)
                .fixedSize()
                .rotationEffect(.degrees(-90))
                .frame(width: 18, height: compact ? 36 : 72)

            if !compact { Spacer(minLength: 2) }
        }
        .frame(width: 24)
        .frame(maxHeight: .infinity)
        .background(VitalColors.bodyHeading)
        .overlay(Rectangle().frame(width: 1)
            .foregroundColor(VitalColors.panelEdge), alignment: .trailing)
    }
}

/// Sample / audio buffer waveform viewer (desktop SMP style).
struct SampleWaveformView: View {
    var samples: [Float]
    var color: Color = VitalColors.accent
    var active: Bool = true

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let mid = h * 0.5
            let amp = mid * 0.78

            // Center line
            var midLine = Path()
            midLine.move(to: .init(x: 0, y: mid))
            midLine.addLine(to: .init(x: w, y: mid))
            ctx.stroke(midLine, with: .color(Color.white.opacity(0.06)), lineWidth: 1)

            guard !samples.isEmpty else {
                // Empty placeholder: quiet noise hint
                var path = Path()
                let steps = Int(w)
                for i in 0...steps {
                    let t = Double(i) / Double(max(steps, 1))
                    let n = sin(t * 40) * 0.08 + sin(t * 97) * 0.04
                    let y = mid - n * amp
                    if i == 0 { path.move(to: .init(x: t * w, y: y)) }
                    else { path.addLine(to: .init(x: t * w, y: y)) }
                }
                ctx.stroke(path, with: .color(color.opacity(0.25)),
                           style: StrokeStyle(lineWidth: 1, lineCap: .round))
                return
            }

            var path = Path()
            let n = samples.count
            for i in 0..<Int(w) {
                let idx = min(n - 1, i * n / max(Int(w), 1))
                let y = mid - Double(samples[idx]) * amp
                if i == 0 { path.move(to: .init(x: Double(i), y: y)) }
                else { path.addLine(to: .init(x: Double(i), y: y)) }
            }
            var fill = path
            fill.addLine(to: .init(x: w, y: mid))
            fill.addLine(to: .init(x: 0, y: mid))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(color.opacity(active ? 0.22 : 0.08)))
            ctx.stroke(path, with: .color(color.opacity(active ? 0.25 : 0.1)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
            ctx.stroke(path, with: .color(color.opacity(active ? 0.95 : 0.4)),
                       style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.45), lineWidth: 1))
        )
        .opacity(active ? 1 : 0.45)
    }
}

// MARK: - Waveform display

struct WavetableView: View {
    var waveShape: Int = 0
    var color: Color = VitalColors.accent

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let mid = h * 0.5, amp = mid * 0.72
            let cycles = 3.0
            var path = Path()
            var started = false
            let steps = Int(w * 2)
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let phase = (t * cycles).truncatingRemainder(dividingBy: 1.0)
                let x = t * w
                let y: Double
                switch waveShape {
                case 0:  y = mid + (phase * 2 - 1) * amp
                case 1:  y = mid - sin(phase * .pi * 2) * amp
                case 2:  y = mid - (phase < 0.5 ? (phase * 4 - 1) : (3 - phase * 4)) * amp
                default: y = mid - (phase < 0.5 ? 1.0 : -1.0) * amp
                }
                if !started { path.move(to: .init(x: x, y: y)); started = true }
                else        { path.addLine(to: .init(x: x, y: y)) }
            }
            var fill = path
            fill.addLine(to: .init(x: w, y: h))
            fill.addLine(to: .init(x: 0, y: h))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(color.opacity(0.18)))
            ctx.stroke(path, with: .color(color.opacity(0.2)),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ctx.stroke(path, with: .color(color.opacity(0.9)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.45), lineWidth: 1))
        )
    }
}

// MARK: - Wavetable 3D

struct Wavetable3DView: View {
    var frames: [[Float]]
    var color: Color = VitalColors.accent

    private var slices: [[Float]] {
        guard !frames.isEmpty else { return [] }
        let n = min(8, frames.count)
        if frames.count <= n { return frames }
        return (0..<n).map { i in
            let idx = i * (frames.count - 1) / max(n - 1, 1)
            return frames[min(idx, frames.count - 1)]
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let s = slices
            let n = s.count
            guard n > 0 else { return }
            let w = size.width, h = size.height
            let depthY  = n > 1 ? h * 0.28 / Double(n - 1) : 0.0
            let depthX  = n > 1 ? w * 0.12 / Double(n - 1) : 0.0
            let drawW   = w - depthX * Double(n - 1)
            let amp     = (h - depthY * Double(n - 1)) * 0.40
            let frontMY = h * 0.70
            for fi in 0..<n {
                let slice = s[fi]
                let t     = Double(fi) / Double(max(n - 1, 1))
                let depth = Double(n - 1 - fi)
                let origX = depth * depthX
                let midY  = frontMY - depth * depthY
                let opacity = 0.25 + 0.75 * t
                var path = Path()
                let ns = slice.count
                guard ns > 1 else { continue }
                for si in 0...Int(drawW) {
                    let pct  = Double(si) / drawW
                    let sIdx = min(Int(pct * Double(ns - 1)), ns - 1)
                    let py   = midY - Double(slice[sIdx]) * amp
                    let px   = origX + Double(si)
                    if si == 0 { path.move(to: .init(x: px, y: py)) }
                    else       { path.addLine(to: .init(x: px, y: py)) }
                }
                ctx.stroke(path, with: .color(color.opacity(opacity * 0.22)),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round))
                ctx.stroke(path, with: .color(color.opacity(opacity)),
                           style: StrokeStyle(lineWidth: fi == n - 1 ? 1.5 : 1.0,
                                              lineCap: .round))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.45), lineWidth: 1))
        )
    }
}

// MARK: - Filter curve

struct FilterCurveView: View {
    var cutoff: Float = 0.5
    var resonance: Float = 0.5
    var color: Color = VitalColors.accent

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            for t in [0.25, 0.5, 0.75] {
                var g = Path()
                g.move(to: .init(x: t * w, y: 0))
                g.addLine(to: .init(x: t * w, y: h))
                ctx.stroke(g, with: .color(.white.opacity(0.05)), lineWidth: 1)
                var gh = Path()
                gh.move(to: .init(x: 0, y: t * h))
                gh.addLine(to: .init(x: w, y: t * h))
                ctx.stroke(gh, with: .color(.white.opacity(0.05)), lineWidth: 1)
            }
            var path = Path()
            let cutX = Double(cutoff)
            let res  = Double(resonance)
            for i in 0...Int(w) {
                let t    = Double(i) / w
                let dist = t - cutX
                let peak = res * 2.2 * exp(-dist * dist / 0.0025)
                let roll = dist > 0 ? -dist * 4.8 : 0.0
                let gain = max(0.0, min(1.0, 0.5 + (roll + peak) / 3.5))
                let y    = h * (1.0 - gain * 0.85 + 0.05)
                if i == 0 { path.move(to: .init(x: t * w, y: y)) }
                else       { path.addLine(to: .init(x: t * w, y: y)) }
            }
            var fill = path
            fill.addLine(to: .init(x: w, y: h))
            fill.addLine(to: .init(x: 0,  y: h))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(color.opacity(0.45)))
            ctx.stroke(path, with: .color(color.opacity(0.22)),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ctx.stroke(path, with: .color(color.opacity(0.9)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            let cx = cutX * w
            var mk = Path()
            mk.move(to: .init(x: cx, y: 0))
            mk.addLine(to: .init(x: cx, y: h))
            ctx.stroke(mk, with: .color(color.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.45), lineWidth: 1))
        )
    }
}

// MARK: - Envelope shape (DAHDSR-aware)

struct EnvelopeShapeView: View {
    var delay: Float = 0
    var attack: Float
    var hold: Float = 0
    var decay: Float
    var sustain: Float
    var release: Float
    var color: Color = VitalColors.accent

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let pad = h * 0.1
            let sustainHold = 0.18
            let total = Double(delay + attack + hold + decay + release) + sustainHold + 0.001
            let xDel = Double(delay) / total * w
            let xA = xDel + Double(attack) / total * w
            let xH = xA + Double(hold) / total * w
            let xD = xH + Double(decay) / total * w
            let xS = xD + sustainHold / total * w
            let xR = min(w, xS + Double(release) / total * w)
            let yT = pad, yB = h - pad
            let yS = yT + (yB - yT) * (1.0 - Double(sustain))

            var path = Path()
            path.move(to: .init(x: 0, y: yB))
            path.addLine(to: .init(x: xDel, y: yB))
            path.addLine(to: .init(x: xA, y: yT))
            path.addLine(to: .init(x: xH, y: yT))
            path.addLine(to: .init(x: xD, y: yS))
            path.addLine(to: .init(x: xS, y: yS))
            path.addLine(to: .init(x: xR, y: yB))

            var fill = path
            fill.addLine(to: .init(x: 0, y: yB))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(color.opacity(0.12)))
            ctx.stroke(path, with: .color(color.opacity(0.25)),
                       style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            ctx.stroke(path, with: .color(color.opacity(0.95)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.45), lineWidth: 1))
        )
    }
}

// MARK: - Shared constants

private let waveNames = ["SAW", "SIN", "TRI", "SQ"]
private let destNames = ["F1", "F2", "F1+2", "FX", "OUT"]
private let filterModelNames = ["ANL", "DIR", "LAD", "DIG", "DIO", "FMT", "CMB", "PHS"]
private let spectralMorphNames = [
    "NONE", "VOC", "FORM", "HARM", "INH", "SMEAR", "RAND", "LP", "HP", "DISP", "SHEP", "SKEW"
]
private let distortionTypeNames = [
    "NONE", "SYNC", "FORM", "QUANT", "BEND", "SQZ", "PULSE",
    "FM A", "FM B", "FM S", "RM A", "RM B", "RM S"
]
private let randomStyleNames = ["PERLIN", "S&H", "SMOOTH", "WALK"]

private func powerLED(on: Binding<Bool>, color: Color) -> some View {
    Circle()
        .fill(on.wrappedValue ? color : VitalColors.powerOff)
        .frame(width: 8, height: 8)
        .shadow(color: on.wrappedValue ? color.opacity(0.85) : .clear, radius: 4)
        .frame(width: 16, height: 28)
        .contentShape(Rectangle())
        .onTapGesture { on.wrappedValue.toggle() }
}

private func sectionChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.body)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(VitalColors.panelEdge, lineWidth: 1)
                )
                .shadow(color: VitalColors.panelInset, radius: 0, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
}

/// Compact ◀ value ▶ stepper for tempo-synced rates (names come from the caller).
private func tempoStepper(label: String, names: [String], value: Int, color: Color,
                          onChange: @escaping (Int) -> Void) -> some View {
    let maxIdx = max(0, names.count - 1)
    let idx = min(max(value, 0), maxIdx)
    return HStack(spacing: 0) {
        VitalKnobLabel(label)
        Button { onChange(max(0, idx - 1)) } label: {
            Image(systemName: "chevron.left").font(.system(size: 8))
                .foregroundColor(VitalColors.labelText).frame(width: 20, height: 22)
        }.buttonStyle(.plain)
        Text(names.isEmpty ? "" : names[idx])
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .frame(minWidth: 34)
        Button { onChange(min(maxIdx, idx + 1)) } label: {
            Image(systemName: "chevron.right").font(.system(size: 8))
                .foregroundColor(VitalColors.labelText).frame(width: 20, height: 22)
        }.buttonStyle(.plain)
    }
    .background(VitalColors.widgetBg).cornerRadius(3)
}

// MARK: - Oscillator section (Vital columns)

struct OscillatorSection: View {
    let title: String
    @Binding var isOn: Bool
    @Binding var waveform: Int
    @Binding var waveFrame: Float
    @Binding var level: Float
    @Binding var pan: Float
    @Binding var transpose: Float   // 0-1 → −48..+48
    @Binding var destination: Int   // 0..4
    @Binding var unisonVoices: Int
    @Binding var unisonDetune: Float
    @Binding var phase: Float
    @Binding var spectralMorphType: Int
    @Binding var spectralMorphAmount: Float
    @Binding var distortionType: Int
    @Binding var distortionAmount: Float
    var displayFrames: [[Float]] = []
    var wavetableName: String = "Init"
    var knobSize: CGFloat = 28
    var onWavetableLoaded: ((URL) -> Void)? = nil
    /// Engine-driven TUNE knob position (0-1). When nil the knob keeps a local value.
    var tuneValue: Float? = nil
    var onTuneChanged: ((Float) -> Void)? = nil
    var onEditWavetable: (() -> Void)? = nil

    @State private var tune: Float = 0.5
    @State private var transStartVal: Float = 0
    @State private var showWavetablePicker = false
    @State private var isDropTargeted = false
    @State private var dropStatus: String? = nil

    private var semitones: Int { Int((transpose * 96 - 48).rounded()) }

    /// 1-based number of this oscillator, parsed from its title ("OSC 2" → 2).
    private var oscNumber: Int { Int(title.filter(\.isNumber)) ?? 1 }

    /// Distortion names with the real FM/RM modulator, mirroring
    /// ProducersModule::getFirst/SecondModulationIndex:
    /// OSC1 → A=OSC2, B=OSC3 · OSC2 → A=OSC1, B=OSC3 · OSC3 → A=OSC1, B=OSC2.
    private var distortionNames: [String] {
        let n = oscNumber - 1
        let firstIdx = (n == 0) ? 1 : 0
        let secondIdx = (n == 1) ? 2 : firstIdx + 1
        let a = "OSC \(firstIdx + 1)"
        let b = "OSC \(secondIdx + 1)"
        return [
            "NONE", "SYNC", "FORM", "QUANT", "BEND", "SQZ", "PULSE",
            "FM <- \(a)", "FM <- \(b)", "FM <- SMP",
            "RM <- \(a)", "RM <- \(b)", "RM <- SMP"
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            VitalVerticalTitle(title: title, isOn: $isOn, color: VitalColors.accent)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Level/Pan + Pitch packed tightly like desktop
                    HStack(spacing: 0) {
                        colPower
                        colPitch
                    }
                    Divider().background(Color.white.opacity(0.08))
                    colWave
                    Divider().background(Color.white.opacity(0.08))
                    colUnison
                    Divider().background(Color.white.opacity(0.08))
                    colPhase
                    Divider().background(Color.white.opacity(0.08))
                    colSpectral
                    Divider().background(Color.white.opacity(0.08))
                    colDistortion
                }
            }
        }
        .frame(height: 148)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.body)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isDropTargeted ? VitalColors.accent : VitalColors.panelEdge,
                                lineWidth: isDropTargeted ? 2 : 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(alignment: .bottom) {
            if let dropStatus {
                Text(dropStatus)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(VitalColors.accent)
                    .cornerRadius(3)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        // Files.app advertises audio/data/item — not always public.file-url.
        .onDrop(of: Self.dropTypes, delegate: WavetableDropDelegate(
            isTargeted: $isDropTargeted,
            onLoad: { url in
                guard onWavetableLoaded != nil else { return }
                onWavetableLoaded?(url)
                withAnimation { dropStatus = "Loaded \(url.deletingPathExtension().lastPathComponent)" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation { dropStatus = nil }
                }
            }
        ))
        .fileImporter(
            isPresented: $showWavetablePicker,
            allowedContentTypes: Self.wavetableTypes,
            onCompletion: { result in
                guard case .success(let url) = result else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                onWavetableLoaded?(url)
            }
        )
    }

    private static let wavetableTypes: [UTType] = [
        .audio, .json,
        UTType(filenameExtension: "vital") ?? .data,
        UTType(filenameExtension: "vitaltable") ?? .data
    ]

    /// Broad set so Files / Finder drags are accepted (not just fileURL).
    static let dropTypes: [UTType] = {
        var types: [UTType] = [
            .fileURL, .audio, .wav, .aiff, .mp3, .mpeg4Audio,
            .json, .data, .item, .content
        ]
        if let t = UTType(filenameExtension: "vital") { types.append(t) }
        if let t = UTType(filenameExtension: "vitaltable") { types.append(t) }
        if let t = UTType(filenameExtension: "flac") { types.append(t) }
        return types
    }()

    static let wavetableExtensions: Set<String> = [
        "wav", "aif", "aiff", "flac", "caf", "mp3", "m4a",
        "vital", "vitaltable", "json"
    ]

    // 1. Level + Pan + Destination (title moved to vertical strip)
    private var colPower: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("LEVEL / PAN")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)

            VStack(spacing: 4) {
                VitalKnob(label: "LEVEL", value: $level, size: knobSize, color: VitalColors.accent)
                VitalKnob(label: "PAN", value: $pan, size: knobSize, color: VitalColors.accent)
            }
            .padding(.top, 6)

            Spacer(minLength: 4)

            HStack(spacing: 1) {
                ForEach(Array(destNames.enumerated()), id: \.offset) { idx, label in
                    Button { destination = idx } label: {
                        Text(label)
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(destination == idx ? Color.black : VitalColors.labelText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(destination == idx ? VitalColors.accent : VitalColors.bodyHeading)
                    }.buttonStyle(.plain)
                }
            }
        }
        .frame(width: 68)
    }

    // 2. Transpose + Tune
    private var colPitch: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("PITCH")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)

            VStack(spacing: 2) {
                VitalKnobLabel("TRANS")
                Text(semitones >= 0 ? "+\(semitones)" : "\(semitones)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isOn ? VitalColors.accent : VitalColors.labelText)
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(VitalColors.widgetBg).cornerRadius(3)
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let delta = Float(-g.translation.height / 180)
                            transpose = max(0, min(1, transStartVal + delta))
                        }
                        .onEnded { _ in transStartVal = transpose }
                    )
            }
            .padding(.top, 8)

            VitalKnob(label: "TUNE", value: Binding(
                get: { tuneValue ?? tune },
                set: { tune = $0; onTuneChanged?($0) }
            ), size: knobSize, color: VitalColors.accent)
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(width: 49)
    }

    // 3. Wavetable — width matches SMP waveform viewer (~220)
    private var colWave: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button { waveform = max(0, waveform - 1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(VitalColors.labelText)
                        .frame(width: 24, height: 22)
                }.buttonStyle(.plain)
                Spacer(minLength: 2)
                Text(wavetableName.isEmpty ? waveNames[min(waveform, waveNames.count - 1)] : wavetableName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(VitalColors.bodyText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.middle)
                Spacer(minLength: 2)
                Button { waveform = min(waveNames.count - 1, waveform + 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(VitalColors.labelText)
                        .frame(width: 24, height: 22)
                }.buttonStyle(.plain)
                if onEditWavetable != nil {
                    Button { onEditWavetable?() } label: {
                        Text("EDIT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(VitalColors.accent)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(VitalColors.widgetBg)
                            .cornerRadius(2)
                    }.buttonStyle(.plain)
                }
                if onWavetableLoaded != nil {
                    Button { showWavetablePicker = true } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 9))
                            .foregroundColor(VitalColors.accent.opacity(0.8))
                            .frame(width: 22, height: 22)
                    }.buttonStyle(.plain)
                }
            }
            .background(VitalColors.bodyHeading)

            HStack(spacing: 4) {
                Group {
                    if displayFrames.isEmpty {
                        WavetableView(waveShape: waveform,
                                      color: isOn ? VitalColors.accent : VitalColors.accentDim)
                    } else {
                        Wavetable3DView(frames: displayFrames,
                                        color: isOn ? VitalColors.accent : VitalColors.accentDim)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isOn ? 1 : 0.4)

                VitalKnob(label: "WT POS", value: $waveFrame, size: 26, color: VitalColors.modTeal)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(maxHeight: .infinity)
        }
        .frame(width: 260)
    }

    // 4. Unison — larger DETUNE knob like desktop
    private var colUnison: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("UNISON")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)

            HStack(spacing: 3) {
                Button { unisonVoices = max(1, unisonVoices - 1) } label: {
                    Text("−").font(.system(size: 12)).foregroundColor(VitalColors.labelText)
                        .frame(width: 20, height: 20).background(VitalColors.bodyHeading).cornerRadius(2)
                }.buttonStyle(.plain)
                Text("\(unisonVoices)v")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(VitalColors.bodyText).frame(width: 28)
                Button { unisonVoices = min(16, unisonVoices + 1) } label: {
                    Text("+").font(.system(size: 12)).foregroundColor(VitalColors.labelText)
                        .frame(width: 20, height: 20).background(VitalColors.bodyHeading).cornerRadius(2)
                }.buttonStyle(.plain)
            }
            .padding(.top, 8)

            VitalKnob(label: "DETUNE", value: $unisonDetune, size: 42, color: VitalColors.accent)
                .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .frame(width: 88)
    }

    // 5. Phase — larger knob like desktop
    private var colPhase: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("PHASE")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)
            VitalKnob(label: "PHASE", value: $phase, size: 48, color: VitalColors.accent)
                .padding(.top, 14)
            Spacer(minLength: 0)
        }
        .frame(width: 78)
    }

    // 6. Spectral morph
    private var colSpectral: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("SPECTRAL")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)

            typeBrowser(names: spectralMorphNames, selected: $spectralMorphType, color: VitalColors.modTeal)
                .padding(.top, 4)
            VitalKnob(label: "AMT", value: $spectralMorphAmount, size: knobSize, color: VitalColors.modTeal)
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .frame(width: 88)
    }

    // 7. Distortion
    private var colDistortion: some View {
        VStack(spacing: 0) {
            VitalKnobLabel("DISTORT")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(VitalColors.bodyHeading)

            typeBrowser(names: distortionNames, selected: $distortionType, color: VitalColors.warmOrange)
                .padding(.top, 4)
            VitalKnob(label: "AMT", value: $distortionAmount, size: knobSize, color: VitalColors.warmOrange)
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .frame(width: 88)
    }

    private func typeBrowser(names: [String], selected: Binding<Int>, color: Color) -> some View {
        HStack(spacing: 0) {
            Button { selected.wrappedValue = max(0, selected.wrappedValue - 1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                    .frame(width: 16, height: 28)
            }.buttonStyle(.plain)
            Text(names[min(selected.wrappedValue, names.count - 1)])
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Button { selected.wrappedValue = min(names.count - 1, selected.wrappedValue + 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                    .frame(width: 16, height: 28)
            }.buttonStyle(.plain)
        }
        .background(VitalColors.widgetBg)
        .cornerRadius(3)
        .padding(.horizontal, 4)
    }
}

/// Accepts Files.app / Finder drops and proposes `.copy` so iOS shows a green + instead of 🚫.
private struct WavetableDropDelegate: DropDelegate {
    @Binding var isTargeted: Bool
    let onLoad: (URL) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        // Accept the drag session; extension filtering happens on load.
        // Files.app often omits public.file-url from the advertised types.
        true
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .copy)
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false
        let providers = info.itemProviders(for: OscillatorSection.dropTypes)
        return Self.load(from: providers, onLoad: onLoad)
    }

    @discardableResult
    static func load(from providers: [NSItemProvider], onLoad: @escaping (URL) -> Void) -> Bool {
        guard let provider = providers.first else { return false }

        // Preferred: concrete file URL object (Files / Finder).
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { object, _ in
                guard let url = object as? URL else { return }
                Self.persistAndDeliver(url: url, suggestedName: provider.suggestedName, onLoad: onLoad)
            }
            return true
        }

        // Try typed file representations in priority order.
        let typeIds = [
            UTType.fileURL.identifier,
            UTType.wav.identifier,
            UTType.aiff.identifier,
            UTType.audio.identifier,
            UTType.json.identifier,
            UTType.data.identifier,
            UTType.item.identifier
        ]
        if let typeId = typeIds.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            if typeId == UTType.fileURL.identifier {
                provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
                    let url: URL?
                    if let u = item as? URL {
                        url = u
                    } else if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    } else {
                        url = nil
                    }
                    guard let url else { return }
                    Self.persistAndDeliver(url: url, suggestedName: provider.suggestedName, onLoad: onLoad)
                }
            } else {
                provider.loadFileRepresentation(forTypeIdentifier: typeId) { url, _ in
                    guard let url else { return }
                    Self.persistAndDeliver(url: url, suggestedName: provider.suggestedName, onLoad: onLoad)
                }
            }
            return true
        }
        return false
    }

    private static func persistAndDeliver(url: URL, suggestedName: String?, onLoad: @escaping (URL) -> Void) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        var ext = url.pathExtension.lowercased()
        if ext.isEmpty, let name = suggestedName {
            ext = (name as NSString).pathExtension.lowercased()
        }
        if !ext.isEmpty && !OscillatorSection.wavetableExtensions.contains(ext) {
            return
        }
        if ext.isEmpty { ext = "wav" }

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("vital-drop-\(UUID().uuidString).\(ext)")
        if FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.removeItem(at: dest)
        }
        var persisted = (try? FileManager.default.copyItem(at: url, to: dest)) != nil
        if !persisted, let data = try? Data(contentsOf: url) {
            persisted = (try? data.write(to: dest)) != nil
        }
        guard persisted else { return }
        DispatchQueue.main.async { onLoad(dest) }
    }
}

// MARK: - Sample section

struct SampleSection: View {
    @ObservedObject var engine: VitalAudioEngine
    @State private var showSamplePicker = false

    var body: some View {
        sectionChrome {
            HStack(spacing: 0) {
                VitalVerticalTitle(
                    title: "SMP",
                    isOn: Binding(get: { engine.sampleOn }, set: { engine.setSampleOn($0) }),
                    color: VitalColors.accent,
                    compact: true
                )

                // Waveform viewer (desktop SMP center)
                SampleWaveformView(
                    samples: engine.sampleDisplayFrames,
                    color: VitalColors.accent,
                    active: engine.sampleOn
                )
                .frame(minWidth: 160, idealWidth: 220, maxWidth: 280)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)

                HStack(spacing: 14) {
                    VitalKnob(label: "LEVEL", value: Binding(
                        get: { engine.sampleLevel }, set: { engine.setSampleLevel($0) }
                    ), size: 36, color: VitalColors.accent)
                    VitalKnob(label: "PAN", value: Binding(
                        get: { engine.samplePan }, set: { engine.setSamplePan($0) }
                    ), size: 36, color: VitalColors.accent)
                    VStack(spacing: 3) {
                        Button { showSamplePicker = true } label: {
                            Text("LOAD")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(white: 0.92))
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(white: 0.11))
                                        .overlay(RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1))
                                )
                        }.buttonStyle(.plain)
                        Text(engine.sampleName.isEmpty ? "—" : engine.sampleName)
                            .font(.system(size: 7))
                            .foregroundColor(VitalColors.labelText)
                            .lineLimit(1)
                            .frame(width: 56)
                    }
                    Button {
                        engine.setSampleLoop(!engine.sampleLoop)
                    } label: {
                        Text("LOOP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(engine.sampleLoop ? Color(white: 0.92) : VitalColors.labelText)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(engine.sampleLoop ? VitalColors.accent.opacity(0.85) : Color(white: 0.11))
                                    .overlay(RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1))
                            )
                    }.buttonStyle(.plain)
                    VStack(spacing: 3) {
                        VitalKnobLabel("TRANS")
                        Text("\(Int(engine.sampleTranspose.rounded()))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(VitalColors.bodyText)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(VitalColors.widgetBg).cornerRadius(3)
                    }
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let delta = Float(-g.translation.height / 12)
                            engine.setSampleTranspose(max(-48, min(48, engine.sampleTranspose + delta * 0.05)))
                        }
                    )
                    Spacer(minLength: 0)
                }
                .padding(.trailing, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 92)
        }
        .fileImporter(
            isPresented: $showSamplePicker,
            allowedContentTypes: [.wav, .aiff, UTType(filenameExtension: "aif") ?? .aiff],
            onCompletion: { result in
                guard case .success(let url) = result else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                engine.loadSample(from: url)
            }
        )
    }
}

// MARK: - Filter section

struct FilterSection: View {
    var filterNumber: Int = 1
    var accentColor: Color = VitalColors.warmOrange
    @Binding var isOn: Bool
    @Binding var cutoff: Float
    @Binding var resonance: Float
    @Binding var drive: Float
    @Binding var model: Int
    @Binding var blend: Float
    var knobSize: CGFloat = 32
    /// Optional KEYTRACK knob (0-1 → filter_N_keytrack -1…1).
    var keytrack: Binding<Float>? = nil

    var body: some View {
        sectionChrome {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    powerLED(on: $isOn, color: accentColor)
                    Text("FILTER \(filterNumber)")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundColor(VitalColors.bodyText)
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(filterModelNames.enumerated()), id: \.offset) { idx, name in
                                Button { model = idx } label: {
                                    Text(name)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(model == idx ? VitalColors.rotaryBody : VitalColors.labelText)
                                        .padding(.horizontal, 4).padding(.vertical, 3)
                                        .background(model == idx ? accentColor : VitalColors.bodyHeading)
                                        .cornerRadius(2)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(VitalColors.bodyHeading)

                VStack(spacing: 5) {
                    FilterCurveView(cutoff: cutoff, resonance: resonance, color: accentColor)
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .opacity(isOn ? 1 : 0.45)
                    HStack(spacing: 0) {
                        VitalKnob(label: "CUTOFF", value: $cutoff, size: knobSize, color: accentColor)
                        Spacer(minLength: 6)
                        VitalKnob(label: "RES", value: $resonance, size: knobSize, color: accentColor)
                        Spacer(minLength: 6)
                        VitalKnob(label: "DRIVE", value: $drive, size: knobSize, color: accentColor)
                        Spacer(minLength: 6)
                        VitalKnob(label: "BLEND", value: $blend, size: knobSize, color: accentColor)
                        if let keytrack {
                            Spacer(minLength: 6)
                            VitalKnob(label: "KEYTRK", value: keytrack, size: knobSize, color: accentColor)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Right column: ENV / LFO / Random panels

struct ModulationSidePanel: View {
    @ObservedObject var engine: VitalAudioEngine
    @State private var envTab = 0
    @State private var lfoTab = 0
    @State private var lfoShapeToken = 0
    @State private var lfoGridSnap = false
    @State private var lfoSmoothOn = false
    @State private var randomTab = 0

    var body: some View {
        VStack(spacing: 5) {
            envPanel
            lfoPanel
            randomPanel
        }
    }

    // ENV 1-6
    private var envPanel: some View {
        sectionChrome {
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { i in
                        Button { envTab = i } label: {
                            Text("ENV \(i + 1)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(envTab == i ? VitalColors.rotaryBody : VitalColors.labelText)
                                .padding(.horizontal, 5).padding(.vertical, 4)
                                .background(envTab == i ? VitalColors.modTeal : VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(VitalColors.bodyHeading)

                let stages = envStages(envTab)
                VStack(spacing: 8) {
                    EnvelopeShapeView(
                        delay: 0,
                        attack: stages.attack.wrappedValue,
                        hold: stages.hold.wrappedValue,
                        decay: stages.decay.wrappedValue,
                        sustain: stages.sustain.wrappedValue,
                        release: stages.release.wrappedValue,
                        color: VitalColors.modTeal
                    )
                    .frame(height: 78)

                    HStack(spacing: 0) {
                        VitalKnob(label: "ATK", value: stages.attack, size: 34, color: VitalColors.modTeal)
                        Spacer(minLength: 4)
                        VitalKnob(label: "HLD", value: stages.hold, size: 34, color: VitalColors.modTeal)
                        Spacer(minLength: 4)
                        VitalKnob(label: "DEC", value: stages.decay, size: 34, color: VitalColors.modTeal)
                        Spacer(minLength: 4)
                        VitalKnob(label: "SUS", value: stages.sustain, size: 34, color: VitalColors.modTeal)
                        Spacer(minLength: 4)
                        VitalKnob(label: "REL", value: stages.release, size: 34, color: VitalColors.modTeal)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(10)
            }
        }
    }

    /// Vital's real envelope ranges: attack/decay/release raw 0…2.37842 (time = raw⁴ s,
    /// i.e. up to ~32 s), hold raw 0…1.41421. Knobs stay normalised 0…1.
    private static let envTimeMax: Float = 2.37842
    private static let envHoldMax: Float = 1.4142135

    private func envStages(_ i: Int) -> (
        attack: Binding<Float>, hold: Binding<Float>,
        decay: Binding<Float>, sustain: Binding<Float>, release: Binding<Float>
    ) {
        let raw = envStagesRaw(i)
        func scaled(_ b: Binding<Float>, _ maxValue: Float) -> Binding<Float> {
            Binding(
                get: { min(1, max(0, b.wrappedValue / maxValue)) },
                set: { b.wrappedValue = min(1, max(0, $0)) * maxValue }
            )
        }
        return (
            scaled(raw.attack, Self.envTimeMax),
            scaled(raw.hold, Self.envHoldMax),
            scaled(raw.decay, Self.envTimeMax),
            raw.sustain,
            scaled(raw.release, Self.envTimeMax)
        )
    }

    private func envStagesRaw(_ i: Int) -> (
        attack: Binding<Float>, hold: Binding<Float>,
        decay: Binding<Float>, sustain: Binding<Float>, release: Binding<Float>
    ) {
        switch i {
        case 1: return (
            Binding(get: { engine.env2Attack }, set: { engine.setEnv2Attack($0) }),
            Binding(get: { engine.env2Hold }, set: { engine.setEnv2Hold($0) }),
            Binding(get: { engine.env2Decay }, set: { engine.setEnv2Decay($0) }),
            Binding(get: { engine.env2Sustain }, set: { engine.setEnv2Sustain($0) }),
            Binding(get: { engine.env2Release }, set: { engine.setEnv2Release($0) })
        )
        case 2: return (
            Binding(get: { engine.env3Attack }, set: { engine.setEnv3Attack($0) }),
            Binding(get: { engine.env3Hold }, set: { engine.setEnv3Hold($0) }),
            Binding(get: { engine.env3Decay }, set: { engine.setEnv3Decay($0) }),
            Binding(get: { engine.env3Sustain }, set: { engine.setEnv3Sustain($0) }),
            Binding(get: { engine.env3Release }, set: { engine.setEnv3Release($0) })
        )
        case 3: return (
            Binding(get: { engine.env4Attack }, set: { engine.setEnv4Attack($0) }),
            Binding(get: { engine.env4Hold }, set: { engine.setEnv4Hold($0) }),
            Binding(get: { engine.env4Decay }, set: { engine.setEnv4Decay($0) }),
            Binding(get: { engine.env4Sustain }, set: { engine.setEnv4Sustain($0) }),
            Binding(get: { engine.env4Release }, set: { engine.setEnv4Release($0) })
        )
        case 4: return (
            Binding(get: { engine.env5Attack }, set: { engine.setEnv5Attack($0) }),
            Binding(get: { engine.env5Hold }, set: { engine.setEnv5Hold($0) }),
            Binding(get: { engine.env5Decay }, set: { engine.setEnv5Decay($0) }),
            Binding(get: { engine.env5Sustain }, set: { engine.setEnv5Sustain($0) }),
            Binding(get: { engine.env5Release }, set: { engine.setEnv5Release($0) })
        )
        case 5: return (
            Binding(get: { engine.env6Attack }, set: { engine.setEnv6Attack($0) }),
            Binding(get: { engine.env6Hold }, set: { engine.setEnv6Hold($0) }),
            Binding(get: { engine.env6Decay }, set: { engine.setEnv6Decay($0) }),
            Binding(get: { engine.env6Sustain }, set: { engine.setEnv6Sustain($0) }),
            Binding(get: { engine.env6Release }, set: { engine.setEnv6Release($0) })
        )
        default: return (
            Binding(get: { engine.env1Attack }, set: { engine.setEnv1Attack($0) }),
            Binding(get: { engine.env1Hold }, set: { engine.setEnv1Hold($0) }),
            Binding(get: { engine.env1Decay }, set: { engine.setEnv1Decay($0) }),
            Binding(get: { engine.env1Sustain }, set: { engine.setEnv1Sustain($0) }),
            Binding(get: { engine.env1Release }, set: { engine.setEnv1Release($0) })
        )
        }
    }

    // LFO 1-8
    private var lfoPanel: some View {
        sectionChrome {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(0..<8, id: \.self) { i in
                            Button { lfoTab = i; lfoSmoothOn = engine.lfoSmooth(index: i) } label: {
                                Text("LFO \(i + 1)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(lfoTab == i ? VitalColors.rotaryBody : VitalColors.labelText)
                                    .padding(.horizontal, 5).padding(.vertical, 4)
                                    .background(lfoTab == i ? VitalColors.modTeal : VitalColors.bodyHeading)
                                    .cornerRadius(2)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(VitalColors.bodyHeading)

                VStack(spacing: 6) {
                    LfoShapeView(engine: engine, lfoIndex: lfoTab, color: VitalColors.modTeal,
                                 reloadToken: lfoShapeToken, gridSnap: lfoGridSnap)
                        .frame(height: 64)
                    HStack(spacing: 2) {
                        ForEach([("TRI", 1), ("SIN", 3), ("SQ", 2), ("SAW", 4)], id: \.1) { name, shape in
                            Button {
                                _ = engine.initLfoShape(index: lfoTab, shape: shape)
                                lfoSmoothOn = engine.lfoSmooth(index: lfoTab)
                                lfoShapeToken += 1
                            } label: {
                                Text(name)
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(VitalColors.labelText)
                                    .padding(.horizontal, 4).padding(.vertical, 3)
                                    .background(VitalColors.bodyHeading)
                                    .cornerRadius(2)
                            }.buttonStyle(.plain)
                        }
                        Button {
                            lfoSmoothOn.toggle()
                            _ = engine.setLfoSmooth(index: lfoTab, enabled: lfoSmoothOn)
                            lfoShapeToken += 1
                        } label: {
                            Text("SMOOTH")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(lfoSmoothOn ? .black : VitalColors.labelText)
                                .padding(.horizontal, 4).padding(.vertical, 3)
                                .background(lfoSmoothOn ? VitalColors.modTeal : VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                        Button {
                            lfoGridSnap.toggle()
                        } label: {
                            Text("GRID")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(lfoGridSnap ? .black : VitalColors.labelText)
                                .padding(.horizontal, 4).padding(.vertical, 3)
                                .background(lfoGridSnap ? VitalColors.modTeal : VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                        Button {
                            LfoShapeClipboard.data = engine.lfoStateJSON(index: lfoTab)
                        } label: {
                            Text("CPY")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(VitalColors.labelText)
                                .padding(.horizontal, 4).padding(.vertical, 3)
                                .background(VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                        Button {
                            guard let data = LfoShapeClipboard.data else { return }
                            _ = engine.setLfoStateJSON(index: lfoTab, data: data)
                            lfoSmoothOn = engine.lfoSmooth(index: lfoTab)
                            lfoShapeToken += 1
                        } label: {
                            Text("PST")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(LfoShapeClipboard.data == nil ? VitalColors.labelText.opacity(0.4) : VitalColors.labelText)
                                .padding(.horizontal, 4).padding(.vertical, 3)
                                .background(VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 0) {
                        VitalKnob(label: "RATE", value: Binding(
                            get: { engine.lfoRates[safe: lfoTab] ?? 0.25 },
                            set: { engine.setLfoRate(lfoTab, $0) }
                        ), size: 32, color: VitalColors.modTeal)
                        Spacer(minLength: 8)
                        VitalKnob(label: "PHASE", value: Binding(
                            get: { engine.lfoPhases[safe: lfoTab] ?? 0 },
                            set: { engine.setLfoPhase(lfoTab, $0) }
                        ), size: 32, color: VitalColors.modTeal)
                        Spacer(minLength: 8)
                        VitalKnob(label: "AMT", value: Binding(
                            get: { engine.lfoAmounts[safe: lfoTab] ?? 0 },
                            set: { engine.setLfoAmount(lfoTab, $0) }
                        ), size: 32, color: VitalColors.modTeal)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(["SEC", "TEMPO", "DOT", "TRIP", "KEY"].enumerated()), id: \.offset) { idx, name in
                                Button { engine.setLfoSync(lfoTab, idx) } label: {
                                    Text(name)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor((engine.lfoSyncs[safe: lfoTab] ?? 1) == idx ? .black : VitalColors.labelText)
                                        .padding(.horizontal, 4).padding(.vertical, 3)
                                        .background((engine.lfoSyncs[safe: lfoTab] ?? 1) == idx ? VitalColors.modTeal : VitalColors.bodyHeading)
                                        .cornerRadius(2)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    lfoTempoRow
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(VitalAudioEngine.lfoTargetNames.enumerated()), id: \.offset) { idx, name in
                                Button { engine.setLfoTarget(lfoTab, idx) } label: {
                                    Text(name)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor((engine.lfoTargets[safe: lfoTab] ?? 0) == idx ? .black : VitalColors.labelText)
                                        .padding(.horizontal, 4).padding(.vertical, 3)
                                        .background((engine.lfoTargets[safe: lfoTab] ?? 0) == idx ? VitalColors.modTeal : VitalColors.bodyHeading)
                                        .cornerRadius(2)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    /// lfo_N_tempo — only meaningful when the LFO is in a tempo mode (TEMPO / DOT / TRIP).
    @ViewBuilder
    private var lfoTempoRow: some View {
        let sync = engine.lfoSyncs[safe: lfoTab] ?? 1
        if sync >= 1 && sync <= 3 {
            HStack(spacing: 0) {
                tempoStepper(label: "TEMPO", names: VitalAudioEngine.tempoNames,
                             value: engine.lfoTempos[safe: lfoTab] ?? 8,
                             color: VitalColors.modTeal) { engine.setLfoTempo(lfoTab, $0) }
                Spacer(minLength: 0)
            }
        }
    }

    // Random 1-4
    private var randomPanel: some View {
        sectionChrome {
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        Button { randomTab = i } label: {
                            Text("RND \(i + 1)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(randomTab == i ? VitalColors.rotaryBody : VitalColors.labelText)
                                .padding(.horizontal, 5).padding(.vertical, 4)
                                .background(randomTab == i ? VitalColors.warmOrange : VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(VitalColors.bodyHeading)

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STYLE")
                            .font(.system(size: 7)).foregroundColor(VitalColors.labelText)
                        HStack(spacing: 0) {
                            Button {
                                engine.setRandomStyle(randomTab, max(0, (engine.randomStyle[safe: randomTab] ?? 0) - 1))
                            } label: {
                                Image(systemName: "chevron.left").font(.system(size: 8))
                                    .foregroundColor(VitalColors.labelText).frame(width: 18, height: 22)
                            }.buttonStyle(.plain)
                            Text(randomStyleNames[min(engine.randomStyle[safe: randomTab] ?? 0, randomStyleNames.count - 1)])
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(VitalColors.warmOrange)
                                .frame(minWidth: 56)
                            Button {
                                engine.setRandomStyle(randomTab, min(randomStyleNames.count - 1, (engine.randomStyle[safe: randomTab] ?? 0) + 1))
                            } label: {
                                Image(systemName: "chevron.right").font(.system(size: 8))
                                    .foregroundColor(VitalColors.labelText).frame(width: 18, height: 22)
                            }.buttonStyle(.plain)
                        }
                        .background(VitalColors.widgetBg).cornerRadius(3)
                    }
                    VitalKnob(label: "RATE", value: Binding(
                        get: { engine.randomRate[safe: randomTab] ?? 0.25 },
                        set: { engine.setRandomRate(randomTab, $0) }
                    ), size: 32, color: VitalColors.warmOrange)
                    Spacer()
                }
                .padding(10)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Matrix tab

struct MatrixTab: View {
    @ObservedObject var engine: VitalAudioEngine
    var body: some View { MatrixInterfaceView(engine: engine) }
}

// MARK: - Advanced tab

struct AdvancedTab: View {
    @ObservedObject var engine: VitalAudioEngine

    var body: some View {
        VStack(spacing: 10) {
            sectionChrome {
                VStack(spacing: 0) {
                    Text("VOICE")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundColor(VitalColors.bodyText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(VitalColors.bodyHeading)

                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("POLY").font(.system(size: 8)).foregroundColor(VitalColors.labelText)
                            HStack(spacing: 4) {
                                Button { engine.setPolyphony(engine.polyphony - 1) } label: {
                                    Text("−").frame(width: 22, height: 22)
                                        .background(VitalColors.bodyHeading).cornerRadius(3)
                                }.buttonStyle(.plain)
                                Text("\(engine.polyphony)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(VitalColors.bodyText).frame(width: 28)
                                Button { engine.setPolyphony(engine.polyphony + 1) } label: {
                                    Text("+").frame(width: 22, height: 22)
                                        .background(VitalColors.bodyHeading).cornerRadius(3)
                                }.buttonStyle(.plain)
                            }
                        }
                        Button { engine.setLegato(!engine.legato) } label: {
                            Text("LEGATO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(engine.legato ? .black : VitalColors.labelText)
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(engine.legato ? VitalColors.accent : VitalColors.bodyHeading)
                                .cornerRadius(4)
                        }.buttonStyle(.plain)

                        VitalKnob(label: "GLIDE", value: Binding(
                            get: { engine.glide }, set: { engine.setGlide($0) }
                        ), size: 34, color: VitalColors.accent)

                        VitalKnob(label: "PB RANGE", value: Binding(
                            get: { engine.pitchBendRange / 48 },
                            set: { engine.setPitchBendRange($0 * 48) }
                        ), size: 34, color: VitalColors.warmOrange)

                        VStack(spacing: 4) {
                            Text("OVERSAMPLE")
                                .font(.system(size: 8)).foregroundColor(VitalColors.labelText)
                            HStack(spacing: 2) {
                                ForEach(Array(["1×", "2×", "4×", "8×"].enumerated()), id: \.offset) { idx, label in
                                    Button { engine.setOversampling(idx) } label: {
                                        Text(label)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(engine.oversampling == idx ? .black : VitalColors.labelText)
                                            .frame(width: 30, height: 24)
                                            .background(engine.oversampling == idx ? VitalColors.accent : VitalColors.bodyHeading)
                                            .cornerRadius(3)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }

            ForEach(1...3, id: \.self) { osc in
                oscAdvanced(osc)
            }
        }
    }

    private func oscAdvanced(_ n: Int) -> some View {
        let i = n - 1
        return sectionChrome {
            VStack(spacing: 0) {
                Text("OSC \(n) ADVANCED")
                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                    .foregroundColor(VitalColors.bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(VitalColors.bodyHeading)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        VitalKnob(label: "DETUNE PWR", value: Binding(
                            get: {
                                switch n {
                                case 2: return engine.osc2DetunePower
                                case 3: return engine.osc3DetunePower
                                default: return engine.osc1DetunePower
                                }
                            },
                            set: {
                                switch n {
                                case 2: engine.setOsc2DetunePower($0)
                                case 3: engine.setOsc3DetunePower($0)
                                default: engine.setOsc1DetunePower($0)
                                }
                            }
                        ), size: 34, color: VitalColors.accent)
                        VitalKnob(label: "RND PHASE", value: Binding(
                            get: {
                                switch n {
                                case 2: return engine.osc2RandomPhase
                                case 3: return engine.osc3RandomPhase
                                default: return engine.osc1RandomPhase
                                }
                            },
                            set: {
                                switch n {
                                case 2: engine.setOsc2RandomPhase($0)
                                case 3: engine.setOsc3RandomPhase($0)
                                default: engine.setOsc1RandomPhase($0)
                                }
                            }
                        ), size: 34, color: VitalColors.modTeal)
                        VitalKnob(label: "UNI BLEND", value: Binding(
                            get: { engine.oscUnisonBlend[i] },
                            set: { engine.setOscUnisonBlend(i, $0) }
                        ), size: 34, color: VitalColors.accent)
                        VitalKnob(label: "ST SPREAD", value: Binding(
                            get: { engine.oscStereoSpread[i] },
                            set: { engine.setOscStereoSpread(i, $0) }
                        ), size: 34, color: VitalColors.accent)
                        VitalKnob(label: "DET RANGE", value: Binding(
                            get: { engine.oscDetuneRange[i] / 48 },
                            set: { engine.setOscDetuneRange(i, $0 * 48) }
                        ), size: 34, color: VitalColors.accent)
                        stackStylePicker(i)
                    }
                    .padding(12)
                }
            }
        }
    }

    private func stackStylePicker(_ i: Int) -> some View {
        let names = VitalAudioEngine.stackStyleNames
        let cur = min(max(engine.oscStackStyle[i], 0), names.count - 1)
        return VStack(spacing: 4) {
            VitalKnobLabel("STACK")
            HStack(spacing: 0) {
                Button { engine.setOscStackStyle(i, cur - 1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 8))
                        .foregroundColor(VitalColors.labelText).frame(width: 20, height: 24)
                }.buttonStyle(.plain)
                Text(names[cur])
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(VitalColors.accent)
                    .frame(minWidth: 52)
                Button { engine.setOscStackStyle(i, cur + 1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 8))
                        .foregroundColor(VitalColors.labelText).frame(width: 20, height: 24)
                }.buttonStyle(.plain)
            }
            .background(VitalColors.widgetBg).cornerRadius(3)
        }
    }
}

// MARK: - ContentView

private struct IdentifiedOsc: Identifiable {
    let id: Int
    init(_ id: Int) { self.id = id }
}

struct ContentView: View {
    @StateObject private var engine = VitalAudioEngine()
    @StateObject private var presetManager = PresetManager()
    @State private var showPresetSheet = false
    @State private var currentPresetIndex: Int? = nil
    @State private var selectedTab = 0
    @State private var editingOscillator: Int? = nil
    @State private var keyboardHeight: CGFloat = 56
    @GestureState private var kbDrag: CGFloat = 0
    @State private var pitchBend: Float = 0.5
    @State private var modWheel: Float = 0.0

    private var effectiveKbHeight: CGFloat { max(40, min(110, keyboardHeight - kbDrag)) }
    private let tabs = ["VOICE", "EFFECTS", "MATRIX", "ADVANCED"]

    private var allPresets: [PresetNavEntry] {
        presetManager.presets.map { .custom($0) } +
        presetManager.importedPresets.map { .imported($0) }
    }

    private func navigatePreset(by delta: Int) {
        let all = allPresets
        guard !all.isEmpty else { return }
        let idx: Int
        if let cur = currentPresetIndex {
            idx = (cur + delta + all.count) % all.count
        } else {
            idx = delta > 0 ? 0 : all.count - 1
        }
        currentPresetIndex = idx
        engine.allNotesOff()
        all[idx].apply(engine: engine)
    }

    private func randomLibraryPreset() {
        let all = allPresets
        guard !all.isEmpty else { return }
        let idx = Int.random(in: 0..<all.count)
        currentPresetIndex = idx
        engine.allNotesOff()
        all[idx].apply(engine: engine)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                headerBar
                mainBody(width: geo.size.width)
                keyboardHandle
                VitalKeyboardView(engine: engine)
                    .frame(height: effectiveKbHeight)
            }
        }
        .background(VitalColors.background.ignoresSafeArea())
        .onAppear { engine.start() }
        .sheet(isPresented: $showPresetSheet) {
            PresetSheet(manager: presetManager, engine: engine)
        }
        .fullScreenCover(item: Binding(
            get: { editingOscillator.map { IdentifiedOsc($0) } },
            set: { editingOscillator = $0?.id }
        )) { item in
            WavetableEditorView(engine: engine, oscillatorIndex: item.id) {
                editingOscillator = nil
            }
        }
    }

    // MARK: Header (48pt)

    private var headerBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Rectangle().fill(VitalColors.accent).frame(width: 3, height: 18)
                VStack(alignment: .leading, spacing: 0) {
                    Text("VITAL")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: VitalColors.accent.opacity(0.45), radius: 4)
                    Text("for iOS · Derbin Hamler")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(VitalColors.labelText)
                }
            }
            .padding(.leading, 10)

            // Tabs
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, title in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedTab = i }
                    } label: {
                        Text(title)
                            .font(.system(size: 10, weight: selectedTab == i ? .bold : .medium))
                            .tracking(0.8)
                            .foregroundColor(selectedTab == i ? VitalColors.accent : VitalColors.labelText)
                            .padding(.horizontal, 8).padding(.vertical, 6)
            .overlay(
                                Rectangle().frame(height: 2)
                                    .foregroundColor(selectedTab == i ? VitalColors.accent : .clear)
                                    .shadow(color: selectedTab == i ? VitalColors.accent.opacity(0.7) : .clear, radius: 4),
                                alignment: .bottom
                            )
                    }.buttonStyle(.plain)
                }
            }
            .padding(.leading, 12)

            Spacer(minLength: 4)

            // Patch nav
            HStack(spacing: 0) {
                let has = !allPresets.isEmpty
                Button { navigatePreset(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(has ? VitalColors.labelText : VitalColors.labelText.opacity(0.3))
                        .padding(5)
                }.buttonStyle(.plain).disabled(!has)

                Text(engine.currentPatch)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(minWidth: 70, maxWidth: 140)

                Button { navigatePreset(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(has ? VitalColors.labelText : VitalColors.labelText.opacity(0.3))
                        .padding(5)
                }.buttonStyle(.plain).disabled(!has)

                Button { randomLibraryPreset() } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 11))
                        .foregroundColor(has ? VitalColors.accent : VitalColors.labelText.opacity(0.3))
                        .padding(5)
                }.buttonStyle(.plain).disabled(!has)
            }

            Button { showPresetSheet = true } label: {
                let n = allPresets.count
                Text(n > 0 ? "PRESETS \(n)" : "PRESETS")
                    .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    .foregroundColor(VitalColors.labelText)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(VitalColors.body).cornerRadius(4)
            }.buttonStyle(.plain).padding(.leading, 6)

            Button { engine.resetToInit(); currentPresetIndex = nil } label: {
                Text("INIT")
                    .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    .foregroundColor(VitalColors.labelText)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(VitalColors.body).cornerRadius(4)
            }.buttonStyle(.plain).padding(.leading, 4)

            HStack(spacing: 3) {
                Text("VOL").font(.system(size: 8)).foregroundColor(VitalColors.labelText)
                VitalKnob(label: "", value: Binding(
                    get: { engine.masterVolume },
                    set: { engine.setMasterVolume($0) }
                ), size: 28, color: VitalColors.modTeal)
            }
            .padding(.trailing, 10).padding(.leading, 6)
        }
        .frame(height: 44)
        .background(VitalColors.headerBg)
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(VitalColors.panelEdge), alignment: .bottom)
    }

    // MARK: Main body

    private func mainBody(width: CGFloat) -> some View {
        let narrow = width < 900
        // Desktop Vital modulation column ~40%+; +15% vs previous 0.38 → ~0.437
        let modWidth = min(490, max(390, width * 0.437))
        return HStack(alignment: .top, spacing: 0) {
            // Left macros
            macrosColumn
                .frame(width: 64)

            if narrow {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        if selectedTab == 1 {
                            effectsStack
                        } else if selectedTab == 2 {
                            MatrixInterfaceView(engine: engine)
                        } else {
                            tabContent
                        }
                        ModulationSidePanel(engine: engine)
                    }
                    .padding(5)
                }
            } else {
                Group {
                    if selectedTab == 1 {
                        effectsStack
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if selectedTab == 2 {
                        MatrixInterfaceView(engine: engine)
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            tabContent
                                .padding(5)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                ScrollView(.vertical, showsIndicators: false) {
                    ModulationSidePanel(engine: engine)
                        .padding(.horizontal, 5).padding(.vertical, 5)
                }
                .frame(width: modWidth)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var macrosColumn: some View {
        VStack(spacing: 0) {
            Text("MACRO")
                .font(.system(size: 7, weight: .bold))
                .tracking(0.6)
                .foregroundColor(VitalColors.labelText)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Even vertical gaps between macros like desktop Vital
            ForEach(0..<4, id: \.self) { i in
                if i > 0 { Spacer(minLength: 14) }
                VStack(spacing: 2) {
                    VitalKnob(label: "", value: Binding(
                        get: { engine.macro[safe: i] ?? 0 },
                        set: { engine.setMacro(i, $0) }
                    ), size: 34, color: VitalColors.modTeal)
                    Text("\(i + 1)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(VitalColors.labelText)
                }
            }

            Spacer(minLength: 16)

            // Pitch / Mod wheels live under macros on desktop Vital
            WheelControl(label: "PITCH", value: $pitchBend,
                         springReturn: true, color: VitalColors.warmOrange)
                .frame(height: 90)
                .onChange(of: pitchBend) { engine.pitchBend($0) }

            WheelControl(label: "MOD", value: $modWheel,
                         springReturn: false, color: VitalColors.modTeal)
                .frame(height: 90)
                .onChange(of: modWheel) { engine.modWheel($0) }
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
        .frame(maxHeight: .infinity)
        .background(VitalColors.headerBg)
        .overlay(Rectangle().frame(width: 1)
            .foregroundColor(VitalColors.panelEdge), alignment: .trailing)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: voiceTab
        case 1: effectsTab
        case 2: MatrixTab(engine: engine)
        default: AdvancedTab(engine: engine)
        }
    }

    // MARK: VOICE

    private var voiceTab: some View {
        VStack(spacing: 5) {
            oscSection(1)
            oscSection(2)
            oscSection(3)
            SampleSection(engine: engine)
            HStack(alignment: .top, spacing: 5) {
                FilterSection(
                    filterNumber: 1, accentColor: VitalColors.warmOrange,
                    isOn: Binding(get: { engine.filter1On }, set: { engine.setFilter1On($0) }),
                    cutoff: Binding(get: { (engine.filterCutoff - 8) / 128 },
                                    set: { engine.setFilterCutoff($0 * 128 + 8) }),
                    resonance: Binding(get: { engine.filterResonance }, set: { engine.setFilterResonance($0) }),
                    drive: Binding(get: { engine.filterDrive }, set: { engine.setFilterDrive($0) }),
                    model: Binding(get: { engine.filterModel }, set: { engine.setFilterModel($0) }),
                    blend: Binding(get: { engine.filter1Blend }, set: { engine.setFilter1Blend($0) }),
                    keytrack: Binding(get: { engine.filter1Keytrack }, set: { engine.setFilter1Keytrack($0) })
                )
                FilterSection(
                    filterNumber: 2, accentColor: VitalColors.warmOrange,
                    isOn: Binding(get: { engine.filter2On }, set: { engine.setFilter2On($0) }),
                    cutoff: Binding(get: { (engine.filter2Cutoff - 8) / 128 },
                                    set: { engine.setFilter2Cutoff($0 * 128 + 8) }),
                    resonance: Binding(get: { engine.filter2Resonance }, set: { engine.setFilter2Resonance($0) }),
                    drive: Binding(get: { engine.filter2Drive }, set: { engine.setFilter2Drive($0) }),
                    model: Binding(get: { engine.filter2Model }, set: { engine.setFilter2Model($0) }),
                    blend: Binding(get: { engine.filter2Blend }, set: { engine.setFilter2Blend($0) }),
                    keytrack: Binding(get: { engine.filter2Keytrack }, set: { engine.setFilter2Keytrack($0) })
                )
            }
        }
    }

    private func oscSection(_ n: Int) -> some View {
        switch n {
        case 2:
            return AnyView(OscillatorSection(
                title: "OSC 2",
                isOn: Binding(get: { engine.osc2On }, set: { engine.setOsc2On($0) }),
                waveform: Binding(get: { engine.osc2WaveForm }, set: { engine.setOsc2Waveform($0) }),
                waveFrame: Binding(get: { engine.osc2WaveFrame }, set: { engine.setOsc2WaveFrame($0) }),
                level: Binding(get: { engine.osc2Level }, set: { engine.setOsc2Level($0) }),
                pan: Binding(get: { engine.osc2Pan }, set: { engine.setOsc2Pan($0) }),
                transpose: Binding(get: { (engine.osc2Transpose + 48) / 96 },
                                   set: { engine.setOsc2Transpose($0 * 96 - 48) }),
                destination: Binding(get: { engine.osc2Destination }, set: { engine.setOsc2Destination($0) }),
                unisonVoices: Binding(get: { engine.osc2UnisonVoices }, set: { engine.setOsc2UnisonVoices($0) }),
                unisonDetune: Binding(get: { engine.osc2UnisonDetune }, set: { engine.setOsc2UnisonDetune($0) }),
                phase: Binding(get: { engine.osc2Phase }, set: { engine.setOsc2Phase($0) }),
                spectralMorphType: Binding(get: { engine.osc2SpectralMorphType }, set: { engine.setOsc2SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { engine.osc2SpectralMorphAmount }, set: { engine.setOsc2SpectralMorphAmount($0) }),
                distortionType: Binding(get: { engine.osc2DistortionType }, set: { engine.setOsc2DistortionType($0) }),
                distortionAmount: Binding(get: { engine.osc2DistortionAmount }, set: { engine.setOsc2DistortionAmount($0) }),
                displayFrames: engine.osc2DisplayFrames,
                wavetableName: engine.osc2WavetableName,
                onWavetableLoaded: { engine.loadWavetable(from: $0, oscillatorIndex: 1) },
                tuneValue: engine.oscTune[1],
                onTuneChanged: { engine.setOscTune(1, $0) },
                onEditWavetable: { editingOscillator = 1 }
            ))
        case 3:
            return AnyView(OscillatorSection(
                title: "OSC 3",
                isOn: Binding(get: { engine.osc3On }, set: { engine.setOsc3On($0) }),
                waveform: Binding(get: { engine.osc3WaveForm }, set: { engine.setOsc3Waveform($0) }),
                waveFrame: Binding(get: { engine.osc3WaveFrame }, set: { engine.setOsc3WaveFrame($0) }),
                level: Binding(get: { engine.osc3Level }, set: { engine.setOsc3Level($0) }),
                pan: Binding(get: { engine.osc3Pan }, set: { engine.setOsc3Pan($0) }),
                transpose: Binding(get: { (engine.osc3Transpose + 48) / 96 },
                                   set: { engine.setOsc3Transpose($0 * 96 - 48) }),
                destination: Binding(get: { engine.osc3Destination }, set: { engine.setOsc3Destination($0) }),
                unisonVoices: Binding(get: { engine.osc3UnisonVoices }, set: { engine.setOsc3UnisonVoices($0) }),
                unisonDetune: Binding(get: { engine.osc3UnisonDetune }, set: { engine.setOsc3UnisonDetune($0) }),
                phase: Binding(get: { engine.osc3Phase }, set: { engine.setOsc3Phase($0) }),
                spectralMorphType: Binding(get: { engine.osc3SpectralMorphType }, set: { engine.setOsc3SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { engine.osc3SpectralMorphAmount }, set: { engine.setOsc3SpectralMorphAmount($0) }),
                distortionType: Binding(get: { engine.osc3DistortionType }, set: { engine.setOsc3DistortionType($0) }),
                distortionAmount: Binding(get: { engine.osc3DistortionAmount }, set: { engine.setOsc3DistortionAmount($0) }),
                displayFrames: engine.osc3DisplayFrames,
                wavetableName: engine.osc3WavetableName,
                onWavetableLoaded: { engine.loadWavetable(from: $0, oscillatorIndex: 2) },
                tuneValue: engine.oscTune[2],
                onTuneChanged: { engine.setOscTune(2, $0) },
                onEditWavetable: { editingOscillator = 2 }
            ))
        default:
            return AnyView(OscillatorSection(
                title: "OSC 1",
                isOn: Binding(get: { engine.osc1On }, set: { engine.setOsc1On($0) }),
                waveform: Binding(get: { engine.osc1WaveForm }, set: { engine.setOsc1Waveform($0) }),
                waveFrame: Binding(get: { engine.osc1WaveFrame }, set: { engine.setOsc1WaveFrame($0) }),
                level: Binding(get: { engine.osc1Level }, set: { engine.setOsc1Level($0) }),
                pan: Binding(get: { engine.osc1Pan }, set: { engine.setOsc1Pan($0) }),
                transpose: Binding(get: { (engine.osc1Transpose + 48) / 96 },
                                   set: { engine.setOsc1Transpose($0 * 96 - 48) }),
                destination: Binding(get: { engine.osc1Destination }, set: { engine.setOsc1Destination($0) }),
                unisonVoices: Binding(get: { engine.osc1UnisonVoices }, set: { engine.setOsc1UnisonVoices($0) }),
                unisonDetune: Binding(get: { engine.osc1UnisonDetune }, set: { engine.setOsc1UnisonDetune($0) }),
                phase: Binding(get: { engine.osc1Phase }, set: { engine.setOsc1Phase($0) }),
                spectralMorphType: Binding(get: { engine.osc1SpectralMorphType }, set: { engine.setOsc1SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { engine.osc1SpectralMorphAmount }, set: { engine.setOsc1SpectralMorphAmount($0) }),
                distortionType: Binding(get: { engine.osc1DistortionType }, set: { engine.setOsc1DistortionType($0) }),
                distortionAmount: Binding(get: { engine.osc1DistortionAmount }, set: { engine.setOsc1DistortionAmount($0) }),
                displayFrames: engine.osc1DisplayFrames,
                wavetableName: engine.osc1WavetableName,
                onWavetableLoaded: { engine.loadWavetable(from: $0, oscillatorIndex: 0) },
                tuneValue: engine.oscTune[0],
                onTuneChanged: { engine.setOscTune(0, $0) },
                onEditWavetable: { editingOscillator = 0 }
            ))
        }
    }

    // MARK: EFFECTS

    private var effectsTab: some View {
        effectsStack
    }

    /// Existing effects UI + the extra tempo / frequency / distortion-filter panel.
    private var effectsStack: some View {
        VStack(spacing: 5) {
            EffectsInterfaceView(engine: engine)
            EffectsExtraPanel(engine: engine)
        }
    }

    private var keyboardHandle: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(VitalColors.accentDim.opacity(0.28))
                .frame(width: 28, height: 3)
            Spacer()
        }
        .frame(height: 10)
        .background(VitalColors.headerBg)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .updating($kbDrag) { v, s, _ in s = v.translation.height }
                .onEnded { v in
                    keyboardHeight = max(40, min(110, keyboardHeight - v.translation.height))
                }
        )
    }
}

// MARK: - Extra FX panel (tempo / frequency / distortion filter)

struct EffectsExtraPanel: View {
    @ObservedObject var engine: VitalAudioEngine

    var body: some View {
        sectionChrome {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    delayBlock
                    Divider().background(Color.white.opacity(0.08))
                    modulationFxBlock
                    Divider().background(Color.white.opacity(0.08))
                    distortionFilterBlock
                }
            }
        }
    }

    private func header(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold)).tracking(1.0)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(VitalColors.bodyHeading)
    }

    private var delayBlock: some View {
        VStack(spacing: 0) {
            header("DELAY TEMPO", color: VitalColors.fxDelay)
            VStack(spacing: 6) {
                tempoStepper(label: "MAIN", names: VitalAudioEngine.tempoNames,
                             value: engine.delayTempo, color: VitalColors.fxDelay) {
                    engine.setDelayTempo($0)
                }
                tempoStepper(label: "AUX", names: VitalAudioEngine.tempoNames,
                             value: engine.delayAuxTempo, color: VitalColors.fxDelay) {
                    engine.setDelayAuxTempo($0)
                }
            }
            .padding(8)
        }
        .frame(width: 150)
    }

    private var modulationFxBlock: some View {
        VStack(spacing: 0) {
            header("FLANGER / PHASER", color: VitalColors.fxFlanger)
            HStack(spacing: 14) {
                VitalKnob(label: "FLG FREQ", value: Binding(
                    get: { engine.flangerFrequency }, set: { engine.setFlangerFrequency($0) }
                ), size: 34, color: VitalColors.fxFlanger)
                VitalKnob(label: "PHS FREQ", value: Binding(
                    get: { engine.phaserFrequency }, set: { engine.setPhaserFrequency($0) }
                ), size: 34, color: VitalColors.fxPhaser)
            }
            .padding(8)
        }
        .frame(width: 140)
    }

    private var distortionFilterBlock: some View {
        VStack(spacing: 0) {
            header("DISTORTION FILTER", color: VitalColors.fxDistortion)
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    ForEach(Array(VitalAudioEngine.distortionFilterOrderNames.enumerated()), id: \.offset) { idx, name in
                        Button { engine.setDistortionFilterOrder(idx) } label: {
                            Text(name)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(engine.distortionFilterOrder == idx ? .black : VitalColors.labelText)
                                .frame(width: 38, height: 18)
                                .background(engine.distortionFilterOrder == idx ? VitalColors.fxDistortion : VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                    }
                }
                VitalKnob(label: "CUTOFF", value: Binding(
                    get: { engine.distortionFilterCutoff }, set: { engine.setDistortionFilterCutoff($0) }
                ), size: 34, color: VitalColors.fxDistortion)
                VitalKnob(label: "RES", value: Binding(
                    get: { engine.distortionFilterResonance }, set: { engine.setDistortionFilterResonance($0) }
                ), size: 34, color: VitalColors.fxDistortion)
                VitalKnob(label: "BLEND", value: Binding(
                    get: { engine.distortionFilterBlend }, set: { engine.setDistortionFilterBlend($0) }
                ), size: 34, color: VitalColors.fxDistortion)
            }
            .padding(8)
            .opacity(engine.distortionFilterOrder == 0 ? 0.55 : 1)
        }
        .frame(width: 260)
    }
}

// MARK: - Pitch / Mod Wheel

struct WheelControl: View {
    let label: String
    @Binding var value: Float
    var springReturn: Bool = false
    var color: Color = VitalColors.accent

    @State private var dragStart: Float = 0.5

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7, weight: .bold)).tracking(0.5)
                .foregroundColor(VitalColors.labelText)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.06))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1))

                GeometryReader { g in
                    let w = g.size.width, h = g.size.height
                    let ridgeSpacing: CGFloat = 7
                    let shift = CGFloat(value) * ridgeSpacing * 2

                    ZStack {
                        LinearGradient(
                            colors: [Color(white: 0.10), Color(white: 0.32), Color(white: 0.22), Color(white: 0.10)],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(.horizontal, 4)

                        Canvas { ctx, size in
                            let totalStripes = Int(size.height / ridgeSpacing) + 4
                            let offset = shift.truncatingRemainder(dividingBy: ridgeSpacing)
                            for i in 0...totalStripes {
                                let y = CGFloat(i) * ridgeSpacing - offset
                                if y < 0 || y > size.height { continue }
                                var p = Path()
                                p.move(to: CGPoint(x: 6, y: y))
                                p.addLine(to: CGPoint(x: size.width - 6, y: y))
                                ctx.stroke(p, with: .color(Color.white.opacity(0.10)), lineWidth: 1)
                            }
                        }
                        .padding(.horizontal, 4)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(color.opacity(0.30))
                                .frame(width: w - 8, height: max(2, h * CGFloat(value)))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                        Capsule()
                            .fill(color.opacity(0.90))
                            .shadow(color: color.opacity(0.55), radius: 3)
                            .frame(width: w - 8, height: 8)
                            .offset(y: (0.5 - CGFloat(value)) * (h - 16))
                    }
                    .frame(width: w, height: h)
                }
                .padding(4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let delta = Float(-g.translation.height / 160)
                        value = max(0, min(1, dragStart + delta))
                    }
                    .onEnded { _ in
                        if springReturn {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                value = 0.5
                            }
                        }
                        dragStart = value
                    }
            )
            .onAppear { dragStart = value }
        }
    }
}

// MARK: - Piano Keyboard

struct VitalKeyboardView: View {
    @ObservedObject var engine: VitalAudioEngine

    @State private var activeNotes: Set<Int> = []
    @State private var octaveShift: Int = 0

    private let baseLowest  = 48
    private let baseHighest = 72

    private var lowestNote:  Int { baseLowest  + octaveShift * 12 }
    private var highestNote: Int { baseHighest + octaveShift * 12 }

    private var whiteNotes: [Int] {
        (lowestNote...highestNote).filter { [0,2,4,5,7,9,11].contains($0 % 12) }
    }
    private var blackNotes: [Int] {
        (lowestNote...highestNote).filter { [1,3,6,8,10].contains($0 % 12) }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Compact octave strip (wheels moved to left macro column)
            VStack(spacing: 2) {
                Button {
                    if octaveShift < 2 {
                        engine.allNotesOff(); activeNotes.removeAll()
                        octaveShift += 1
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(octaveShift < 2 ? VitalColors.accent : VitalColors.labelText)
                        .frame(width: 28, height: 18)
                        .background(VitalColors.bodyHeading).cornerRadius(2)
                }.buttonStyle(.plain)

                Text("C\(lowestNote / 12 - 1)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(VitalColors.bodyText)

                Button {
                    if octaveShift > -2 {
                        engine.allNotesOff(); activeNotes.removeAll()
                        octaveShift -= 1
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(octaveShift > -2 ? VitalColors.accent : VitalColors.labelText)
                        .frame(width: 28, height: 18)
                        .background(VitalColors.bodyHeading).cornerRadius(2)
                }.buttonStyle(.plain)
            }
            .frame(width: 40)
            .frame(maxHeight: .infinity)
            .background(VitalColors.headerBg)

            GeometryReader { geo in
                let w  = geo.size.width
                let h  = geo.size.height
                let ww = w / CGFloat(max(whiteNotes.count, 1))
                let bw = ww * 0.58
                let bh = h * 0.58

                ZStack(alignment: .topLeading) {
                    VitalColors.widgetBg
                    HStack(spacing: 1) {
                        ForEach(whiteNotes, id: \.self) { note in
                            whiteKey(note: note, width: ww - 1, height: h)
                        }
                    }
                    ForEach(blackNotes, id: \.self) { note in
                        blackKey(note: note,
                                 x: blackX(note, ww: ww, bw: bw),
                                 width: bw, height: bh)
                    }
                }
            }
        }
        .background(VitalColors.headerBg)
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(VitalColors.panelEdge), alignment: .top)
    }

    private func whiteKey(note: Int, width: CGFloat, height: CGFloat) -> some View {
        let pressed = activeNotes.contains(note)
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: pressed
                        ? [Color(white: 0.72), Color(white: 0.82), Color(white: 0.78)]
                        : [Color(white: 0.97), Color(white: 0.91), Color(white: 0.84)],
                    startPoint: .top, endPoint: .bottom
                ))
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(pressed ? 0.0 : 0.55))
                .frame(height: 3)
            VStack {
                Spacer()
                Rectangle().fill(Color.black.opacity(0.18)).frame(height: 5).cornerRadius(2)
            }
            HStack {
                Rectangle().fill(Color.black.opacity(0.15)).frame(width: 1)
                Spacer()
            }
            if pressed {
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(VitalColors.accent.opacity(0.45))
                        .frame(height: height * 0.22)
                }
            }
        }
        .frame(width: width, height: height)
        .scaleEffect(CGSize(width: 1, height: pressed ? 0.97 : 1.0), anchor: .top)
        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !activeNotes.contains(note) {
                        activeNotes.insert(note)
                        engine.noteOn(note: note, velocity: 0.78)
                    }
                }
                .onEnded { _ in
                    activeNotes.remove(note)
                    engine.noteOff(note: note)
                }
        )
        .animation(.easeOut(duration: 0.06), value: pressed)
    }

    private func blackKey(note: Int, x: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let pressed = activeNotes.contains(note)
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: pressed
                        ? [Color(white: 0.35), Color(white: 0.12)]
                        : [Color(white: 0.28), Color(white: 0.06)],
                    startPoint: .top, endPoint: .bottom
                ))
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(pressed ? 0.04 : 0.18))
                    .frame(width: 2).cornerRadius(1)
                Spacer()
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(pressed ? 0.0 : 0.12))
                .frame(height: 4)
            VStack {
                Spacer()
                Rectangle().fill(Color.black.opacity(0.5)).frame(height: 3).cornerRadius(2)
            }
            if pressed {
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(VitalColors.accent.opacity(0.55))
                        .frame(height: height * 0.25)
                }
            }
        }
        .frame(width: width, height: height)
        .offset(x: x)
        .scaleEffect(CGSize(width: 1, height: pressed ? 0.96 : 1.0), anchor: .top)
        .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 3)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !activeNotes.contains(note) {
                        activeNotes.insert(note)
                        engine.noteOn(note: note, velocity: 0.82)
                    }
                }
                .onEnded { _ in
                    activeNotes.remove(note)
                    engine.noteOff(note: note)
                }
        )
        .animation(.easeOut(duration: 0.06), value: pressed)
    }

    private func blackX(_ note: Int, ww: CGFloat, bw: CGFloat) -> CGFloat {
        let semitone = note % 12
        let octaveIdx = (note - lowestNote) / 12
        let posMap: [Int: Int] = [1:0, 3:1, 6:2, 8:3, 10:4]
        let pos = posMap[semitone] ?? 0
        let wBeforeBlack = [0, 1, 3, 4, 5]
        let wIdx = octaveIdx * 7 + wBeforeBlack[pos]
        return CGFloat(wIdx) * (ww + 1) + (ww + 1) * 0.5 - bw * 0.5
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
