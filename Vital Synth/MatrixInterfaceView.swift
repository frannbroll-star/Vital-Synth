//
//  MatrixInterfaceView.swift
//  Vital Synth
//
//  Desktop-style modulation matrix: bypass · source · ± · stereo · morph · amount · dest.
//

import SwiftUI

struct MatrixInterfaceView: View {
    @ObservedObject var engine: VitalAudioEngine
    @State private var addSource = "lfo_1"
    @State private var addDest = "filter_1_cutoff"
    @State private var filterText = ""

    private var sources: [String] {
        engine.modulationSources.isEmpty ? Self.fallbackSources : engine.modulationSources
    }

    private var destinations: [String] {
        engine.modulationDestinations.isEmpty ? Self.fallbackDestinations : engine.modulationDestinations
    }

    private var filteredConnections: [ModConnection] {
        let q = filterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return engine.modConnections }
        return engine.modConnections.filter {
            $0.source.lowercased().contains(q) || $0.destination.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            columnLabels
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredConnections) { conn in
                        MatrixConnectionRow(engine: engine, connection: conn)
                    }
                    if engine.modConnections.isEmpty {
                        Text("No modulation connections — add one below")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(VitalColors.labelText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                    }
                }
                .padding(8)
            }
            addBar
        }
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(VitalColors.body)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(VitalColors.panelEdge, lineWidth: 1))
        )
        .onAppear {
            engine.refreshModulations()
            if sources.contains("lfo_1") { addSource = "lfo_1" }
            else if let s = sources.first { addSource = s }
            if destinations.contains("filter_1_cutoff") { addDest = "filter_1_cutoff" }
            else if let d = destinations.first { addDest = d }
        }
    }

    private var header: some View {
        HStack {
            Text("MODULATION MATRIX")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(VitalColors.bodyText)
                .tracking(1)
            Spacer()
            Text("\(engine.modConnections.count) connections")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(VitalColors.labelText)
            TextField("Filter…", text: $filterText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(VitalColors.bodyText)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .frame(width: 140)
                .background(VitalColors.widgetBg)
                .cornerRadius(3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(VitalColors.bodyHeading)
    }

    private var columnLabels: some View {
        HStack(spacing: 6) {
            Text("BYP").frame(width: 28)
            Text("SOURCE").frame(width: 120, alignment: .leading)
            Text("±").frame(width: 28)
            Text("ST").frame(width: 28)
            Text("MORPH").frame(width: 52)
            Text("AMOUNT").frame(maxWidth: .infinity)
            Text("DESTINATION").frame(maxWidth: .infinity, alignment: .leading)
            Text("").frame(width: 28)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundColor(VitalColors.labelText)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(VitalColors.headerBg)
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            Picker("SRC", selection: $addSource) {
                ForEach(sources, id: \.self) { Text(Self.shortName($0)).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(VitalColors.labelText)

            Picker("DST", selection: $addDest) {
                ForEach(destinations, id: \.self) { Text(Self.shortName($0)).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Button {
                engine.addModulation(source: addSource, destination: addDest, amount: 0.5)
            } label: {
                Text("ADD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(VitalColors.modTeal)
                    .cornerRadius(4)
            }.buttonStyle(.plain)
        }
        .padding(10)
        .background(VitalColors.bodyHeading)
    }

    static func shortName(_ name: String) -> String {
        name.replacingOccurrences(of: "macro_control_", with: "macro_")
            .replacingOccurrences(of: "oscillator_", with: "osc_")
    }

    static let fallbackSources = [
        "env_1","env_2","env_3","env_4","env_5","env_6",
        "lfo_1","lfo_2","lfo_3","lfo_4","lfo_5","lfo_6","lfo_7","lfo_8",
        "random_1","random_2","random_3","random_4",
        "macro_control_1","macro_control_2","macro_control_3","macro_control_4",
        "note","velocity","mod_wheel","pitch_wheel","aftertouch","lift","note_in_octave","slide"
    ]

    static let fallbackDestinations = [
        "filter_1_cutoff","filter_1_resonance","filter_1_drive","filter_1_blend",
        "filter_2_cutoff","filter_2_resonance","filter_2_drive","filter_2_blend",
        "osc_1_level","osc_2_level","osc_3_level",
        "osc_1_pan","osc_2_pan","osc_3_pan",
        "osc_1_wave_frame","osc_2_wave_frame","osc_3_wave_frame",
        "osc_1_transpose","osc_2_transpose","osc_3_transpose",
        "osc_1_tune","osc_2_tune","osc_3_tune",
        "osc_1_unison_detune","osc_2_unison_detune","osc_3_unison_detune",
        "osc_1_phase","osc_2_phase","osc_3_phase",
        "osc_1_spectral_morph_amount","osc_2_spectral_morph_amount","osc_3_spectral_morph_amount",
        "osc_1_distortion_amount","osc_2_distortion_amount","osc_3_distortion_amount",
        "sample_level","sample_pan","sample_transpose",
        "volume","env_1_attack","env_1_decay","env_1_sustain","env_1_release",
        "lfo_1_frequency","lfo_2_frequency","macro_control_1","macro_control_2",
        "reverb_dry_wet","delay_dry_wet","chorus_dry_wet","flanger_dry_wet","phaser_dry_wet",
        "distortion_drive","filter_fx_cutoff","eq_low_gain","eq_band_gain","eq_high_gain"
    ]
}

// MARK: - Connection row

private struct MatrixConnectionRow: View {
    @ObservedObject var engine: VitalAudioEngine
    let connection: ModConnection

    private var live: ModConnection {
        engine.modConnections.first(where: {
            $0.source == connection.source && $0.destination == connection.destination
        }) ?? connection
    }

    var body: some View {
        HStack(spacing: 6) {
            // Bypass
            Button {
                engine.setModulationBypass(source: live.source, destination: live.destination, !live.bypass)
            } label: {
                Circle()
                    .fill(live.bypass ? VitalColors.powerOff : VitalColors.modTeal)
                    .frame(width: 10, height: 10)
                    .shadow(color: live.bypass ? .clear : VitalColors.modTeal.opacity(0.55), radius: 3)
            }
            .buttonStyle(.plain)
            .frame(width: 28)

            Text(MatrixInterfaceView.shortName(live.source))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(VitalColors.modTeal)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1).minimumScaleFactor(0.65)

            // Bipolar
            Button {
                engine.setModulationBipolar(source: live.source, destination: live.destination, !live.bipolar)
            } label: {
                Text("±")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(live.bipolar ? .black : VitalColors.labelText)
                    .frame(width: 26, height: 22)
                    .background(live.bipolar ? VitalColors.modTeal : VitalColors.bodyHeading)
                    .cornerRadius(3)
            }.buttonStyle(.plain)

            // Stereo
            Button {
                engine.setModulationStereo(source: live.source, destination: live.destination, !live.stereo)
            } label: {
                Text("ST")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(live.stereo ? .black : VitalColors.labelText)
                    .frame(width: 26, height: 22)
                    .background(live.stereo ? VitalColors.accent : VitalColors.bodyHeading)
                    .cornerRadius(3)
            }.buttonStyle(.plain)

            // Morph / power
            VitalKnob(label: "", value: Binding(
                get: { (live.power + 1) * 0.5 },
                set: { engine.setModulationPower(source: live.source, destination: live.destination, $0 * 2 - 1) }
            ), size: 28, color: VitalColors.warmOrange)
            .frame(width: 52)

            // Amount (-1…1)
            VStack(spacing: 2) {
                Slider(value: Binding(
                    get: { Double(live.amount) },
                    set: { engine.updateModulation(source: live.source, destination: live.destination, amount: Float($0)) }
                ), in: -1...1)
                .accentColor(VitalColors.modTeal)
                Text(String(format: "%+.2f", live.amount))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(VitalColors.labelText)
            }
            .frame(maxWidth: .infinity)

            Text(MatrixInterfaceView.shortName(live.destination))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(VitalColors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1).minimumScaleFactor(0.65)

            Button {
                engine.removeModulation(source: live.source, destination: live.destination)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(VitalColors.labelText)
                    .frame(width: 26, height: 22)
                    .background(VitalColors.bodyHeading)
                    .cornerRadius(3)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(VitalColors.widgetBg)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(VitalColors.panelEdge, lineWidth: 1))
        )
        .opacity(live.bypass ? 0.45 : 1)
    }
}
