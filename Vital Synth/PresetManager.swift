//
//  PresetManager.swift
//  Vital Synth
//
//  Musical preset model, storage, and randomiser.
//

import Foundation
import SwiftUI

// MARK: - Preset Model

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
    var lfo1Amount: Float = 0.0   // 0-1, fraction of destination range
    var lfo1Target: Int = 0       // index into VitalAudioEngine.lfoTargets

    // FX
    var reverbMix: Float = 0.0;  var delayMix: Float = 0.0
    var chorusMix: Float = 0.0;  var distortionMix: Float = 0.0

    // Voice
    var legato: Bool = false
    var glide:  Float = 0.0   // 0=off, 1=max; maps to portamento_time -10..4

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
    case strings = "Strings"
    case stabs = "Stabs"

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
        case .strings: return "🎻"
        case .stabs:   return "🔪"
        }
    }
}

// MARK: - Preset Navigation

enum PresetNavEntry {
    case custom(VitalPreset)
    case imported(ImportedPreset)

    var name: String {
        switch self {
        case .custom(let p):   return p.name
        case .imported(let p): return p.name
        }
    }

    @MainActor func apply(engine: VitalAudioEngine) {
        switch self {
        case .custom(let p):   engine.applyPreset(p)
        case .imported(let p): engine.loadVitalPreset(from: p.url)
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
            .appendingPathComponent("vitalsynth_imported.json")
    }()

    init() {
        loadFromDisk()
        loadImportedFromDisk()
    }

    // MARK: CRUD

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

    // MARK: Persistence

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

    // MARK: Imported bank presets

    private func loadImportedFromDisk() {
        guard let data    = try? Data(contentsOf: importedStorageURL),
              let decoded = try? JSONDecoder().decode([ImportedPreset].self, from: data)
        else { return }
        // Drop any entries whose .vital file no longer exists on disk
        importedPresets = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }

    private func persistImported() {
        if let data = try? JSONEncoder().encode(importedPresets) {
            try? data.write(to: importedStorageURL, options: .atomic)
        }
    }

    func importFolder(from url: URL) async throws -> Int {
        let presets = try await Task.detached(priority: .userInitiated) {
            try VitalbankImporter.importFolder(from: url)
        }.value
        let existing = Set(importedPresets.map(\.relativePath))
        let fresh    = presets.filter { !existing.contains($0.relativePath) }
        importedPresets.append(contentsOf: fresh)
        importedPresets.sort {
            $0.bankName == $1.bankName
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.bankName.localizedCaseInsensitiveCompare($1.bankName) == .orderedAscending
        }
        persistImported()
        return fresh.count
    }

    func importBank(from url: URL) async throws -> Int {
        let presets = try await Task.detached(priority: .userInitiated) {
            try VitalbankImporter.importBank(from: url)
        }.value
        let existing = Set(importedPresets.map(\.relativePath))
        let fresh    = presets.filter { !existing.contains($0.relativePath) }
        importedPresets.append(contentsOf: fresh)
        importedPresets.sort {
            $0.bankName == $1.bankName
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.bankName.localizedCaseInsensitiveCompare($1.bankName) == .orderedAscending
        }
        persistImported()
        return fresh.count
    }

    func deleteImported(_ preset: ImportedPreset) {
        importedPresets.removeAll { $0.id == preset.id }
        try? FileManager.default.removeItem(at: preset.url)
        persistImported()
    }

    var importedBankNames: [String] {
        var seen = Set<String>()
        return importedPresets.compactMap { seen.insert($0.bankName).inserted ? $0.bankName : nil }
    }

    // MARK: Export / Import

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

    // MARK: Musical Random Generator

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

    func randomPreset(style: PresetStyle) -> VitalPreset {
        var p = VitalPreset(name: randomName(), category: style.rawValue)
        configure(&p, style: style)
        return p
    }

    // MARK: Style configurations

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

        // ── PAD ──────────────────────────────────────────────────────────────
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
            // Parallel filter: OSC1→F1, OSC2→F2 for stereo width
            p.filter2On       = Bool.random()
            if p.filter2On {
                p.osc2FilterRoute  = 1   // OSC2 → F2
                p.filter2Cutoff    = rnd(70, 110)
                p.filter2Resonance = rnd(0.0, 0.3)
            }
            // Gentle LFO on F1 cutoff for movement
            p.lfo1Rate   = rnd(0.05, 0.20)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.10, 0.30)

        // ── LEAD ─────────────────────────────────────────────────────────────
        case .lead:
            p.osc1WaveForm    = pick([0, 3])
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.0, 0.30)
            p.osc2Transpose   = pick([0, 7, 12])
            p.filterCutoff    = rnd(70, 110)
            p.filterResonance = rnd(0.25, 0.55)
            p.filterDrive     = rnd(0.0, 0.3)
            p.env1Attack      = rnd(0.001, 0.03)
            p.env1Decay       = rnd(0.10, 0.40)
            p.env1Sustain     = rnd(0.35, 0.75)
            p.env1Release     = rnd(0.10, 0.40)
            p.distortionMix   = rnd(0.0, 0.2)
            // LFO on filter cutoff for classic lead movement
            p.lfo1Rate   = rnd(0.15, 0.50)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.10, 0.35)

        // ── BASS ─────────────────────────────────────────────────────────────
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
            // Optional parallel filter for mid-frequency shaping
            p.filter2On = Bool.random()
            if p.filter2On && p.osc2On {
                p.osc2FilterRoute  = 1   // OSC2 (upper octave) → F2 for separate tone
                p.filter2Cutoff    = rnd(60, 90)
                p.filter2Resonance = rnd(0.1, 0.4)
            }
            // Subtle LFO on amplitude for pumping feel
            p.lfo1Rate   = rnd(0.25, 1.0)
            p.lfo1Target = 4   // AMP
            p.lfo1Amount = rnd(0.0, 0.15)

        // ── PLUCK ────────────────────────────────────────────────────────────
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
            // Minimal LFO — subtle tone variation
            p.lfo1Rate   = rnd(0.10, 0.30)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.0, 0.10)

        // ── KEYS ─────────────────────────────────────────────────────────────
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
            // Occasional second filter for warmth layering
            p.filter2On = Bool.random()
            if p.filter2On {
                p.filter2Cutoff    = rnd(85, 120)
                p.filter2Resonance = rnd(0.0, 0.25)
            }
            // Gentle LFO on F1 cutoff
            p.lfo1Rate   = rnd(0.10, 0.30)
            p.lfo1Target = 0
            p.lfo1Amount = rnd(0.0, 0.20)

        // ── AMBIENT ──────────────────────────────────────────────────────────
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
            // Ambient always uses dual filters: OSC1→F1, OSC2→F2, OSC3→Both
            p.filter2On        = true
            p.osc1FilterRoute  = 0   // F1
            p.osc2FilterRoute  = 1   // F2
            p.osc3FilterRoute  = p.osc3On ? 2 : 0   // Both (if OSC3 is on)
            p.filter2Cutoff    = rnd(80, 120)
            p.filter2Resonance = rnd(0.0, 0.20)
            // Slow LFO on either F1 or F2 cutoff for evolving texture
            p.lfo1Rate   = rnd(0.03, 0.12)
            p.lfo1Target = pick([0, 1])   // F1 or F2 cutoff
            p.lfo1Amount = rnd(0.20, 0.50)

        // ── ARP ──────────────────────────────────────────────────────────────
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
            // Signature arp filter sweep LFO — synced feel, medium-high amount
            p.lfo1Rate   = rnd(0.25, 0.80)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.25, 0.50)

        // ── BRASS ────────────────────────────────────────────────────────────
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
            // Subtle LFO tremolo on amplitude
            p.lfo1Rate   = rnd(0.30, 0.70)
            p.lfo1Target = 4   // AMP
            p.lfo1Amount = rnd(0.0, 0.15)

        // ── STRINGS ──────────────────────────────────────────────────────────
        case .strings:
            p.osc1WaveForm    = pick([1, 2])   // Sine or Triangle for smooth timbre
            p.osc2On          = true
            p.osc2Level       = rnd(0.5, 0.85)
            p.osc2Pan         = 1.0 - p.osc1Pan
            p.osc2Transpose   = rnd(-0.3, 0.3) // Slight detune for ensemble thickness
            p.osc2WaveForm    = pick([1, 2])
            p.osc3On          = Bool.random()
            p.osc3Level       = rnd(0.2, 0.5)
            p.osc3Transpose   = rnd(-7, 7)     // Fifth or octave for richness
            p.filterCutoff    = rnd(90, 120)
            p.filterResonance = rnd(0.05, 0.25)
            p.filterDrive     = rnd(0.0, 0.1)
            p.env1Attack      = rnd(0.15, 0.50) // Slow bow attack
            p.env1Decay       = rnd(0.20, 0.50)
            p.env1Sustain     = rnd(0.65, 0.90)
            p.env1Release     = rnd(0.30, 0.65)
            p.reverbMix       = rnd(0.25, 0.55)
            p.chorusMix       = rnd(0.10, 0.35)
            // Dual filters for warmth layering
            p.filter2On        = true
            p.osc2FilterRoute  = 1   // OSC2 → F2 for separate tone shaping
            p.filter2Cutoff    = rnd(85, 115)
            p.filter2Resonance = rnd(0.0, 0.20)
            // Very slow LFO vibrato on filter for natural bow movement
            p.lfo1Rate   = rnd(0.04, 0.15)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.05, 0.20)

        // ── STABS ────────────────────────────────────────────────────────────
        case .stabs:
            p.osc1WaveForm    = pick([0, 3])   // Saw or Square for aggression
            p.osc2On          = Bool.random()
            p.osc2Level       = rnd(0.3, 0.7)
            p.osc2Transpose   = Float(pick([0, 7, 12]))
            p.osc2WaveForm    = pick([0, 3])
            p.filterCutoff    = rnd(55, 95)
            p.filterResonance = rnd(0.35, 0.70)
            p.filterDrive     = rnd(0.15, 0.55)
            p.env1Attack      = rnd(0.001, 0.005) // Instant transient
            p.env1Decay       = rnd(0.06, 0.20)
            p.env1Sustain     = 0.0               // No sustain — pure stab
            p.env1Release     = rnd(0.04, 0.15)
            p.distortionMix   = rnd(0.0, 0.30)
            p.delayMix        = rnd(0.0, 0.20)
            // Second filter for parallel low-end punch
            p.filter2On = Bool.random()
            if p.filter2On && p.osc2On {
                p.osc2FilterRoute  = 1
                p.filter2Cutoff    = rnd(40, 75)
                p.filter2Resonance = rnd(0.2, 0.5)
            }
            // Fast LFO filter sweep for trance-style stabs
            p.lfo1Rate   = rnd(0.50, 1.50)
            p.lfo1Target = 0   // F1 cutoff
            p.lfo1Amount = rnd(0.15, 0.40)
        }
    }
}
