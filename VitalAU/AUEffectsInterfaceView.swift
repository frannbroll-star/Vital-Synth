//
//  AUEffectsInterfaceView.swift
//  VitalAU
//
//  Desktop-style Effects tab: left drag-order rail + multi-select detail panels.
//

import SwiftUI

// MARK: - Effect IDs (Vital constants::Effect order)

enum VitalEffectID: Int, CaseIterable, Identifiable, Hashable {
    case chorus = 0, compressor, delay, distortion, eq, filterFx, flanger, phaser, reverb

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .chorus: return "CHORUS"
        case .compressor: return "COMPRESSOR"
        case .delay: return "DELAY"
        case .distortion: return "DISTORTION"
        case .eq: return "EQ"
        case .filterFx: return "FILTER"
        case .flanger: return "FLANGER"
        case .phaser: return "PHASER"
        case .reverb: return "REVERB"
        }
    }

    var shortTitle: String {
        switch self {
        case .chorus: return "CHO"
        case .compressor: return "CMP"
        case .delay: return "DLY"
        case .distortion: return "DST"
        case .eq: return "EQ"
        case .filterFx: return "FLT"
        case .flanger: return "FLA"
        case .phaser: return "PHA"
        case .reverb: return "RVB"
        }
    }

    var color: Color {
        switch self {
        case .chorus: return VitalColors.fxChorus
        case .compressor: return VitalColors.fxCompressor
        case .delay: return VitalColors.fxDelay
        case .distortion: return VitalColors.fxDistortion
        case .eq: return VitalColors.fxEQ
        case .filterFx: return VitalColors.fxFilter
        case .flanger: return VitalColors.fxFlanger
        case .phaser: return VitalColors.fxPhaser
        case .reverb: return VitalColors.fxReverb
        }
    }
}

// MARK: - Main effects interface

struct AUEffectsInterfaceView: View {
    @ObservedObject var engine: VitalAUViewModel
    /// Multi-select: which detail panels are open (independent of power).
    @State private var selected: Set<VitalEffectID> = []
    @State private var didInitSelection = false

    private var orderedEffects: [VitalEffectID] {
        engine.effectChainOrder.compactMap { VitalEffectID(rawValue: $0) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            effectOrderRail
                .frame(width: 128)
            detailViewport
                .frame(maxWidth: .infinity)
        }
        .onAppear {
            engine.loadEffectChainOrder()
            if !didInitSelection {
                selected = Set(VitalEffectID.allCases.filter { isEnabled($0) })
                if selected.isEmpty, let first = orderedEffects.first {
                    selected = [first]
                }
                didInitSelection = true
            }
        }
    }

    // MARK: Left rail (desktop DragDropEffectOrder)

    private var effectOrderRail: some View {
        VStack(spacing: 0) {
            Text("ORDER")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(VitalColors.labelText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(VitalColors.bodyHeading)

            List {
                ForEach(orderedEffects) { fx in
                    effectRailRow(fx)
                        .listRowInsets(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
                        .listRowBackground(Color.clear)
                }
                .onMove(perform: moveEffects)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))

            HStack(spacing: 4) {
                Button("ALL") {
                    selected = Set(VitalEffectID.allCases)
                }
                .buttonStyle(EffectsChipStyle(active: selected.count == 9))
                Button("ON") {
                    selected = Set(VitalEffectID.allCases.filter { isEnabled($0) })
                }
                .buttonStyle(EffectsChipStyle(active: false))
                Button("NONE") {
                    selected = []
                }
                .buttonStyle(EffectsChipStyle(active: selected.isEmpty))
            }
            .padding(6)
            .background(VitalColors.bodyHeading)
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.body)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(VitalColors.panelEdge, lineWidth: 1))
        )
    }

    private func effectRailRow(_ fx: VitalEffectID) -> some View {
        let on = isEnabled(fx)
        let isSel = selected.contains(fx)
        return HStack(spacing: 8) {
            Circle()
                .fill(on ? fx.color : VitalColors.powerOff)
                .frame(width: 10, height: 10)
                .shadow(color: on ? fx.color.opacity(0.65) : .clear, radius: 3)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        setEnabled(fx, !on)
                        if !on { selected.insert(fx) }
                    }
                }

            Text(fx.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isSel ? VitalColors.bodyText : VitalColors.labelText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        if selected.contains(fx) { selected.remove(fx) }
                        else { selected.insert(fx) }
                    }
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSel ? fx.color.opacity(0.18) : VitalColors.widgetBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSel ? fx.color.opacity(0.7) : VitalColors.panelEdge, lineWidth: isSel ? 1.2 : 1)
                )
        )
    }

    private func moveEffects(from source: IndexSet, to destination: Int) {
        var order = orderedEffects
        order.move(fromOffsets: source, toOffset: destination)
        engine.setEffectChainOrder(order.map(\.rawValue))
    }

    // MARK: Right detail viewport

    private var detailViewport: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EFFECTS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                Spacer()
                Text(selected.isEmpty ? "tap to open · multi-select" : "\(selected.count) open")
                    .font(.system(size: 9))
                    .foregroundColor(VitalColors.labelText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(VitalColors.bodyHeading)

            if selected.isEmpty {
                VStack(spacing: 10) {
                    Text("Select one or more effects in the order list")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(VitalColors.labelText)
                        .multilineTextAlignment(.center)
                    Button("Show Enabled") {
                        selected = Set(VitalEffectID.allCases.filter { isEnabled($0) })
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(VitalColors.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(VitalColors.widgetBg)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(orderedEffects.filter { selected.contains($0) }) { fx in
                            effectDetailSection(fx)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.body)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(VitalColors.panelEdge, lineWidth: 1))
        )
    }

    // MARK: Detail sections (desktop-like knob banks)

    @ViewBuilder
    private func effectDetailSection(_ fx: VitalEffectID) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isEnabled(fx) ? fx.color : VitalColors.powerOff)
                    .frame(width: 11, height: 11)
                    .shadow(color: isEnabled(fx) ? fx.color.opacity(0.7) : .clear, radius: 4)
                    .onTapGesture { setEnabled(fx, !isEnabled(fx)) }
                Text(fx.title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(VitalColors.bodyText)
                    .tracking(1)
                Spacer()
                Button {
                    selected.remove(fx)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(VitalColors.labelText)
                        .frame(width: 22, height: 22)
                }.buttonStyle(.plain)
            }

            knobs(for: fx)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.widgetBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(fx.color.opacity(isEnabled(fx) ? 0.45 : 0.15), lineWidth: 1)
                )
        )
        .opacity(isEnabled(fx) ? 1 : 0.72)
    }

    @ViewBuilder
    private func knobs(for fx: VitalEffectID) -> some View {
        switch fx {
        case .chorus:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.chorusMix }, set: { engine.setChorusMix($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FDBK", value: Binding(get: { engine.chorusFeedback }, set: { engine.setChorusFeedback($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "DEPTH", value: Binding(get: { engine.chorusModDepth }, set: { engine.setChorusModDepth($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FREQ", value: Binding(get: { engine.chorusFrequency }, set: { engine.setChorusFrequency($0) }), size: 40, color: fx.color)
            }
        case .compressor:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.compressorMix }, set: { engine.setCompressorMix($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "ATK", value: Binding(get: { engine.compressorAttack }, set: { engine.setCompressorAttack($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "REL", value: Binding(get: { engine.compressorRelease }, set: { engine.setCompressorRelease($0) }), size: 40, color: fx.color)
            }
        case .delay:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.delayMix }, set: { engine.setDelayMix($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FDBK", value: Binding(get: { engine.delayFeedback }, set: { engine.setDelayFeedback($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FREQ", value: Binding(get: { engine.delayFrequency }, set: { engine.setDelayFrequency($0) }), size: 40, color: fx.color)
            }
        case .distortion:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.distortionMix }, set: { engine.setDistortionMix($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "DRIVE", value: Binding(get: { engine.distortionDrive }, set: { engine.setDistortionDrive($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VStack(spacing: 4) {
                    Text("TYPE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(VitalColors.labelText)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { t in
                            Button {
                                engine.setDistortionType(t)
                            } label: {
                                Text("\(t + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(engine.distortionType == t ? .black : VitalColors.labelText)
                                    .frame(width: 22, height: 22)
                                    .background(engine.distortionType == t ? fx.color : VitalColors.bodyHeading)
                                    .cornerRadius(3)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        case .eq:
            HStack(spacing: 0) {
                VitalKnob(label: "LOW", value: Binding(
                    get: { (engine.equalizerLowGain + 15) / 30 },
                    set: { engine.setEqualizerLowGain($0 * 30 - 15) }
                ), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "MID", value: Binding(
                    get: { (engine.equalizerMidGain + 15) / 30 },
                    set: { engine.setEqualizerMidGain($0 * 30 - 15) }
                ), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "HIGH", value: Binding(
                    get: { (engine.equalizerHighGain + 15) / 30 },
                    set: { engine.setEqualizerHighGain($0 * 30 - 15) }
                ), size: 40, color: fx.color)
            }
        case .filterFx:
            HStack(spacing: 0) {
                VitalKnob(label: "CUTOFF", value: Binding(
                    get: { (engine.filterFxCutoff - 8) / 128 },
                    set: { engine.setFilterFxCutoff($0 * 128 + 8) }
                ), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "RES", value: Binding(get: { engine.filterFxResonance }, set: { engine.setFilterFxResonance($0) }), size: 40, color: fx.color)
            }
        case .flanger:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.flangerDryWet }, set: { engine.setFlangerDryWet($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FDBK", value: Binding(get: { engine.flangerFeedback }, set: { engine.setFlangerFeedback($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "DEPTH", value: Binding(get: { engine.flangerModDepth }, set: { engine.setFlangerModDepth($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "CTR", value: Binding(
                    get: { (engine.flangerCenter - 8) / 128 },
                    set: { engine.setFlangerCenter($0 * 128 + 8) }
                ), size: 40, color: fx.color)
            }
        case .phaser:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.phaserDryWet }, set: { engine.setPhaserDryWet($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "FDBK", value: Binding(get: { engine.phaserFeedback }, set: { engine.setPhaserFeedback($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "CTR", value: Binding(
                    get: { (engine.phaserCenter - 8) / 128 },
                    set: { engine.setPhaserCenter($0 * 128 + 8) }
                ), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "DEPTH", value: Binding(get: { engine.phaserModDepth }, set: { engine.setPhaserModDepth($0) }), size: 40, color: fx.color)
            }
        case .reverb:
            HStack(spacing: 0) {
                VitalKnob(label: "MIX", value: Binding(get: { engine.reverbMix }, set: { engine.setReverbMix($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "SIZE", value: Binding(get: { engine.reverbSize }, set: { engine.setReverbSize($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "DECAY", value: Binding(get: { engine.reverbDecay }, set: { engine.setReverbDecay($0) }), size: 40, color: fx.color)
                Spacer(minLength: 8)
                VitalKnob(label: "CHORUS", value: Binding(get: { engine.reverbChorusAmount }, set: { engine.setReverbChorusAmount($0) }), size: 40, color: fx.color)
            }
        }
    }

    // MARK: Power helpers

    private func isEnabled(_ fx: VitalEffectID) -> Bool {
        switch fx {
        case .chorus: return engine.chorusOn
        case .compressor: return engine.compressorOn
        case .delay: return engine.delayOn
        case .distortion: return engine.distortionOn
        case .eq: return engine.equalizerOn
        case .filterFx: return engine.filterFxOn
        case .flanger: return engine.flangerOn
        case .phaser: return engine.phaserOn
        case .reverb: return engine.reverbOn
        }
    }

    private func setEnabled(_ fx: VitalEffectID, _ on: Bool) {
        switch fx {
        case .chorus: engine.setChorusOn(on)
        case .compressor: engine.setCompressorOn(on)
        case .delay: engine.setDelayOn(on)
        case .distortion: engine.setDistortionOn(on)
        case .eq: engine.setEqualizerOn(on)
        case .filterFx: engine.setFilterFxOn(on)
        case .flanger: engine.setFlangerOn(on)
        case .phaser: engine.setPhaserOn(on)
        case .reverb: engine.setReverbOn(on)
        }
    }
}

private struct EffectsChipStyle: ButtonStyle {
    var active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(active ? .black : VitalColors.labelText)
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(active ? VitalColors.accent : VitalColors.widgetBg)
            .cornerRadius(3)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
