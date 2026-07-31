//
//  AUWavetableEditorView.swift
//  VitalAU
//
//  Wavetable editor: multi-frame tables, time + spectral editing, shapes.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Editor sheet

struct AUWavetableEditorView: View {
    enum EditMode: String, CaseIterable {
        case time = "TIME"
        case amp = "AMP"
        case phase = "PHASE"
    }

    @ObservedObject var viewModel: VitalAUViewModel
    let oscillatorIndex: Int
    var onDismiss: () -> Void

    @State private var frameIndex: Int = 0
    @State private var numFrames: Int = 1
    @State private var samples: [Float] = Array(repeating: 0, count: 256)
    @State private var amplitudes: [Float] = Array(repeating: 0, count: 64)
    @State private var phases: [Float] = Array(repeating: 0, count: 64)
    @State private var clipboard: [Float]? = nil
    @State private var dirty = false
    @State private var status: String = ""
    @State private var editMode: EditMode = .time
    @State private var morphFrom: Int? = nil
    @State private var morphSpectral = false
    @State private var showImporter = false

    private let displaySize = 256
    private let harmonicCount = 64
    private let framePresets = [1, 64, 128, 256]
    private let shapes: [(String, Int)] = [
        ("SIN", 0), ("TRI", 2), ("SQ", 3), ("PULSE", 4), ("SAW", 5)
    ]

    private var oscLabel: String { "OSC \(oscillatorIndex + 1)" }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(VitalColors.panelEdge)
            toolbar
            modeBar
            editorCanvas
                .padding(10)
            frameStrip
            footer
        }
        .background(VitalColors.background.ignoresSafeArea())
        .onAppear { loadFromEngine() }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [
                .audio, .json,
                UTType(filenameExtension: "vital") ?? .data,
                UTType(filenameExtension: "vitaltable") ?? .data
            ]
        ) { result in
            guard case .success(let url) = result else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            viewModel.loadWavetable(from: url, oscillatorIndex: oscillatorIndex)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                loadFromEngine()
                status = "Imported into \(oscLabel)"
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WAVETABLE EDITOR")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                Text("\(oscLabel)  ·  Frame \(frameIndex) / \(max(numFrames - 1, 0))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(VitalColors.labelText)
            }
            Spacer()
            if dirty {
                Text("EDITED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(VitalColors.warmOrange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(VitalColors.widgetBg).cornerRadius(3)
            }
            Button("DONE") {
                if dirty { applyCurrent(commit: true) }
                onDismiss()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(VitalColors.accent)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(VitalColors.headerBg)
    }

    // MARK: Toolbar

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("FRAMES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                ForEach(framePresets, id: \.self) { n in
                    Button { expandTo(n) } label: {
                        Text("\(n)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(numFrames == n ? .black : VitalColors.bodyText)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(numFrames == n ? VitalColors.accent : VitalColors.bodyHeading)
                            .cornerRadius(3)
                    }.buttonStyle(.plain)
                }

                toolbarDivider

                ForEach(shapes, id: \.1) { name, shape in
                    Button { injectShape(shape) } label: {
                        Text(name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(VitalColors.bodyText)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(VitalColors.bodyHeading)
                            .cornerRadius(3)
                    }.buttonStyle(.plain)
                }

                toolbarDivider

                Button { clearFrame() } label: { toolLabel("CLEAR") }.buttonStyle(.plain)
                Button { flipHorizontal() } label: { toolLabel("FLIP H") }.buttonStyle(.plain)
                Button { flipVertical() } label: { toolLabel("FLIP V") }.buttonStyle(.plain)
                Button { normalizeFrame() } label: { toolLabel("NORM") }.buttonStyle(.plain)
                Button { duplicateToNext() } label: { toolLabel("DUP→") }.buttonStyle(.plain)

                toolbarDivider

                Button {
                    morphFrom = frameIndex
                    status = "Morph start → frame \(frameIndex)"
                } label: {
                    toolLabel(morphFrom == nil ? "KEY A" : "A:\(morphFrom!)")
                }.buttonStyle(.plain)

                Button {
                    morphSpectral.toggle()
                } label: {
                    Text(morphSpectral ? "SPEC" : "TIME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(morphSpectral ? .black : VitalColors.bodyText)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(morphSpectral ? VitalColors.accent : VitalColors.bodyHeading)
                        .cornerRadius(3)
                }.buttonStyle(.plain)

                Button { runMorph() } label: { toolLabel("BLEND") }.buttonStyle(.plain)

                toolbarDivider

                Button { showImporter = true } label: { toolLabel("IMPORT") }.buttonStyle(.plain)

                toolbarDivider

                Button {
                    clipboard = samples
                    status = "Copied frame \(frameIndex)"
                } label: { toolLabel("COPY") }.buttonStyle(.plain)

                Button {
                    guard let clip = clipboard else { return }
                    samples = clip
                    dirty = true
                    status = "Pasted → frame \(frameIndex)"
                } label: {
                    toolLabel("PASTE").opacity(clipboard == nil ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(clipboard == nil)

                toolbarDivider

                Button {
                    applyCurrent(commit: true)
                    status = "Applied to \(oscLabel)"
                } label: {
                    Text("APPLY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(VitalColors.accent)
                        .cornerRadius(3)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(VitalColors.headerBg)
    }

    private var modeBar: some View {
        HStack(spacing: 4) {
            ForEach(EditMode.allCases, id: \.self) { mode in
                Button {
                    if dirty { applyCurrent(commit: false) }
                    editMode = mode
                    reloadCurrentFrame()
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(editMode == mode ? .black : VitalColors.labelText)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(editMode == mode ? VitalColors.accent : VitalColors.bodyHeading)
                        .cornerRadius(3)
                }.buttonStyle(.plain)
            }
            Spacer()
            Text(editMode == .time ? "Draw waveform" : (editMode == .amp ? "Drag harmonic amps" : "Drag harmonic phases"))
                .font(.system(size: 10))
                .foregroundColor(VitalColors.labelText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(VitalColors.headerBg)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(VitalColors.panelEdge)
            .frame(width: 1, height: 18)
    }

    private func toolLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(VitalColors.bodyText)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(VitalColors.bodyHeading)
            .cornerRadius(3)
    }

    // MARK: Canvas

    @ViewBuilder
    private var editorCanvas: some View {
        Group {
            switch editMode {
            case .time:
                AUWavetableDrawCanvas(samples: $samples, color: VitalColors.accent) {
                    dirty = true
                }
            case .amp:
                AUSpectralBarCanvas(values: $amplitudes, bipolar: false, color: VitalColors.accent) {
                    dirty = true
                }
            case .phase:
                AUSpectralBarCanvas(values: $phases, bipolar: true, color: VitalColors.warmOrange) {
                    dirty = true
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(VitalColors.panelEdge, lineWidth: 1))
        )
    }

    // MARK: Frame scrubber + strip

    private var frameStrip: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FRAME")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                if numFrames > 1 {
                    Slider(
                        value: Binding(
                            get: { Double(frameIndex) },
                            set: { selectFrame(Int($0.rounded())) }
                        ),
                        in: 0...Double(numFrames - 1),
                        step: 1
                    )
                    .accentColor(VitalColors.accent)
                } else {
                    Text("single frame")
                        .font(.system(size: 10))
                        .foregroundColor(VitalColors.labelText)
                    Spacer()
                }
                Text("\(frameIndex)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(VitalColors.accent)
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<min(numFrames, 64), id: \.self) { i in
                        Button { selectFrame(i) } label: {
                            AUWavetableMiniFrame(samples: previewSamples(for: i),
                                               selected: i == frameIndex,
                                               color: VitalColors.accent)
                                .frame(width: 44, height: 28)
                        }.buttonStyle(.plain)
                    }
                    if numFrames > 64 {
                        Text("+\(numFrames - 64)")
                            .font(.system(size: 9))
                            .foregroundColor(VitalColors.labelText)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack {
            Text(status.isEmpty ? "KEY A → end frame → BLEND · DUP→ · IMPORT · NORM" : status)
                .font(.system(size: 10))
                .foregroundColor(VitalColors.labelText)
                .lineLimit(1)
            Spacer()
            Text("\(numFrames) frames")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(VitalColors.labelText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(VitalColors.headerBg)
    }

    // MARK: - Engine I/O

    private func loadFromEngine() {
        numFrames = max(1, viewModel.wavetableFrameCount(oscillatorIndex: oscillatorIndex))
        let pos = viewModel.waveFramePosition(oscillatorIndex: oscillatorIndex)
        if numFrames > 1 {
            frameIndex = min(numFrames - 1, max(0, Int((pos * Float(numFrames - 1)).rounded())))
        } else {
            frameIndex = 0
        }
        reloadCurrentFrame()
        dirty = false
        status = "Loaded \(oscLabel)"
    }

    private func reloadCurrentFrame() {
        samples = downsample(viewModel.getWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frameIndex))
        amplitudes = viewModel.getWavetableAmplitudes(oscillatorIndex: oscillatorIndex,
                                                   frame: frameIndex,
                                                   harmonicCount: harmonicCount)
        phases = viewModel.getWavetablePhases(oscillatorIndex: oscillatorIndex,
                                           frame: frameIndex,
                                           harmonicCount: harmonicCount)
    }

    private func selectFrame(_ idx: Int) {
        let clamped = max(0, min(numFrames - 1, idx))
        if dirty && clamped != frameIndex {
            applyCurrent(commit: false)
        }
        frameIndex = clamped
        reloadCurrentFrame()
        viewModel.setWaveFramePosition(oscillatorIndex: oscillatorIndex, normalized: numFrames > 1
                                    ? Float(clamped) / Float(numFrames - 1) : 0)
        dirty = false
    }

    private func expandTo(_ count: Int) {
        if dirty { applyCurrent(commit: false) }
        let ok = viewModel.expandWavetable(toFrames: count, oscillatorIndex: oscillatorIndex, interpolate: true)
        guard ok else {
            status = "Could not expand to \(count) frames"
            return
        }
        numFrames = max(1, viewModel.wavetableFrameCount(oscillatorIndex: oscillatorIndex))
        frameIndex = min(frameIndex, numFrames - 1)
        reloadCurrentFrame()
        dirty = false
        status = "Table → \(numFrames) frames"
    }

    private func injectShape(_ shape: Int) {
        _ = viewModel.fillWavetableFrame(shape: shape, oscillatorIndex: oscillatorIndex, frame: frameIndex)
        _ = viewModel.commitWavetable(oscillatorIndex: oscillatorIndex)
        reloadCurrentFrame()
        dirty = false
        status = "Shape applied to frame \(frameIndex)"
    }

    private func clearFrame() {
        switch editMode {
        case .time:
            samples = Array(repeating: 0, count: displaySize)
        case .amp:
            amplitudes = Array(repeating: 0, count: harmonicCount)
        case .phase:
            phases = Array(repeating: 0, count: harmonicCount)
        }
        dirty = true
    }

    private func flipHorizontal() {
        guard editMode == .time else { return }
        samples.reverse()
        dirty = true
    }

    private func flipVertical() {
        switch editMode {
        case .time:
            samples = samples.map { -$0 }
        case .amp:
            break
        case .phase:
            phases = phases.map { -$0 }
        }
        dirty = true
    }

    private func normalizeFrame() {
        if dirty { applyCurrent(commit: false) }
        _ = viewModel.normalizeWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frameIndex, removeDC: true)
        _ = viewModel.commitWavetable(oscillatorIndex: oscillatorIndex)
        reloadCurrentFrame()
        dirty = false
        status = "Normalized frame \(frameIndex)"
    }

    private func duplicateToNext() {
        guard numFrames > 1, frameIndex < numFrames - 1 else {
            status = "Need a next frame (expand table first)"
            return
        }
        if dirty { applyCurrent(commit: false) }
        _ = viewModel.copyWavetableFrame(from: frameIndex, to: frameIndex + 1, oscillatorIndex: oscillatorIndex)
        _ = viewModel.commitWavetable(oscillatorIndex: oscillatorIndex)
        selectFrame(frameIndex + 1)
        status = "Duplicated → frame \(frameIndex)"
    }

    private func runMorph() {
        guard let a = morphFrom else {
            status = "Set KEY A first, then move to end frame and BLEND"
            return
        }
        let b = frameIndex
        guard abs(b - a) >= 2 else {
            status = "Need ≥1 frame between A and B"
            return
        }
        if dirty { applyCurrent(commit: false) }
        let ok = viewModel.interpolateWavetableFrames(from: a, to: b, spectral: morphSpectral,
                                                   oscillatorIndex: oscillatorIndex)
        if ok {
            _ = viewModel.commitWavetable(oscillatorIndex: oscillatorIndex)
            reloadCurrentFrame()
            status = "Blended \(min(a,b))→\(max(a,b)) (\(morphSpectral ? "spectral" : "time"))"
        } else {
            status = "Blend failed"
        }
    }

    private func applyCurrent(commit: Bool) {
        switch editMode {
        case .time:
            let full = upsample(samples)
            _ = viewModel.setWavetableFrame(full, oscillatorIndex: oscillatorIndex, frame: frameIndex)
        case .amp, .phase:
            _ = viewModel.setWavetableSpectrum(amplitudes: amplitudes,
                                            phases: phases,
                                            oscillatorIndex: oscillatorIndex,
                                            frame: frameIndex)
            // Refresh time preview after spectral write
            samples = downsample(viewModel.getWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frameIndex))
        }
        if commit {
            _ = viewModel.commitWavetable(oscillatorIndex: oscillatorIndex)
        }
        dirty = false
    }

    private func previewSamples(for frame: Int) -> [Float] {
        if frame == frameIndex { return samples }
        let cached: [[Float]]
        switch oscillatorIndex {
        case 0: cached = viewModel.osc1DisplayFrames
        case 1: cached = viewModel.osc2DisplayFrames
        case 2: cached = viewModel.osc3DisplayFrames
        default: cached = []
        }
        if frame < cached.count { return cached[frame] }
        return downsample(viewModel.getWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frame))
    }

    private func downsample(_ full: [Float]) -> [Float] {
        guard !full.isEmpty else { return Array(repeating: 0, count: displaySize) }
        if full.count == displaySize { return full }
        var out = [Float](repeating: 0, count: displaySize)
        for i in 0..<displaySize {
            let idx = i * (full.count - 1) / max(displaySize - 1, 1)
            out[i] = full[idx]
        }
        return out
    }

    private func upsample(_ display: [Float]) -> [Float] {
        let target = 2048
        guard !display.isEmpty else { return Array(repeating: 0, count: target) }
        if display.count == target { return display }
        var out = [Float](repeating: 0, count: target)
        let last = display.count - 1
        for i in 0..<target {
            let t = Float(i) * Float(last) / Float(target - 1)
            let i0 = Int(t)
            let i1 = min(last, i0 + 1)
            let frac = t - Float(i0)
            out[i] = display[i0] * (1 - frac) + display[i1] * frac
        }
        return out
    }
}

// MARK: - Drawable canvas

struct AUWavetableDrawCanvas: View {
    @Binding var samples: [Float]
    var color: Color = VitalColors.accent
    var onEdit: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Canvas { ctx, size in
                    for t in [0.25, 0.5, 0.75] {
                        var v = Path()
                        v.move(to: .init(x: t * size.width, y: 0))
                        v.addLine(to: .init(x: t * size.width, y: size.height))
                        ctx.stroke(v, with: .color(.white.opacity(0.05)), lineWidth: 1)
                        var hz = Path()
                        hz.move(to: .init(x: 0, y: t * size.height))
                        hz.addLine(to: .init(x: size.width, y: t * size.height))
                        ctx.stroke(hz, with: .color(.white.opacity(0.05)), lineWidth: 1)
                    }
                    var mid = Path()
                    mid.move(to: .init(x: 0, y: size.height * 0.5))
                    mid.addLine(to: .init(x: size.width, y: size.height * 0.5))
                    ctx.stroke(mid, with: .color(.white.opacity(0.12)), lineWidth: 1)
                }

                Canvas { ctx, size in
                    guard samples.count > 1 else { return }
                    var path = Path()
                    let n = samples.count
                    for i in 0..<n {
                        let x = CGFloat(i) / CGFloat(n - 1) * size.width
                        let y = size.height * 0.5 - CGFloat(samples[i]) * size.height * 0.42
                        if i == 0 { path.move(to: .init(x: x, y: y)) }
                        else { path.addLine(to: .init(x: x, y: y)) }
                    }
                    var fill = path
                    fill.addLine(to: .init(x: size.width, y: size.height * 0.5))
                    fill.addLine(to: .init(x: 0, y: size.height * 0.5))
                    fill.closeSubpath()
                    ctx.fill(fill, with: .color(color.opacity(0.18)))
                    ctx.stroke(path, with: .color(color.opacity(0.25)),
                               style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    ctx.stroke(path, with: .color(color.opacity(0.95)),
                               style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        paint(at: g.location, in: CGSize(width: w, height: h))
                    }
            )
        }
    }

    private func paint(at point: CGPoint, in size: CGSize) {
        guard size.width > 1, samples.count > 1 else { return }
        let n = samples.count
        let xNorm = max(0, min(1, point.x / size.width))
        let yNorm = max(-1, min(1, Float(1 - (point.y / size.height) * 2)))
        let idx = Int((xNorm * CGFloat(n - 1)).rounded())
        var next = samples
        next[idx] = yNorm
        if idx > 0 { next[idx - 1] = next[idx - 1] * 0.35 + yNorm * 0.65 }
        if idx + 1 < n { next[idx + 1] = next[idx + 1] * 0.35 + yNorm * 0.65 }
        samples = next
        onEdit()
    }
}

// MARK: - Spectral bar editor

struct AUSpectralBarCanvas: View {
    @Binding var values: [Float]
    var bipolar: Bool
    var color: Color
    var onEdit: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let n = max(values.count, 1)
            let barW = w / CGFloat(n)

            Canvas { ctx, size in
                if bipolar {
                    var mid = Path()
                    mid.move(to: .init(x: 0, y: size.height * 0.5))
                    mid.addLine(to: .init(x: size.width, y: size.height * 0.5))
                    ctx.stroke(mid, with: .color(.white.opacity(0.15)), lineWidth: 1)
                }
                for i in 0..<values.count {
                    let v = values[i]
                    let x = CGFloat(i) * barW + barW * 0.15
                    let bw = max(1, barW * 0.7)
                    if bipolar {
                        let midY = size.height * 0.5
                        let yh = CGFloat(v) * size.height * 0.42
                        let rect = CGRect(x: x, y: midY - max(0, yh),
                                          width: bw, height: abs(yh) + 1)
                        ctx.fill(Path(rect), with: .color(color.opacity(0.85)))
                    } else {
                        let clamped = max(0, min(1, CGFloat(v)))
                        let bh = clamped * size.height * 0.9
                        let rect = CGRect(x: x, y: size.height - bh - 4, width: bw, height: bh)
                        ctx.fill(Path(rect), with: .color(color.opacity(0.85)))
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        paint(at: g.location, width: w, height: h)
                    }
            )
        }
    }

    private func paint(at point: CGPoint, width w: CGFloat, height h: CGFloat) {
        guard !values.isEmpty, w > 1, h > 1 else { return }
        let idx = max(0, min(values.count - 1, Int(point.x / w * CGFloat(values.count))))
        var next = values
        if bipolar {
            next[idx] = max(-1, min(1, Float(1 - (point.y / h) * 2)))
        } else {
            next[idx] = max(0, min(1, Float(1 - point.y / h)))
        }
        values = next
        onEdit()
    }
}

// MARK: - Mini frame thumbnail

struct AUWavetableMiniFrame: View {
    var samples: [Float]
    var selected: Bool
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            guard samples.count > 1 else { return }
            var path = Path()
            let n = samples.count
            let mid = size.height * 0.5
            let amp = size.height * 0.4
            for i in 0..<n {
                let x = CGFloat(i) / CGFloat(n - 1) * size.width
                let y = mid - CGFloat(samples[i]) * amp
                if i == 0 { path.move(to: .init(x: x, y: y)) }
                else { path.addLine(to: .init(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(color.opacity(selected ? 1 : 0.55)),
                       style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        .background(VitalColors.widgetBg)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(selected ? color : VitalColors.panelEdge, lineWidth: selected ? 1.5 : 1)
        )
        .cornerRadius(3)
    }
}
