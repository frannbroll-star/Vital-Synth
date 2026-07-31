//
//  VitalAUComponents.swift
//  VitalAU
//
//  AUv3 GUI widgets matching Vital desktop FullInterface layout.
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
    var onTuneChanged: ((Float) -> Void)? = nil
    var onEditWavetable: (() -> Void)? = nil

    @State private var tune: Float = 0.5
    @State private var transStartVal: Float = 0
    @State private var showWavetablePicker = false
    @State private var isDropTargeted = false
    @State private var dropStatus: String? = nil

    private var semitones: Int { Int((transpose * 96 - 48).rounded()) }

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
                get: { tune },
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

            typeBrowser(names: distortionTypeNames, selected: $distortionType, color: VitalColors.warmOrange)
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
                .minimumScaleFactor(0.7)
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
    @ObservedObject var engine: VitalAUViewModel

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
    @ObservedObject var engine: VitalAUViewModel
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

    private func envStages(_ i: Int) -> (
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
                    AULfoShapeView(viewModel: engine, lfoIndex: lfoTab, color: VitalColors.modTeal,
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
                            AULfoShapeClipboard.data = engine.lfoStateJSON(index: lfoTab)
                        } label: {
                            Text("CPY")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(VitalColors.labelText)
                                .padding(.horizontal, 4).padding(.vertical, 3)
                                .background(VitalColors.bodyHeading)
                                .cornerRadius(2)
                        }.buttonStyle(.plain)
                        Button {
                            guard let data = AULfoShapeClipboard.data else { return }
                            _ = engine.setLfoStateJSON(index: lfoTab, data: data)
                            lfoSmoothOn = engine.lfoSmooth(index: lfoTab)
                            lfoShapeToken += 1
                        } label: {
                            Text("PST")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(AULfoShapeClipboard.data == nil ? VitalColors.labelText.opacity(0.4) : VitalColors.labelText)
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(VitalAUViewModel.lfoTargetNames.enumerated()), id: \.offset) { idx, name in
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

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - FX effect row

// MARK: - Matrix tab

struct MatrixTab: View {
    @ObservedObject var engine: VitalAUViewModel
    var body: some View { AUMatrixInterfaceView(engine: engine) }
}

// MARK: - Advanced tab

struct AdvancedTab: View {
    @ObservedObject var engine: VitalAUViewModel

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

                        VStack(spacing: 2) {
                            Text("OVERSAMPLE")
                                .font(.system(size: 8)).foregroundColor(VitalColors.labelText)
                            Text("1×")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(VitalColors.accentDim)
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
        sectionChrome {
            VStack(spacing: 0) {
                Text("OSC \(n) ADVANCED")
                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                    .foregroundColor(VitalColors.bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(VitalColors.bodyHeading)
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
                    Spacer()
                }
                .padding(12)
            }
        }
    }
}


// MARK: - Modulation connection model

struct ModConnection: Identifiable, Equatable {
    let id = UUID()
    var source: String
    var destination: String
    var amount: Float
    var bipolar: Bool = false
    var stereo: Bool = false
    var bypass: Bool = false
    var power: Float = 0
    var index: Int = 0
}

// MARK: - Preset Model

// MARK: - Imported Preset (mirrors VitalbankImporter in standalone target)

struct ImportedPreset: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let bankName: String
    let relativePath: String   // relative to importedPresetsDirectory

    init(name: String, bankName: String, relativePath: String) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.relativePath = relativePath
    }

    var url: URL {
        AUVitalbankImporter.importedPresetsDirectory.appendingPathComponent(relativePath)
    }
}

enum AUVitalbankImporter {

    static var importedPresetsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("ImportedPresets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func importBank(from bankURL: URL) throws -> [ImportedPreset] {
        let bankName = bankURL.deletingPathExtension().lastPathComponent
        let bankDir  = importedPresetsDirectory.appendingPathComponent(bankName, isDirectory: true)
        let tmpDir   = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let extracted = try ZipExtractor.extractZip(bankURL, toDirectory: tmpDir, fileExtension: "vital")
        guard !extracted.isEmpty else {
            throw NSError(domain: "AUVitalbankImporter", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No .vital presets found in this bank"])
        }
        try FileManager.default.createDirectory(at: bankDir, withIntermediateDirectories: true)
        var imported: [ImportedPreset] = []
        for srcURL in extracted {
            let destURL = bankDir.appendingPathComponent(srcURL.lastPathComponent)
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            imported.append(ImportedPreset(
                name: srcURL.deletingPathExtension().lastPathComponent,
                bankName: bankName,
                relativePath: "\(bankName)/\(srcURL.lastPathComponent)"))
        }
        return imported.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func importFolder(from folderURL: URL) throws -> [ImportedPreset] {
        let fm         = FileManager.default
        let folderName = folderURL.lastPathComponent
        var results:          [ImportedPreset] = []
        var processedPackDirs = Set<String>()
        guard let enumerator = fm.enumerator(at: folderURL,
                                              includingPropertiesForKeys: [.isDirectoryKey],
                                              options: .skipsHiddenFiles) else {
            throw NSError(domain: "AUVitalbankImporter", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read folder"])
        }
        for case let item as URL in enumerator {
            guard item.pathExtension.lowercased() == "vital" else { continue }
            let parentDir  = item.deletingLastPathComponent()
            let parentName = parentDir.lastPathComponent
            let bankName: String
            let packDir:  URL
            if parentName.localizedCaseInsensitiveCompare("Presets") == .orderedSame {
                let gp = parentDir.deletingLastPathComponent()
                bankName = gp.lastPathComponent == folderName ? folderName : gp.lastPathComponent
                packDir  = gp
            } else {
                bankName = parentName == folderName ? folderName : parentName
                packDir  = parentDir
            }
            if !processedPackDirs.contains(packDir.path) {
                processedPackDirs.insert(packDir.path)
                copyAuxFolders(from: packDir, toBankNamed: bankName, fm: fm)
            }
            let bankDir = importedPresetsDirectory.appendingPathComponent(bankName, isDirectory: true)
            try fm.createDirectory(at: bankDir, withIntermediateDirectories: true)
            let dest = bankDir.appendingPathComponent(item.lastPathComponent)
            try? fm.removeItem(at: dest)
            try fm.copyItem(at: item, to: dest)
            results.append(ImportedPreset(
                name: item.deletingPathExtension().lastPathComponent,
                bankName: bankName,
                relativePath: "\(bankName)/\(item.lastPathComponent)"))
        }
        guard !results.isEmpty else {
            throw NSError(domain: "AUVitalbankImporter", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "No .vital presets found in folder"])
        }
        return results.sorted {
            $0.bankName == $1.bankName
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.bankName.localizedCaseInsensitiveCompare($1.bankName) == .orderedAscending
        }
    }

    private static func copyAuxFolders(from packDir: URL, toBankNamed bankName: String,
                                       fm: FileManager) {
        for subfolder in ["Wavetables", "Samples"] {
            let src = packDir.appendingPathComponent(subfolder)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: src.path, isDirectory: &isDir), isDir.boolValue else { continue }
            let dest = importedPresetsDirectory
                .appendingPathComponent(bankName)
                .appendingPathComponent(subfolder)
            try? fm.createDirectory(at: dest, withIntermediateDirectories: true)
            let items = (try? fm.contentsOfDirectory(at: src,
                                                     includingPropertiesForKeys: nil,
                                                     options: .skipsHiddenFiles)) ?? []
            for file in items {
                let fileDest = dest.appendingPathComponent(file.lastPathComponent)
                try? fm.removeItem(at: fileDest)
                try? fm.copyItem(at: file, to: fileDest)
            }
        }
    }
}

// MARK: - Navigation entry (custom preset or imported .vital)

enum AUNavEntry {
    case custom(VitalPreset)
    case imported(ImportedPreset)
    var name: String {
        switch self {
        case .custom(let p):   return p.name
        case .imported(let p): return p.name
        }
    }
}

// MARK: -

struct VitalPreset: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: String = "Custom"

    // Oscillators
    var osc1On: Bool = true;     var osc1Level: Float = 1.0;   var osc1Pan: Float = 0.5
    var osc1Transpose: Float = 0; var osc1WaveForm: Int = 0

    var osc2On: Bool = false;    var osc2Level: Float = 0.0;   var osc2Pan: Float = 0.5
    var osc2Transpose: Float = 0; var osc2WaveForm: Int = 0

    var osc3On: Bool = false;    var osc3Level: Float = 0.0;   var osc3Pan: Float = 0.5
    var osc3Transpose: Float = 0; var osc3WaveForm: Int = 0

    // Filter 1
    var filterCutoff: Float = 100; var filterResonance: Float = 0.5
    var filterDrive: Float = 0;    var filterModel: Int = 0

    // Filter 2
    var filter2On: Bool = false
    var filter2Cutoff: Float = 100; var filter2Resonance: Float = 0.5
    var filter2Drive: Float = 0;    var filter2Model: Int = 0

    // OSC → filter routing (0=F1, 1=F2, 2=Both)
    var osc1FilterRoute: Int = 0
    var osc2FilterRoute: Int = 0
    var osc3FilterRoute: Int = 0

    // Envelopes
    var env1Attack: Float = 0.003; var env1Decay: Float = 0.25
    var env1Sustain: Float = 0.70; var env1Release: Float = 0.40

    var env2Attack: Float = 0.003; var env2Decay: Float = 0.40
    var env2Sustain: Float = 0.0;  var env2Release: Float = 0.30

    // LFO
    var lfo1Rate: Float = 0.25
    var lfo1Amount: Float = 0.0
    var lfo1Target: Int = 0

    // FX
    var reverbMix: Float = 0.0;  var delayMix: Float = 0.0
    var chorusMix: Float = 0.0;  var distortionMix: Float = 0.0

    // Voice
    var legato: Bool  = false
    var glide:  Float = 0.0

    // Master
    var masterVolume: Float = 0.8601
}

// MARK: - Preset Styles

enum PresetStyle: String, CaseIterable, Identifiable {
    case pad = "Pad"
    case lead = "Lead"
    case bass = "Bass"
    case pluck = "Pluck"
    case keys = "Keys"
    case ambient = "Ambient"
    case arp = "Arp"
    case brass = "Brass"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .pad:     return "🌊"
        case .lead:    return "🎵"
        case .bass:    return "🔊"
        case .pluck:   return "✨"
        case .keys:    return "🎹"
        case .ambient: return "🌌"
        case .arp:     return "⚡️"
        case .brass:   return "🎺"
        }
    }
}

// MARK: - Preset Manager

@MainActor
final class PresetManager: ObservableObject {
    @Published var presets: [VitalPreset] = []
    @Published var importedPresets: [ImportedPreset] = []

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vitalsynth_presets.json")
    }()

    private let importedStorageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vitalsynth_imported_index.json")
    }()

    init() { loadFromDisk(); loadImportedFromDisk() }

    func save(_ preset: VitalPreset) {
        if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[idx] = preset
        } else {
            presets.insert(preset, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persist()
    }

    func delete(_ preset: VitalPreset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }

    func exportData() -> Data? {
        try? JSONEncoder().encode(presets)
    }

    func importData(_ data: Data) {
        guard let decoded = try? JSONDecoder().decode([VitalPreset].self, from: data) else { return }
        for preset in decoded where !presets.contains(where: { $0.id == preset.id }) {
            presets.append(preset)
        }
        persist()
    }

    // MARK: Imported bank/folder presets

    var importedBankNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for p in importedPresets where seen.insert(p.bankName).inserted { names.append(p.bankName) }
        return names
    }

    func loadImportedFromDisk() {
        guard let data = try? Data(contentsOf: importedStorageURL),
              let decoded = try? JSONDecoder().decode([ImportedPreset].self, from: data)
        else { return }
        importedPresets = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }

    func persistImported() {
        if let data = try? JSONEncoder().encode(importedPresets) {
            try? data.write(to: importedStorageURL, options: .atomic)
        }
    }

    func importBank(from bankURL: URL) async throws -> Int {
        let newPresets = try await Task.detached(priority: .userInitiated) {
            try AUVitalbankImporter.importBank(from: bankURL)
        }.value
        let existing = Set(importedPresets.map(\.relativePath))
        let toAdd = newPresets.filter { !existing.contains($0.relativePath) }
        importedPresets.append(contentsOf: toAdd)
        persistImported()
        return toAdd.count
    }

    func importFolder(from folderURL: URL) async throws -> Int {
        let newPresets = try await Task.detached(priority: .userInitiated) {
            try AUVitalbankImporter.importFolder(from: folderURL)
        }.value
        let existing = Set(importedPresets.map(\.relativePath))
        let toAdd = newPresets.filter { !existing.contains($0.relativePath) }
        importedPresets.append(contentsOf: toAdd)
        persistImported()
        return toAdd.count
    }

    func deleteImported(_ preset: ImportedPreset) {
        importedPresets.removeAll { $0.id == preset.id }
        persistImported()
    }

    func randomPreset(style: PresetStyle) -> VitalPreset {
        var p = VitalPreset(name: randomName(), category: style.rawValue)
        configure(&p, style: style)
        return p
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(presets) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([VitalPreset].self, from: data)
        else { return }
        presets = decoded
    }

    private static let adjectives = [
        "Dark", "Bright", "Warm", "Cold", "Deep", "Shimmer", "Lush", "Raw",
        "Hollow", "Silky", "Punchy", "Dreamy", "Rich", "Airy", "Stark",
        "Glassy", "Velvety", "Hazy", "Crisp", "Distant"
    ]
    private static let nouns = [
        "Horizon", "Cascade", "Dusk", "Nova", "Vapor", "Drift", "Pulse",
        "Aurora", "Shadow", "Crystal", "Mist", "Storm", "Tide", "Echo",
        "Bloom", "Veil", "Ember", "Wave", "Current", "Prism"
    ]

    private func randomName() -> String {
        (Self.adjectives.randomElement() ?? "Deep") + " " + (Self.nouns.randomElement() ?? "Echo")
    }

    private func rnd(_ lo: Float, _ hi: Float) -> Float { Float.random(in: lo...hi) }
    private func pick<T>(_ items: [T]) -> T { items.randomElement()! }

    private func configure(_ p: inout VitalPreset, style: PresetStyle) {
        p.osc1On    = true
        p.osc1Level = rnd(0.7, 1.0)
        p.osc1Pan   = rnd(0.42, 0.58)
        p.masterVolume = 0.8601

        // New field defaults (overridden per style below)
        p.filter2On = false
        p.filter2Cutoff = 100; p.filter2Resonance = 0.5; p.filter2Drive = 0; p.filter2Model = 0
        p.osc1FilterRoute = 0; p.osc2FilterRoute = 0; p.osc3FilterRoute = 0
        p.lfo1Amount = 0.0; p.lfo1Target = 0

        switch style {
        case .pad:
            p.osc1WaveForm    = pick([0, 1, 2])
            p.osc2On          = true
            p.osc2Level       = rnd(0.4, 0.8)
            p.osc2Pan         = 1.0 - p.osc1Pan
            p.osc2Transpose   = rnd(-7, 7)
            p.osc2WaveForm    = pick([1, 2])
            p.filterCutoff    = rnd(80, 120)
            p.filterResonance = rnd(0.1, 0.35)
            p.env1Attack      = rnd(0.25, 0.80)
            p.env1Decay       = rnd(0.20, 0.60)
            p.env1Sustain     = rnd(0.55, 0.90)
            p.env1Release     = rnd(0.50, 1.0)
            p.reverbMix       = rnd(0.30, 0.65)
            p.chorusMix       = rnd(0.10, 0.40)
            p.filter2On       = Bool.random()
            if p.filter2On {
                p.osc2FilterRoute  = 1
                p.filter2Cutoff    = rnd(70, 110)
                p.filter2Resonance = rnd(0.0, 0.3)
            }
            p.lfo1Rate = rnd(0.05, 0.20); p.lfo1Target = 0; p.lfo1Amount = rnd(0.10, 0.30)
        case .lead:
            p.osc1WaveForm    = pick([0, 3])
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.0, 0.30)
            p.osc2Transpose   = Float(pick([0, 7, 12]))
            p.filterCutoff    = rnd(70, 110)
            p.filterResonance = rnd(0.25, 0.55)
            p.filterDrive     = rnd(0.0, 0.3)
            p.env1Attack      = rnd(0.001, 0.03)
            p.env1Decay       = rnd(0.10, 0.40)
            p.env1Sustain     = rnd(0.35, 0.75)
            p.env1Release     = rnd(0.10, 0.40)
            p.distortionMix   = rnd(0.0, 0.2)
            p.lfo1Rate = rnd(0.15, 0.50); p.lfo1Target = 0; p.lfo1Amount = rnd(0.10, 0.35)
        case .bass:
            p.osc1WaveForm    = pick([0, 3])
            p.osc1Transpose   = Float(pick([-24, -12, -12]))
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.0, 0.5)
            p.osc2Transpose   = p.osc1Transpose + Float(pick([0, 12]))
            p.osc2WaveForm    = pick([0, 3])
            p.filterCutoff    = rnd(30, 75)
            p.filterResonance = rnd(0.25, 0.65)
            p.filterDrive     = rnd(0.0, 0.4)
            p.env1Attack      = rnd(0.001, 0.01)
            p.env1Decay       = rnd(0.10, 0.35)
            p.env1Sustain     = rnd(0.0, 0.40)
            p.env1Release     = rnd(0.05, 0.25)
            p.distortionMix   = rnd(0.0, 0.35)
            p.filter2On = Bool.random()
            if p.filter2On && p.osc2On {
                p.osc2FilterRoute  = 1
                p.filter2Cutoff    = rnd(60, 90)
                p.filter2Resonance = rnd(0.1, 0.4)
            }
            p.lfo1Rate = rnd(0.25, 1.0); p.lfo1Target = 4; p.lfo1Amount = rnd(0.0, 0.15)
        case .pluck:
            p.osc1WaveForm    = pick([0, 1, 2])
            p.filterCutoff    = rnd(60, 100)
            p.filterResonance = rnd(0.1, 0.4)
            p.env1Attack      = 0.001
            p.env1Decay       = rnd(0.08, 0.35)
            p.env1Sustain     = 0.0
            p.env1Release     = rnd(0.05, 0.25)
            p.reverbMix       = rnd(0.0, 0.3)
            p.delayMix        = rnd(0.0, 0.25)
            p.lfo1Rate = rnd(0.10, 0.30); p.lfo1Target = 0; p.lfo1Amount = rnd(0.0, 0.10)
        case .keys:
            p.osc1WaveForm    = pick([0, 1, 2, 3])
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.0, 0.4)
            p.osc2Transpose   = Float(pick([0, 12]))
            p.filterCutoff    = rnd(80, 115)
            p.filterResonance = rnd(0.1, 0.4)
            p.env1Attack      = rnd(0.001, 0.05)
            p.env1Decay       = rnd(0.20, 0.80)
            p.env1Sustain     = rnd(0.40, 0.70)
            p.env1Release     = rnd(0.30, 0.80)
            p.reverbMix       = rnd(0.0, 0.25)
            p.filter2On = Bool.random()
            if p.filter2On {
                p.filter2Cutoff    = rnd(85, 120)
                p.filter2Resonance = rnd(0.0, 0.25)
            }
            p.lfo1Rate = rnd(0.10, 0.30); p.lfo1Target = 0; p.lfo1Amount = rnd(0.0, 0.20)
        case .ambient:
            p.osc1WaveForm    = pick([1, 2])
            p.osc2On          = true
            p.osc2Level       = rnd(0.5, 0.9)
            p.osc2Pan         = 1.0 - p.osc1Pan
            p.osc2Transpose   = rnd(-5, 5)
            p.osc2WaveForm    = pick([1, 2])
            p.osc3On          = Bool.random()
            p.osc3Level       = rnd(0.2, 0.6)
            p.osc3Transpose   = rnd(-7, 7)
            p.filterCutoff    = rnd(85, 125)
            p.filterResonance = rnd(0.0, 0.25)
            p.env1Attack      = rnd(0.50, 1.0)
            p.env1Decay       = rnd(0.40, 0.90)
            p.env1Sustain     = rnd(0.65, 1.0)
            p.env1Release     = rnd(0.60, 1.0)
            p.reverbMix       = rnd(0.50, 0.85)
            p.chorusMix       = rnd(0.20, 0.55)
            p.delayMix        = rnd(0.0, 0.35)
            p.filter2On       = true
            p.osc1FilterRoute = 0; p.osc2FilterRoute = 1
            p.osc3FilterRoute = p.osc3On ? 2 : 0
            p.filter2Cutoff   = rnd(80, 120); p.filter2Resonance = rnd(0.0, 0.20)
            p.lfo1Rate = rnd(0.03, 0.12); p.lfo1Target = pick([0, 1]); p.lfo1Amount = rnd(0.20, 0.50)
        case .arp:
            p.osc1WaveForm    = pick([0, 3])
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.0, 0.5)
            p.osc2Transpose   = Float(pick([7, 12, 24]))
            p.filterCutoff    = rnd(60, 100)
            p.filterResonance = rnd(0.30, 0.65)
            p.env1Attack      = 0.001
            p.env1Decay       = rnd(0.05, 0.20)
            p.env1Sustain     = rnd(0.0, 0.40)
            p.env1Release     = rnd(0.05, 0.20)
            p.delayMix        = rnd(0.20, 0.55)
            p.lfo1Rate = rnd(0.25, 0.80); p.lfo1Target = 0; p.lfo1Amount = rnd(0.25, 0.50)
        case .brass:
            p.osc1WaveForm    = 0
            p.osc2On          = true
            p.osc2Level       = rnd(0.4, 0.8)
            p.osc2Transpose   = rnd(-2, 2)
            p.osc2WaveForm    = 0
            p.filterCutoff    = rnd(85, 118)
            p.filterResonance = rnd(0.20, 0.50)
            p.filterDrive     = rnd(0.1, 0.5)
            p.env1Attack      = rnd(0.03, 0.15)
            p.env1Decay       = rnd(0.10, 0.35)
            p.env1Sustain     = rnd(0.60, 0.85)
            p.env1Release     = rnd(0.10, 0.40)
            p.distortionMix   = rnd(0.0, 0.25)
            p.lfo1Rate = rnd(0.30, 0.70); p.lfo1Target = 4; p.lfo1Amount = rnd(0.0, 0.15)
        }
    }
}

// MARK: - FileDocument for preset export

struct PresetExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(_ data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Save Preset Sheet (iOS 14-compatible TextField dialog)

struct SavePresetSheet: View {
    @Binding var name: String
    @Binding var category: String
    let onSave: (String, String) -> Void
    @Environment(\.presentationMode) private var presentationMode

    private let categories = PresetStyle.allCases.map(\.rawValue) + ["Custom"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Name")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            let emoji = PresetStyle(rawValue: cat)?.emoji ?? "🎵"
                            Text("\(emoji)  \(cat)").tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(VitalColors.labelText),
                trailing: Button("Save") {
                    onSave(name, category)
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(VitalColors.accent)
            )
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preset Sheet (works with VitalAUViewModel)

struct PresetSheet: View {
    @ObservedObject var manager: PresetManager
    @ObservedObject var viewModel: VitalAUViewModel
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedTab    = 0
    @State private var selectedStyle: PresetStyle = .pad
    @State private var saveNameText   = ""
    @State private var saveCategory   = "Custom"
    @State private var showSaveSheet  = false
    @State private var showImport     = false
    @State private var showExport     = false
    @State private var exportDoc      = PresetExportDocument()
    @State private var previewNotes: Set<Int> = []
    @State private var bankImportResult: String? = nil

    private let previewChord = [60, 64, 67]

    private var totalPresetCount: Int {
        manager.presets.count + manager.importedPresets.count
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("RANDOM").tag(0)
                    Text(totalPresetCount > 0 ? "SAVED (\(totalPresetCount))" : "SAVED").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(VitalColors.headerBg)

                if selectedTab == 0 {
                    randomTab
                } else {
                    savedTab
                }

                // ── Preview keyboard ─────────────────────────────────────────
                previewKeyboardStrip
            }
            .background(VitalColors.background.ignoresSafeArea())
            .navigationTitle(totalPresetCount > 0 ? "Presets (\(totalPresetCount))" : "Presets")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(VitalColors.accent)
            )
            .sheet(isPresented: $showSaveSheet) {
                SavePresetSheet(name: $saveNameText, category: $saveCategory) { name, cat in
                    var preset = viewModel.capturePreset(name: name.isEmpty ? viewModel.currentPatch : name)
                    preset.category = cat
                    manager.save(preset)
                }
            }
            .fileExporter(isPresented: $showExport, document: exportDoc,
                          contentType: .json, defaultFilename: "vital_presets") { _ in }
            .fileImporter(
                isPresented: $showImport,
                allowedContentTypes: [
                    .json,
                    UTType(filenameExtension: "vital",     conformingTo: .data) ?? .data,
                    UTType(filenameExtension: "vitalbank", conformingTo: .data) ?? .data,
                    .folder
                ],
                onCompletion: handleImport
            )
            .alert(isPresented: Binding(
                get: { bankImportResult != nil },
                set: { if !$0 { bankImportResult = nil } }
            )) {
                Alert(title: Text("Import Result"),
                      message: Text(bankImportResult ?? ""),
                      dismissButton: .default(Text("OK")) { bankImportResult = nil })
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private var randomTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 8
                ) {
                    ForEach(PresetStyle.allCases) { style in
                        Button { selectedStyle = style } label: {
                            VStack(spacing: 5) {
                                Text(style.emoji).font(.system(size: 24))
                                Text(style.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(selectedStyle == style
                                        ? .black : VitalColors.labelText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedStyle == style
                                ? VitalColors.accent : VitalColors.body)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Button {
                    viewModel.allNotesOff()
                    previewNotes.removeAll()
                    let preset = manager.randomPreset(style: selectedStyle)
                    viewModel.applyPreset(preset)
                    playPreviewChord()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "dice.fill")
                        Text("RANDOMIZE")
                            .font(.system(size: 14, weight: .black)).tracking(1.5)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(VitalColors.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .buttonStyle(.plain)

                Button {
                    saveNameText = viewModel.currentPatch
                    saveCategory = "Custom"
                    showSaveSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Current Patch")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(VitalColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(VitalColors.body)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(VitalColors.accent.opacity(0.35), lineWidth: 1))
                }
                .padding(.horizontal)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)
        }
    }

    private var savedTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    saveNameText = viewModel.currentPatch
                    saveCategory = "Custom"
                    showSaveSheet = true
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    if let data = manager.exportData() {
                        exportDoc = PresetExportDocument(data)
                        showExport = true
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)
                .disabled(manager.presets.isEmpty)

                Button { showImport = true } label: {
                    Label("Import", systemImage: "square.and.arrow.down.on.square")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.accent)
                }
                .buttonStyle(.plain)

                Button { showImport = true } label: {
                    Label("Bank", systemImage: "archivebox.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VitalColors.modTeal)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(VitalColors.bodyHeading)

            if manager.presets.isEmpty && manager.importedPresets.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 44))
                        .foregroundColor(VitalColors.labelText.opacity(0.5))
                    Text("No saved presets yet.\nRandomize something and save it,\nor import a .vitalbank file.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13))
                        .foregroundColor(VitalColors.labelText)
                }
                Spacer()
            } else {
                List {
                    ForEach(orderedCategories, id: \.self) { cat in
                        let inCat = manager.presets.filter { $0.category == cat }
                        if !inCat.isEmpty {
                            Section(header: categoryHeader(cat)) {
                                ForEach(inCat) { preset in
                                    presetRow(preset)
                                        .listRowBackground(VitalColors.body)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                        .contextMenu {
                                            Button(action: { manager.delete(preset) }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    ForEach(manager.importedBankNames, id: \.self) { bankName in
                        let inBank = manager.importedPresets.filter { $0.bankName == bankName }
                        if !inBank.isEmpty {
                            Section(header: importedBankHeader(bankName)) {
                                ForEach(inBank) { preset in
                                    importedPresetRow(preset)
                                        .listRowBackground(VitalColors.body)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                        .contextMenu {
                                            Button(action: { manager.deleteImported(preset) }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(VitalColors.background)
            }
        }
    }

    // MARK: - Category helpers

    private var orderedCategories: [String] {
        let defined = PresetStyle.allCases.map(\.rawValue) + ["Custom"]
        var seen = Set(defined)
        var extras: [String] = []
        for p in manager.presets where !seen.contains(p.category) {
            seen.insert(p.category); extras.append(p.category)
        }
        return defined + extras
    }

    private func categoryHeader(_ cat: String) -> some View {
        let emoji = PresetStyle(rawValue: cat)?.emoji ?? "🎵"
        let count = manager.presets.filter { $0.category == cat }.count
        return HStack(spacing: 6) {
            Text(emoji)
            Text(cat.uppercased())
                .font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundColor(VitalColors.labelText)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(VitalColors.labelText.opacity(0.7))
        }
        .textCase(nil)
    }

    private func importedBankHeader(_ name: String) -> some View {
        let count = manager.importedPresets.filter { $0.bankName == name }.count
        return HStack(spacing: 6) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 9))
                .foregroundColor(VitalColors.modTeal)
            Text(name.uppercased())
                .font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundColor(VitalColors.labelText)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(VitalColors.modTeal.opacity(0.8))
        }
        .textCase(nil)
    }

    private func importedPresetRow(_ preset: ImportedPreset) -> some View {
        Button {
            viewModel.allNotesOff()
            previewNotes.removeAll()
            viewModel.loadVitalPreset(from: preset.url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { playPreviewChord() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.modTeal)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(VitalColors.bodyText)
                    Text(preset.bankName)
                        .font(.system(size: 10))
                        .foregroundColor(VitalColors.labelText)
                }
                Spacer()
                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.modTeal.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // Tap to preview — no dismiss. Use "Done" to close.
    private func presetRow(_ preset: VitalPreset) -> some View {
        Button {
            viewModel.allNotesOff()
            previewNotes.removeAll()
            viewModel.applyPreset(preset)
            playPreviewChord()
        } label: {
            HStack(spacing: 12) {
                Text(PresetStyle(rawValue: preset.category)?.emoji ?? "🎵")
                    .font(.system(size: 20))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(VitalColors.bodyText)
                    Text(preset.category)
                        .font(.system(size: 10))
                        .foregroundColor(VitalColors.labelText)
                }

                Spacer()

                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(VitalColors.accent.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview keyboard strip

    private var previewKeyboardStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("PREVIEW")
                    .font(.system(size: 8, weight: .bold)).tracking(1.2)
                    .foregroundColor(VitalColors.labelText)
                Spacer()
                Button { playPreviewChord() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.system(size: 9))
                        Text("C maj").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(VitalColors.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(VitalColors.body)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(VitalColors.bodyHeading)

            GeometryReader { geo in
                let whites = [60, 62, 64, 65, 67, 69, 71]
                let blacks: [(midi: Int, lw: Int)] = [
                    (61, 0), (63, 1), (66, 3), (68, 4), (70, 5)
                ]
                let gap: CGFloat = 1
                let ww = (geo.size.width - CGFloat(whites.count + 1) * gap) / CGFloat(whites.count)
                let bw = ww * 0.58
                let bh = geo.size.height * 0.62

                ZStack(alignment: .topLeading) {
                    Color(white: 0.10)
                    HStack(spacing: gap) {
                        ForEach(whites, id: \.self) { midi in
                            previewWhiteKey(midi: midi, w: ww, h: geo.size.height)
                        }
                    }
                    .padding(.leading, gap)
                    ForEach(blacks, id: \.midi) { bk in
                        previewBlackKey(
                            midi: bk.midi,
                            x: gap + CGFloat(bk.lw) * (ww + gap) + ww * 0.60,
                            w: bw, h: bh)
                    }
                }
            }
        }
        .frame(height: 90)
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(Color.white.opacity(0.10)), alignment: .top)
    }

    private func previewWhiteKey(midi: Int, w: CGFloat, h: CGFloat) -> some View {
        let pressed = previewNotes.contains(midi)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    gradient: Gradient(stops: pressed
                        ? [.init(color: Color(red: 0.63, green: 0.53, blue: 1.0), location: 0),
                           .init(color: Color(red: 0.80, green: 0.72, blue: 1.0), location: 1)]
                        : [.init(color: Color(white: 0.90), location: 0),
                           .init(color: Color(white: 0.97), location: 0.4),
                           .init(color: Color(white: 0.84), location: 1)]),
                    startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(pressed ? 0.06 : 0.18))
                .frame(height: 4)
        }
        .frame(width: w, height: h)
        .scaleEffect(pressed
            ? CGSize(width: 0.97, height: 0.97)
            : CGSize(width: 1.0,  height: 1.0), anchor: .bottom)
        .animation(.easeOut(duration: 0.06), value: pressed)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !previewNotes.contains(midi) {
                    previewNotes.insert(midi)
                    viewModel.noteOn(note: Int32(midi), velocity: 0.75)
                }
            }
            .onEnded { _ in
                previewNotes.remove(midi)
                viewModel.noteOff(Int32(midi))
            })
    }

    private func previewBlackKey(midi: Int, x: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let pressed = previewNotes.contains(midi)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    gradient: Gradient(stops: pressed
                        ? [.init(color: Color(red: 0.50, green: 0.40, blue: 0.90), location: 0),
                           .init(color: Color(red: 0.22, green: 0.16, blue: 0.48), location: 1)]
                        : [.init(color: Color(white: 0.20), location: 0),
                           .init(color: Color(white: 0.06), location: 1)]),
                    startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(pressed ? 0.0 : 0.08))
                .frame(height: h * 0.28)
        }
        .frame(width: w, height: h)
        .scaleEffect(pressed
            ? CGSize(width: 0.96, height: 0.95)
            : CGSize(width: 1.0,  height: 1.0), anchor: .bottom)
        .animation(.easeOut(duration: 0.06), value: pressed)
        .offset(x: x)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !previewNotes.contains(midi) {
                    previewNotes.insert(midi)
                    viewModel.noteOn(note: Int32(midi), velocity: 0.80)
                }
            }
            .onEnded { _ in
                previewNotes.remove(midi)
                viewModel.noteOff(Int32(midi))
            })
    }

    // MARK: - Helpers

    private func playPreviewChord() {
        previewChord.forEach { viewModel.noteOn(note: Int32($0), velocity: 0.72) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            previewChord.forEach { viewModel.noteOff(Int32($0)) }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        let ext = url.pathExtension.lowercased()
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            // Folder of .vital presets
            Task {
                do {
                    let count = try await manager.importFolder(from: url)
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    bankImportResult = "Imported \(count) presets from folder."
                } catch {
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    bankImportResult = error.localizedDescription
                }
            }
        } else if ext == "vitalbank" {
            Task {
                do {
                    let count = try await manager.importBank(from: url)
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    bankImportResult = "Imported \(count) presets from bank."
                } catch {
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    bankImportResult = error.localizedDescription
                }
            }
        } else if ext == "vital" {
            // Single .vital preset — load directly
            viewModel.allNotesOff()
            viewModel.loadVitalPreset(from: url)
            if accessing { url.stopAccessingSecurityScopedResource() }
        } else {
            // JSON preset library
            if let data = try? Data(contentsOf: url) { manager.importData(data) }
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
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

// MARK: - AU Keyboard View

struct AUKeyboardView: View {
    let onNoteOn:      (Int32, Float) -> Void
    let onNoteOff:     (Int32) -> Void
    let onAllNotesOff: () -> Void

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
                        onAllNotesOff(); activeNotes.removeAll()
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
                        onAllNotesOff(); activeNotes.removeAll()
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
                        onNoteOn(Int32(note), 0.78)
                    }
                }
                .onEnded { _ in
                    activeNotes.remove(note)
                    onNoteOff(Int32(note))
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
                        : [Color(white: 0.18), Color(white: 0.05)],
                    startPoint: .top, endPoint: .bottom
                ))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(pressed ? 0.0 : 0.12))
                .frame(height: 2)
            if pressed {
                RoundedRectangle(cornerRadius: 3)
                    .fill(VitalColors.accent.opacity(0.55))
            }
        }
        .frame(width: width, height: height)
        .offset(x: x)
        .scaleEffect(CGSize(width: 1, height: pressed ? 0.96 : 1.0), anchor: .top)
        .shadow(color: Color.black.opacity(0.55), radius: 2, x: 0, y: 2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !activeNotes.contains(note) {
                        activeNotes.insert(note)
                        onNoteOn(Int32(note), 0.85)
                    }
                }
                .onEnded { _ in
                    activeNotes.remove(note)
                    onNoteOff(Int32(note))
                }
        )
        .animation(.easeOut(duration: 0.06), value: pressed)
        .zIndex(1)
    }

    private func blackX(_ note: Int, ww: CGFloat, bw: CGFloat) -> CGFloat {
        let whitesBefore = whiteNotes.filter { $0 < note }.count
        return CGFloat(whitesBefore) * ww - bw * 0.5
    }
}
