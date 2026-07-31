//
//  VitalAudioEngine.swift
//  Vital Synth
//
//  Swift wrapper around VitalEngineWrapper — drives AVAudioEngine rendering.
//

import AVFoundation
import Combine

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

@MainActor
final class VitalAudioEngine: ObservableObject {

    // MARK: - Published state (UI bindings)
    @Published var isRunning     = false
    @Published var currentPatch  = "Init"

    // MARK: Oscillator 1
    @Published var osc1On:        Bool  = true
    @Published var osc1Level:     Float = 1.0
    @Published var osc1Pan:       Float = 0.5          // 0-1 UI → engine -1..1
    @Published var osc1Transpose: Float = 0.0          // -48..+48 semitones
    @Published var osc1WaveForm:  Int   = 0            // cosmetic index
    @Published var osc1WaveFrame: Float = 0.0          // 0-1 → wave_frame 0-255
    @Published var osc1UnisonVoices: Int = 1           // 1-16
    @Published var osc1UnisonDetune: Float = 0.4472    // 0-1 UI → *10
    @Published var osc1DetunePower: Float = 0.65       // 0-1 → -5..5
    @Published var osc1Phase: Float = 0.5
    @Published var osc1RandomPhase: Float = 1.0
    @Published var osc1SpectralMorphType: Int = 0      // 0-11
    @Published var osc1SpectralMorphAmount: Float = 0.5
    @Published var osc1DistortionType: Int = 0         // 0-12
    @Published var osc1DistortionAmount: Float = 0.5
    @Published var osc1Destination: Int = 0            // 0=F1,1=F2,2=F1+2,3=FX,4=Direct
    @Published var osc1DisplayFrames: [[Float]] = []
    @Published var osc1WavetableName: String = "Init"
    @Published var osc1FilterRoute: Int = 0            // 0=F1, 1=F2, 2=Both

    // MARK: Oscillator 2
    @Published var osc2On:        Bool  = false
    @Published var osc2Level:     Float = 0.0
    @Published var osc2Pan:       Float = 0.5
    @Published var osc2Transpose: Float = 0.0
    @Published var osc2WaveForm:  Int   = 0
    @Published var osc2WaveFrame: Float = 0.0
    @Published var osc2UnisonVoices: Int = 1
    @Published var osc2UnisonDetune: Float = 0.4472
    @Published var osc2DetunePower: Float = 0.65
    @Published var osc2Phase: Float = 0.5
    @Published var osc2RandomPhase: Float = 1.0
    @Published var osc2SpectralMorphType: Int = 0
    @Published var osc2SpectralMorphAmount: Float = 0.5
    @Published var osc2DistortionType: Int = 0
    @Published var osc2DistortionAmount: Float = 0.5
    @Published var osc2Destination: Int = 0
    @Published var osc2DisplayFrames: [[Float]] = []
    @Published var osc2WavetableName: String = "Init"
    @Published var osc2FilterRoute: Int = 0

    // MARK: Oscillator 3
    @Published var osc3On:        Bool  = false
    @Published var osc3Level:     Float = 0.0
    @Published var osc3Pan:       Float = 0.5
    @Published var osc3Transpose: Float = 0.0
    @Published var osc3WaveForm:  Int   = 0
    @Published var osc3WaveFrame: Float = 0.0
    @Published var osc3UnisonVoices: Int = 1
    @Published var osc3UnisonDetune: Float = 0.4472
    @Published var osc3DetunePower: Float = 0.65
    @Published var osc3Phase: Float = 0.5
    @Published var osc3RandomPhase: Float = 1.0
    @Published var osc3SpectralMorphType: Int = 0
    @Published var osc3SpectralMorphAmount: Float = 0.5
    @Published var osc3DistortionType: Int = 0
    @Published var osc3DistortionAmount: Float = 0.5
    @Published var osc3Destination: Int = 0
    @Published var osc3DisplayFrames: [[Float]] = []
    @Published var osc3WavetableName: String = "Init"
    @Published var osc3FilterRoute: Int = 0

    // MARK: Sample
    @Published var sampleOn: Bool = false
    @Published var sampleLevel: Float = 0.7071
    @Published var samplePan: Float = 0.5
    @Published var sampleTranspose: Float = 0.0
    @Published var sampleLoop: Bool = true
    @Published var sampleBounce: Bool = false
    @Published var sampleKeytrack: Bool = false
    /// Downsampled preview of the loaded sample for the SMP waveform viewer.
    @Published var sampleDisplayFrames: [Float] = []

    // MARK: Filters — model: Analog/Dirty/Ladder/Digital/Diode/Formant/Comb/Phaser (0-7)
    static let filterModelNames = ["Analog", "Dirty", "Ladder", "Digital", "Diode", "Formant", "Comb", "Phaser"]

    @Published var filter1On:        Bool  = true
    @Published var filterCutoff:     Float = 100.0  // MIDI note 8-136
    @Published var filterResonance:  Float = 0.5
    @Published var filterDrive:      Float = 0.0    // 0-1 → *20
    @Published var filterModel:      Int   = 0
    @Published var filter1Blend:     Float = 0.0    // 0-1 UI → *2 (Vital 0-2)
    @Published var filter1Style:     Int   = 0

    @Published var filter2On:        Bool  = true
    @Published var filter2Cutoff:    Float = 100.0
    @Published var filter2Resonance: Float = 0.5
    @Published var filter2Drive:     Float = 0.0
    @Published var filter2Model:     Int   = 0
    @Published var filter2Blend:     Float = 0.0
    @Published var filter2Style:     Int   = 0

    // MARK: Envelopes 1-6
    @Published var env1Attack:  Float = 0.003
    @Published var env1Hold:    Float = 0.0
    @Published var env1Decay:   Float = 0.25
    @Published var env1Sustain: Float = 0.70
    @Published var env1Release: Float = 0.40

    @Published var env2Attack:  Float = 0.003
    @Published var env2Hold:    Float = 0.0
    @Published var env2Decay:   Float = 0.40
    @Published var env2Sustain: Float = 0.0
    @Published var env2Release: Float = 0.30

    @Published var env3Attack:  Float = 0.0
    @Published var env3Hold:    Float = 0.0
    @Published var env3Decay:   Float = 1.0
    @Published var env3Sustain: Float = 1.0
    @Published var env3Release: Float = 0.5476

    @Published var env4Attack:  Float = 0.0
    @Published var env4Hold:    Float = 0.0
    @Published var env4Decay:   Float = 1.0
    @Published var env4Sustain: Float = 1.0
    @Published var env4Release: Float = 0.5476

    @Published var env5Attack:  Float = 0.0
    @Published var env5Hold:    Float = 0.0
    @Published var env5Decay:   Float = 1.0
    @Published var env5Sustain: Float = 1.0
    @Published var env5Release: Float = 0.5476

    @Published var env6Attack:  Float = 0.0
    @Published var env6Hold:    Float = 0.0
    @Published var env6Decay:   Float = 1.0
    @Published var env6Sustain: Float = 1.0
    @Published var env6Release: Float = 0.5476

    // MARK: LFOs 1-8
    static let lfoTargets = [
        "filter_1_cutoff", "filter_2_cutoff",
        "osc_1_level", "osc_2_level", "osc_3_level",
        "osc_1_wave_frame", "osc_2_wave_frame", "osc_3_wave_frame",
        "volume", "reverb_dry_wet", "delay_dry_wet"
    ]
    static let lfoTargetNames = [
        "F1 CUT", "F2 CUT",
        "O1 VOL", "O2 VOL", "O3 VOL",
        "O1 FRAME", "O2 FRAME", "O3 FRAME",
        "MASTER", "REVERB", "DELAY"
    ]

    @Published var lfoRates:   [Float] = Array(repeating: 0.25, count: 8)  // 0-1 → -7+16*v
    @Published var lfoPhases:  [Float] = Array(repeating: 0.0, count: 8)
    @Published var lfoSyncs:   [Int]   = Array(repeating: 1, count: 8)
    @Published var lfoAmounts: [Float] = [0.3, 0, 0, 0, 0, 0, 0, 0]
    @Published var lfoTargets: [Int]   = Array(repeating: 0, count: 8)

    // Convenience mirrors for existing LFO 1 UI bindings
    @Published var lfo1Rate:   Float = 0.25
    @Published var lfo1Amount: Float = 0.3
    @Published var lfo1Target: Int   = 0

    // MARK: Random LFOs 1-4
    @Published var randomStyle: [Int]   = Array(repeating: 0, count: 4)
    @Published var randomRate:  [Float] = Array(repeating: 0.5, count: 4)  // 0-1 → -7+16*v

    // MARK: Macros 1-4
    @Published var macro: [Float] = Array(repeating: 0.0, count: 4)

    // MARK: FX — Chorus
    @Published var chorusOn: Bool = false
    @Published var chorusMix: Float = 0.0
    @Published var chorusFeedback: Float = 0.5       // 0-1 → -0.95..0.95
    @Published var chorusModDepth: Float = 0.5
    @Published var chorusFrequency: Float = 0.333     // 0-1 → -6..3

    // MARK: FX — Compressor
    @Published var compressorOn: Bool = false
    @Published var compressorMix: Float = 1.0
    @Published var compressorAttack: Float = 0.5
    @Published var compressorRelease: Float = 0.5

    // MARK: FX — Delay
    @Published var delayOn: Bool = false
    @Published var delayMix: Float = 0.0
    @Published var delayFeedback: Float = 0.5         // 0-1 → -1..1
    @Published var delayFrequency: Float = 0.3636     // 0-1 → -2..9

    // MARK: FX — Distortion
    @Published var distortionOn: Bool = false
    @Published var distortionMix: Float = 0.0
    @Published var distortionDrive: Float = 0.5       // 0-1 → -30..30
    @Published var distortionType: Int = 0

    // MARK: FX — Equalizer (Vital: eq_*)
    @Published var equalizerOn: Bool = false
    @Published var equalizerLowGain: Float = 0.0
    @Published var equalizerMidGain: Float = 0.0
    @Published var equalizerHighGain: Float = 0.0

    // MARK: FX — Filter FX
    @Published var filterFxOn: Bool = false
    @Published var filterFxCutoff: Float = 60.0
    @Published var filterFxResonance: Float = 0.5

    // MARK: FX — Flanger
    @Published var flangerOn: Bool = false
    @Published var flangerDryWet: Float = 0.0
    @Published var flangerFeedback: Float = 0.5       // 0-1 → -1..1
    @Published var flangerCenter: Float = 64.0
    @Published var flangerModDepth: Float = 0.5

    // MARK: FX — Phaser
    @Published var phaserOn: Bool = false
    @Published var phaserDryWet: Float = 0.0
    @Published var phaserFeedback: Float = 0.5
    @Published var phaserCenter: Float = 80.0
    @Published var phaserModDepth: Float = 0.5        // 0-1 → *48

    // MARK: FX — Reverb
    @Published var reverbOn: Bool = false
    @Published var reverbMix: Float = 0.0
    @Published var reverbSize: Float = 0.5
    @Published var reverbDecay: Float = 0.5           // 0-1 → -6+12*v
    @Published var reverbChorusAmount: Float = 0.2236

    // MARK: FX chain order (Vital effect_chain_order factorial encoding)
    /// Indices into Vital's Effect enum order: chorus=0 … reverb=8
    @Published var effectChainOrder: [Int] = Array(0..<9)

    // MARK: Voice
    @Published var legato: Bool = false
    @Published var glide: Float = 0.0                 // 0=off, 1=max (portamento_time -10..4)
    @Published var polyphony: Int = 16
    @Published var pitchBendRange: Float = 2.0        // 0-48

    @Published var masterVolume: Float = 0.8601       // maps to raw ≈5473 → ≈ -6 dB

    // MARK: Modulation matrix
    @Published var modConnections: [ModConnection] = []

    // MARK: - Private
    private let engine    = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var wrapper: VitalEngineWrapper?
    // Serial queue ensures wavetable loads don't run concurrently
    private let loadQueue = DispatchQueue(label: "com.vitalsynth.wavetableLoad", qos: .userInitiated)

    private var pendingNoteOns: [(note: Int, vel: Float)] = []

    // MARK: - Setup

    func start() {
        guard !isRunning else { return }
        configureAudioSession()

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let sampleRate = format.sampleRate

        let w = VitalEngineWrapper(sampleRate: sampleRate)
        wrapper = w

        let node = AVAudioSourceNode(format: format) { [weak w] _, _, frameCount, audioBufferList -> OSStatus in
            guard let w else { return noErr }
            let ablp = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let n = Int(frameCount)

            if ablp.count >= 2,
               let l = ablp[0].mData?.assumingMemoryBound(to: Float.self),
               let r = ablp[1].mData?.assumingMemoryBound(to: Float.self) {
                w.render(intoLeft: l, right: r, numFrames: Int32(n))
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        do {
            try engine.start()
            isRunning = true
            syncAllPublishedToEngine()
            loadEffectChainOrder()
            // Pre-connect all 8 LFOs to every target at amount 0,
            // then activate the selected targets. Avoids disconnect/reconnect
            // on target changes, which can trigger Vital engine assertions.
            for lfoIdx in 1...8 {
                let source = "lfo_\(lfoIdx)"
                for t in Self.lfoTargets {
                    _ = wrapper?.connectModulation(source, to: t, amount: 0.0)
                }
                let ti = min(lfoTargets[lfoIdx - 1], Self.lfoTargets.count - 1)
                let active = Self.lfoTargets[ti]
                let amount = lfoAmounts[lfoIdx - 1]
                if amount != 0 {
                    wrapper?.setModulationAmount(amount, source: source, destination: active)
                }
            }
            // Wire mod wheel → filter 1 cutoff
            _ = wrapper?.connectModulation("mod_wheel", to: "filter_1_cutoff", amount: 0.5)
            refreshModulations()
            refreshSampleDisplay()
        } catch {
            print("VitalAudioEngine: AVAudioEngine start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    // MARK: - MIDI

    func noteOn(note: Int, velocity: Float) {
        wrapper?.note(on: Int32(note), velocity: velocity, channel: 1)
    }

    func noteOff(note: Int) {
        wrapper?.noteOff(Int32(note), lift: 0, channel: 1)
    }

    func allNotesOff() {
        wrapper?.allNotesOff()
    }

    func pitchBend(_ normalizedValue: Float) {
        // normalizedValue: 0 = down, 0.5 = center, 1 = up  →  vital wants -1…+1
        wrapper?.setPitchWheel((normalizedValue - 0.5) * 2.0, channel: 1)
    }

    func modWheel(_ value: Float) {
        wrapper?.setModWheel(value, channel: 1)
    }

    // MARK: - Parameter helpers

    func setParameter(_ name: String, _ value: Float) {
        wrapper?.setParameter(name, value: value)
    }

    func setParameterRaw(_ name: String, _ value: Float) {
        setParameter(name, value)
    }

    // MARK: - Oscillator 1 setters

    func setOsc1On(_ v: Bool)          { osc1On = v;         setParameter("osc_1_on",            v ? 1 : 0) }
    func setOsc1Level(_ v: Float)      { osc1Level = v;      setParameter("osc_1_level",         v) }
    func setOsc1Pan(_ v: Float)        { osc1Pan = v;        setParameter("osc_1_pan",           v * 2 - 1) }
    func setOsc1Transpose(_ v: Float)  { osc1Transpose = v;  setParameter("osc_1_transpose",     v) }
    func setOsc1Waveform(_ shape: Int) {
        osc1WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc1WaveFrame = f
        setParameter("osc_1_wave_frame", f * 255.0)
    }
    func setOsc1WaveFrame(_ v: Float) {
        osc1WaveFrame = v
        setParameter("osc_1_wave_frame", v * 255.0)
    }
    func setOsc1UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16)
        osc1UnisonVoices = c
        setParameter("osc_1_unison_voices", Float(c))
    }
    func setOsc1UnisonDetune(_ v: Float) {
        osc1UnisonDetune = v
        setParameter("osc_1_unison_detune", v * 10.0)
    }
    func setOsc1DetunePower(_ v: Float) {
        osc1DetunePower = v
        setParameter("osc_1_detune_power", -5 + 10 * v)
    }
    func setOsc1Phase(_ v: Float) {
        osc1Phase = v
        setParameter("osc_1_phase", v)
    }
    func setOsc1RandomPhase(_ v: Float) {
        osc1RandomPhase = v
        setParameter("osc_1_random_phase", v)
    }
    func setOsc1SpectralMorphType(_ v: Int) {
        osc1SpectralMorphType = min(max(v, 0), 11)
        setParameter("osc_1_spectral_morph_type", Float(osc1SpectralMorphType))
    }
    func setOsc1SpectralMorphAmount(_ v: Float) {
        osc1SpectralMorphAmount = v
        setParameter("osc_1_spectral_morph_amount", v)
    }
    func setOsc1DistortionType(_ v: Int) {
        osc1DistortionType = min(max(v, 0), 12)
        setParameter("osc_1_distortion_type", Float(osc1DistortionType))
    }
    func setOsc1DistortionAmount(_ v: Float) {
        osc1DistortionAmount = v
        setParameter("osc_1_distortion_amount", v)
    }
    func setOsc1Destination(_ v: Int) {
        osc1Destination = v
        setParameter("osc_1_destination", Float(v))
        if v <= 2 {
            osc1FilterRoute = v
            applyOscRouting(1, route: v)
        }
    }

    // MARK: - Oscillator 2 setters

    func setOsc2On(_ v: Bool)          { osc2On = v;         setParameter("osc_2_on",            v ? 1 : 0) }
    func setOsc2Level(_ v: Float)      { osc2Level = v;      setParameter("osc_2_level",         v) }
    func setOsc2Pan(_ v: Float)        { osc2Pan = v;        setParameter("osc_2_pan",           v * 2 - 1) }
    func setOsc2Transpose(_ v: Float)  { osc2Transpose = v;  setParameter("osc_2_transpose",     v) }
    func setOsc2Waveform(_ shape: Int) {
        osc2WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc2WaveFrame = f
        setParameter("osc_2_wave_frame", f * 255.0)
    }
    func setOsc2WaveFrame(_ v: Float) {
        osc2WaveFrame = v
        setParameter("osc_2_wave_frame", v * 255.0)
    }
    func setOsc2UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16)
        osc2UnisonVoices = c
        setParameter("osc_2_unison_voices", Float(c))
    }
    func setOsc2UnisonDetune(_ v: Float) {
        osc2UnisonDetune = v
        setParameter("osc_2_unison_detune", v * 10.0)
    }
    func setOsc2DetunePower(_ v: Float) {
        osc2DetunePower = v
        setParameter("osc_2_detune_power", -5 + 10 * v)
    }
    func setOsc2Phase(_ v: Float) {
        osc2Phase = v
        setParameter("osc_2_phase", v)
    }
    func setOsc2RandomPhase(_ v: Float) {
        osc2RandomPhase = v
        setParameter("osc_2_random_phase", v)
    }
    func setOsc2SpectralMorphType(_ v: Int) {
        osc2SpectralMorphType = min(max(v, 0), 11)
        setParameter("osc_2_spectral_morph_type", Float(osc2SpectralMorphType))
    }
    func setOsc2SpectralMorphAmount(_ v: Float) {
        osc2SpectralMorphAmount = v
        setParameter("osc_2_spectral_morph_amount", v)
    }
    func setOsc2DistortionType(_ v: Int) {
        osc2DistortionType = min(max(v, 0), 12)
        setParameter("osc_2_distortion_type", Float(osc2DistortionType))
    }
    func setOsc2DistortionAmount(_ v: Float) {
        osc2DistortionAmount = v
        setParameter("osc_2_distortion_amount", v)
    }
    func setOsc2Destination(_ v: Int) {
        osc2Destination = v
        setParameter("osc_2_destination", Float(v))
        if v <= 2 {
            osc2FilterRoute = v
            applyOscRouting(2, route: v)
        }
    }

    // MARK: - Oscillator 3 setters

    func setOsc3On(_ v: Bool)          { osc3On = v;         setParameter("osc_3_on",            v ? 1 : 0) }
    func setOsc3Level(_ v: Float)      { osc3Level = v;      setParameter("osc_3_level",         v) }
    func setOsc3Pan(_ v: Float)        { osc3Pan = v;        setParameter("osc_3_pan",           v * 2 - 1) }
    func setOsc3Transpose(_ v: Float)  { osc3Transpose = v;  setParameter("osc_3_transpose",     v) }
    func setOsc3Waveform(_ shape: Int) {
        osc3WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc3WaveFrame = f
        setParameter("osc_3_wave_frame", f * 255.0)
    }
    func setOsc3WaveFrame(_ v: Float) {
        osc3WaveFrame = v
        setParameter("osc_3_wave_frame", v * 255.0)
    }
    func setOsc3UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16)
        osc3UnisonVoices = c
        setParameter("osc_3_unison_voices", Float(c))
    }
    func setOsc3UnisonDetune(_ v: Float) {
        osc3UnisonDetune = v
        setParameter("osc_3_unison_detune", v * 10.0)
    }
    func setOsc3DetunePower(_ v: Float) {
        osc3DetunePower = v
        setParameter("osc_3_detune_power", -5 + 10 * v)
    }
    func setOsc3Phase(_ v: Float) {
        osc3Phase = v
        setParameter("osc_3_phase", v)
    }
    func setOsc3RandomPhase(_ v: Float) {
        osc3RandomPhase = v
        setParameter("osc_3_random_phase", v)
    }
    func setOsc3SpectralMorphType(_ v: Int) {
        osc3SpectralMorphType = min(max(v, 0), 11)
        setParameter("osc_3_spectral_morph_type", Float(osc3SpectralMorphType))
    }
    func setOsc3SpectralMorphAmount(_ v: Float) {
        osc3SpectralMorphAmount = v
        setParameter("osc_3_spectral_morph_amount", v)
    }
    func setOsc3DistortionType(_ v: Int) {
        osc3DistortionType = min(max(v, 0), 12)
        setParameter("osc_3_distortion_type", Float(osc3DistortionType))
    }
    func setOsc3DistortionAmount(_ v: Float) {
        osc3DistortionAmount = v
        setParameter("osc_3_distortion_amount", v)
    }
    func setOsc3Destination(_ v: Int) {
        osc3Destination = v
        setParameter("osc_3_destination", Float(v))
        if v <= 2 {
            osc3FilterRoute = v
            applyOscRouting(3, route: v)
        }
    }

    // MARK: - Sample setters

    func setSampleOn(_ v: Bool) {
        sampleOn = v
        setParameter("sample_on", v ? 1 : 0)
    }
    func setSampleLevel(_ v: Float) {
        sampleLevel = v
        setParameter("sample_level", v)
    }
    func setSamplePan(_ v: Float) {
        samplePan = v
        setParameter("sample_pan", v * 2 - 1)
    }
    func setSampleTranspose(_ v: Float) {
        sampleTranspose = v
        setParameter("sample_transpose", v)
    }
    func setSampleLoop(_ v: Bool) {
        sampleLoop = v
        setParameter("sample_loop", v ? 1 : 0)
    }
    func setSampleBounce(_ v: Bool) {
        sampleBounce = v
        setParameter("sample_bounce", v ? 1 : 0)
    }
    func setSampleKeytrack(_ v: Bool) {
        sampleKeytrack = v
        setParameter("sample_keytrack", v ? 1 : 0)
    }

    // MARK: - Filter setters

    func setFilter1On(_ v: Bool)         { filter1On = v;       setParameter("filter_1_on",         v ? 1 : 0) }
    func setFilterCutoff(_ v: Float)     { filterCutoff = v;    setParameter("filter_1_cutoff",    v) }
    func setFilterResonance(_ v: Float)  { filterResonance = v; setParameter("filter_1_resonance", v) }
    func setFilterDrive(_ v: Float)      { filterDrive = v;     setParameter("filter_1_drive",     v * 20.0) }
    func setFilterModel(_ model: Int) {
        filterModel = min(max(model, 0), 7)
        setParameter("filter_1_model", Float(filterModel))
    }
    func setFilter1Blend(_ v: Float) {
        filter1Blend = v
        setParameter("filter_1_blend", v * 2.0)
    }
    func setFilter1Style(_ v: Int) {
        filter1Style = v
        setParameter("filter_1_style", Float(v))
    }

    func setFilter2On(_ v: Bool)         { filter2On = v;        setParameter("filter_2_on",         v ? 1 : 0) }
    func setFilter2Cutoff(_ v: Float)    { filter2Cutoff = v;    setParameter("filter_2_cutoff",    v) }
    func setFilter2Resonance(_ v: Float) { filter2Resonance = v; setParameter("filter_2_resonance", v) }
    func setFilter2Drive(_ v: Float)     { filter2Drive = v;     setParameter("filter_2_drive",     v * 20.0) }
    func setFilter2Model(_ model: Int) {
        filter2Model = min(max(model, 0), 7)
        setParameter("filter_2_model", Float(filter2Model))
    }
    func setFilter2Blend(_ v: Float) {
        filter2Blend = v
        setParameter("filter_2_blend", v * 2.0)
    }
    func setFilter2Style(_ v: Int) {
        filter2Style = v
        setParameter("filter_2_style", Float(v))
    }

    /// Vital names are `filter_N_oscM_input` (no underscore between osc and index).
    private func applyOscRouting(_ oscIdx: Int, route: Int) {
        let f1 = Float(route == 1 ? 0 : 1)   // F2-only → no signal to F1
        let f2 = Float(route == 0 ? 0 : 1)   // F1-only → no signal to F2
        setParameter("filter_1_osc\(oscIdx)_input", f1)
        setParameter("filter_2_osc\(oscIdx)_input", f2)
    }

    /// Convenience: sets destination (0-2) AND filter_N_oscM_input routing.
    func setOsc1FilterRoute(_ v: Int) {
        osc1FilterRoute = v
        osc1Destination = v
        setParameter("osc_1_destination", Float(v))
        applyOscRouting(1, route: v)
    }
    func setOsc2FilterRoute(_ v: Int) {
        osc2FilterRoute = v
        osc2Destination = v
        setParameter("osc_2_destination", Float(v))
        applyOscRouting(2, route: v)
    }
    func setOsc3FilterRoute(_ v: Int) {
        osc3FilterRoute = v
        osc3Destination = v
        setParameter("osc_3_destination", Float(v))
        applyOscRouting(3, route: v)
    }

    // MARK: - Envelope setters

    func setEnv1Attack(_ v: Float)   { env1Attack = v;   setParameter("env_1_attack",  v) }
    func setEnv1Hold(_ v: Float)     { env1Hold = v;     setParameter("env_1_hold",    v) }
    func setEnv1Decay(_ v: Float)    { env1Decay = v;    setParameter("env_1_decay",   v) }
    func setEnv1Sustain(_ v: Float)  { env1Sustain = v;  setParameter("env_1_sustain", v) }
    func setEnv1Release(_ v: Float)  { env1Release = v;  setParameter("env_1_release", v) }

    func setEnv2Attack(_ v: Float)   { env2Attack = v;   setParameter("env_2_attack",  v) }
    func setEnv2Hold(_ v: Float)     { env2Hold = v;     setParameter("env_2_hold",    v) }
    func setEnv2Decay(_ v: Float)    { env2Decay = v;    setParameter("env_2_decay",   v) }
    func setEnv2Sustain(_ v: Float)  { env2Sustain = v;  setParameter("env_2_sustain", v) }
    func setEnv2Release(_ v: Float)  { env2Release = v;  setParameter("env_2_release", v) }

    func setEnv3Attack(_ v: Float)   { env3Attack = v;   setParameter("env_3_attack",  v) }
    func setEnv3Hold(_ v: Float)     { env3Hold = v;     setParameter("env_3_hold",    v) }
    func setEnv3Decay(_ v: Float)    { env3Decay = v;    setParameter("env_3_decay",   v) }
    func setEnv3Sustain(_ v: Float)  { env3Sustain = v;  setParameter("env_3_sustain", v) }
    func setEnv3Release(_ v: Float)  { env3Release = v;  setParameter("env_3_release", v) }

    func setEnv4Attack(_ v: Float)   { env4Attack = v;   setParameter("env_4_attack",  v) }
    func setEnv4Hold(_ v: Float)     { env4Hold = v;     setParameter("env_4_hold",    v) }
    func setEnv4Decay(_ v: Float)    { env4Decay = v;    setParameter("env_4_decay",   v) }
    func setEnv4Sustain(_ v: Float)  { env4Sustain = v;  setParameter("env_4_sustain", v) }
    func setEnv4Release(_ v: Float)  { env4Release = v;  setParameter("env_4_release", v) }

    func setEnv5Attack(_ v: Float)   { env5Attack = v;   setParameter("env_5_attack",  v) }
    func setEnv5Hold(_ v: Float)     { env5Hold = v;     setParameter("env_5_hold",    v) }
    func setEnv5Decay(_ v: Float)    { env5Decay = v;    setParameter("env_5_decay",   v) }
    func setEnv5Sustain(_ v: Float)  { env5Sustain = v;  setParameter("env_5_sustain", v) }
    func setEnv5Release(_ v: Float)  { env5Release = v;  setParameter("env_5_release", v) }

    func setEnv6Attack(_ v: Float)   { env6Attack = v;   setParameter("env_6_attack",  v) }
    func setEnv6Hold(_ v: Float)     { env6Hold = v;     setParameter("env_6_hold",    v) }
    func setEnv6Decay(_ v: Float)    { env6Decay = v;    setParameter("env_6_decay",   v) }
    func setEnv6Sustain(_ v: Float)  { env6Sustain = v;  setParameter("env_6_sustain", v) }
    func setEnv6Release(_ v: Float)  { env6Release = v;  setParameter("env_6_release", v) }

    // MARK: - LFO setters

    /// Map UI 0-1 rate into Vital's exponential LFO frequency domain (-7…9).
    private static func lfoFrequency(fromNormalized v: Float) -> Float {
        -7 + 16 * v
    }
    private static func normalizedLfoRate(fromFrequency f: Float) -> Float {
        min(1, max(0, (f + 7) / 16))
    }

    func setLfoRate(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoRates[index] = v
        if index == 0 { lfo1Rate = v }
        setParameter("lfo_\(index + 1)_frequency", Self.lfoFrequency(fromNormalized: v))
    }

    func setLfoPhase(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoPhases[index] = v
        setParameter("lfo_\(index + 1)_phase", v)
    }

    func setLfoSync(_ index: Int, _ v: Int) {
        guard (0..<8).contains(index) else { return }
        lfoSyncs[index] = v
        setParameter("lfo_\(index + 1)_sync", Float(v))
    }

    func setLfoAmount(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoAmounts[index] = v
        if index == 0 { lfo1Amount = v }
        let ti = min(lfoTargets[index], Self.lfoTargets.count - 1)
        let target = Self.lfoTargets[ti]
        wrapper?.setModulationAmount(v, source: "lfo_\(index + 1)", destination: target)
    }

    func setLfoTarget(_ index: Int, _ t: Int) {
        guard (0..<8).contains(index) else { return }
        let oldTi = min(lfoTargets[index], Self.lfoTargets.count - 1)
        let oldTarget = Self.lfoTargets[oldTi]
        wrapper?.setModulationAmount(0, source: "lfo_\(index + 1)", destination: oldTarget)
        lfoTargets[index] = t
        if index == 0 { lfo1Target = t }
        let newTi = min(t, Self.lfoTargets.count - 1)
        let newTarget = Self.lfoTargets[newTi]
        wrapper?.setModulationAmount(lfoAmounts[index], source: "lfo_\(index + 1)", destination: newTarget)
    }

    func setLfo1Rate(_ v: Float)   { setLfoRate(0, v) }
    func setLfo1Amount(_ v: Float) { setLfoAmount(0, v) }
    func setLfo1Target(_ t: Int)   { setLfoTarget(0, t) }

    // MARK: - Random LFO setters

    func setRandomStyle(_ index: Int, _ v: Int) {
        guard (0..<4).contains(index) else { return }
        randomStyle[index] = v
        setParameter("random_\(index + 1)_style", Float(v))
    }

    func setRandomRate(_ index: Int, _ v: Float) {
        guard (0..<4).contains(index) else { return }
        randomRate[index] = v
        setParameter("random_\(index + 1)_frequency", Self.lfoFrequency(fromNormalized: v))
    }

    // MARK: - Macro setters

    func setMacro(_ index: Int, _ v: Float) {
        guard (0..<4).contains(index) else { return }
        macro[index] = v
        setParameter("macro_control_\(index + 1)", v)
    }

    // MARK: - FX setters

    func setChorusOn(_ v: Bool) {
        chorusOn = v
        setParameter("chorus_on", v ? 1 : 0)
    }
    func setChorusMix(_ v: Float) {
        chorusMix = v
        setParameter("chorus_dry_wet", v)
        if v > 0.01 { chorusOn = true }
        setParameter("chorus_on", (chorusOn || v > 0.01) ? 1 : 0)
    }
    func setChorusFeedback(_ v: Float) {
        chorusFeedback = v
        setParameter("chorus_feedback", -0.95 + 1.9 * v)
    }
    func setChorusModDepth(_ v: Float) {
        chorusModDepth = v
        setParameter("chorus_mod_depth", v)
    }
    func setChorusFrequency(_ v: Float) {
        chorusFrequency = v
        setParameter("chorus_frequency", -6 + 9 * v)
    }

    func setCompressorOn(_ v: Bool) {
        compressorOn = v
        setParameter("compressor_on", v ? 1 : 0)
    }
    func setCompressorMix(_ v: Float) {
        compressorMix = v
        setParameter("compressor_mix", v)
    }
    func setCompressorAttack(_ v: Float) {
        compressorAttack = v
        setParameter("compressor_attack", v)
    }
    func setCompressorRelease(_ v: Float) {
        compressorRelease = v
        setParameter("compressor_release", v)
    }

    func setDelayOn(_ v: Bool) {
        delayOn = v
        setParameter("delay_on", v ? 1 : 0)
    }
    func setDelayMix(_ v: Float) {
        delayMix = v
        setParameter("delay_dry_wet", v)
        if v > 0.01 { delayOn = true }
        setParameter("delay_on", (delayOn || v > 0.01) ? 1 : 0)
    }
    func setDelayFeedback(_ v: Float) {
        delayFeedback = v
        setParameter("delay_feedback", v * 2 - 1)
    }
    func setDelayFrequency(_ v: Float) {
        delayFrequency = v
        setParameter("delay_frequency", -2 + 11 * v)
    }

    func setDistortionOn(_ v: Bool) {
        distortionOn = v
        setParameter("distortion_on", v ? 1 : 0)
    }
    func setDistortionMix(_ v: Float) {
        distortionMix = v
        setParameter("distortion_mix", v)
        if v > 0.01 { distortionOn = true }
        setParameter("distortion_on", (distortionOn || v > 0.01) ? 1 : 0)
    }
    func setDistortionDrive(_ v: Float) {
        distortionDrive = v
        setParameter("distortion_drive", -30 + 60 * v)
    }
    func setDistortionType(_ v: Int) {
        distortionType = v
        setParameter("distortion_type", Float(v))
    }

    func setEqualizerOn(_ v: Bool) {
        equalizerOn = v
        // Vital parameter is eq_on; also poke equalizer_on for wrapper init parity.
        setParameter("eq_on", v ? 1 : 0)
        setParameter("equalizer_on", v ? 1 : 0)
    }
    func setEqualizerLowGain(_ v: Float) {
        equalizerLowGain = v
        setParameter("eq_low_gain", v)
    }
    func setEqualizerMidGain(_ v: Float) {
        equalizerMidGain = v
        setParameter("eq_band_gain", v)
    }
    func setEqualizerHighGain(_ v: Float) {
        equalizerHighGain = v
        setParameter("eq_high_gain", v)
    }

    func setFilterFxOn(_ v: Bool) {
        filterFxOn = v
        setParameter("filter_fx_on", v ? 1 : 0)
    }
    func setFilterFxCutoff(_ v: Float) {
        filterFxCutoff = v
        setParameter("filter_fx_cutoff", v)
    }
    func setFilterFxResonance(_ v: Float) {
        filterFxResonance = v
        setParameter("filter_fx_resonance", v)
    }

    func setFlangerOn(_ v: Bool) {
        flangerOn = v
        setParameter("flanger_on", v ? 1 : 0)
    }
    func setFlangerDryWet(_ v: Float) {
        flangerDryWet = v
        setParameter("flanger_dry_wet", v)
        if v > 0.01 { flangerOn = true }
        setParameter("flanger_on", (flangerOn || v > 0.01) ? 1 : 0)
    }
    func setFlangerFeedback(_ v: Float) {
        flangerFeedback = v
        setParameter("flanger_feedback", v * 2 - 1)
    }
    func setFlangerCenter(_ v: Float) {
        flangerCenter = v
        setParameter("flanger_center", v)
    }
    func setFlangerModDepth(_ v: Float) {
        flangerModDepth = v
        setParameter("flanger_mod_depth", v)
    }

    func setPhaserOn(_ v: Bool) {
        phaserOn = v
        setParameter("phaser_on", v ? 1 : 0)
    }
    func setPhaserDryWet(_ v: Float) {
        phaserDryWet = v
        setParameter("phaser_dry_wet", v)
        if v > 0.01 { phaserOn = true }
        setParameter("phaser_on", (phaserOn || v > 0.01) ? 1 : 0)
    }
    func setPhaserFeedback(_ v: Float) {
        phaserFeedback = v
        setParameter("phaser_feedback", v)
    }
    func setPhaserCenter(_ v: Float) {
        phaserCenter = v
        setParameter("phaser_center", v)
    }
    func setPhaserModDepth(_ v: Float) {
        phaserModDepth = v
        setParameter("phaser_mod_depth", v * 48.0)
    }

    func setReverbOn(_ v: Bool) {
        reverbOn = v
        setParameter("reverb_on", v ? 1 : 0)
    }
    func setReverbMix(_ v: Float) {
        reverbMix = v
        setParameter("reverb_dry_wet", v)
        if v > 0.01 { reverbOn = true }
        setParameter("reverb_on", (reverbOn || v > 0.01) ? 1 : 0)
    }
    func setReverbSize(_ v: Float) {
        reverbSize = v
        setParameter("reverb_size", v)
    }
    func setReverbDecay(_ v: Float) {
        reverbDecay = v
        setParameter("reverb_decay_time", -6 + 12 * v)
    }
    func setReverbChorusAmount(_ v: Float) {
        reverbChorusAmount = v
        setParameter("reverb_chorus_amount", v)
    }

    // MARK: - Effect chain order

    func loadEffectChainOrder() {
        let code = wrapper?.getParameter("effect_chain_order") ?? 0
        effectChainOrder = Self.decodeEffectOrder(code, size: 9)
    }

    func setEffectChainOrder(_ order: [Int]) {
        guard order.count == 9, Set(order) == Set(0..<9) else { return }
        effectChainOrder = order
        setParameter("effect_chain_order", Self.encodeEffectOrder(order))
    }

    /// Vital utils::encodeOrderToFloat
    static func encodeEffectOrder(_ order: [Int]) -> Float {
        var code: UInt = 0
        for i in 1..<order.count {
            var index = 0
            for j in 0..<i where order[i] < order[j] { index += 1 }
            code *= UInt(i + 1)
            code += UInt(index)
        }
        return Float(code)
    }

    /// Vital utils::decodeFloatToOrder
    static func decodeEffectOrder(_ floatCode: Float, size: Int) -> [Int] {
        var code = Int(floatCode)
        var order = Array(0..<size)
        for i in 0..<size {
            let remaining = size - i
            let index = remaining - 1
            let inversions = code % remaining
            code /= remaining
            let placement = order[index - inversions]
            var j = index - inversions
            while j < index {
                order[j] = order[j + 1]
                j += 1
            }
            order[index] = placement
        }
        return order
    }

    // MARK: - Voice setters

    func setLegato(_ v: Bool) {
        legato = v
        setParameter("legato", v ? 1 : 0)
        // Preserve existing UI behaviour: legato forces mono; leaving restores polyphony.
        setParameter("polyphony", v ? 1 : Float(polyphony))
    }
    func setGlide(_ v: Float) {
        glide = v
        // portamento_time: -10 (off) to 4 (max) — linear map from 0-1
        setParameter("portamento_time", -10 + 14 * v)
    }
    func setPolyphony(_ v: Int) {
        let c = min(max(v, 1), 32)
        polyphony = c
        if !legato {
            setParameter("polyphony", Float(c))
        }
    }
    func setPitchBendRange(_ v: Float) {
        pitchBendRange = min(max(v, 0), 48)
        setParameter("pitch_bend_range", pitchBendRange)
    }

    func setMasterVolume(_ v: Float)  {
        masterVolume = v
        // Vital's volume is in linear amplitude squared * 7399, approx
        setParameter("volume", v * v * 7399.44)
    }

    // MARK: - Modulation matrix

    @Published var modulationSources: [String] = []
    @Published var modulationDestinations: [String] = []

    func addModulation(source: String, destination: String, amount: Float) {
        _ = wrapper?.connectModulation(source, to: destination, amount: amount)
        refreshModulations()
    }

    func updateModulation(id: UUID, amount: Float) {
        guard let idx = modConnections.firstIndex(where: { $0.id == id }) else { return }
        let conn = modConnections[idx]
        wrapper?.setModulationAmount(amount, source: conn.source, destination: conn.destination)
        modConnections[idx].amount = amount
    }

    func updateModulation(source: String, destination: String, amount: Float) {
        wrapper?.setModulationAmount(amount, source: source, destination: destination)
        if let idx = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[idx].amount = amount
        } else {
            refreshModulations()
        }
    }

    func setModulationBipolar(source: String, destination: String, _ v: Bool) {
        wrapper?.setModulationBipolar(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].bipolar = v
        }
    }

    func setModulationStereo(source: String, destination: String, _ v: Bool) {
        wrapper?.setModulationStereo(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].stereo = v
        }
    }

    func setModulationBypass(source: String, destination: String, _ v: Bool) {
        wrapper?.setModulationBypass(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].bypass = v
        }
    }

    func setModulationPower(source: String, destination: String, _ v: Float) {
        wrapper?.setModulationPower(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].power = v
        }
    }

    func removeModulation(id: UUID) {
        guard let idx = modConnections.firstIndex(where: { $0.id == id }) else { return }
        let conn = modConnections[idx]
        wrapper?.disconnectModulation(conn.source, from: conn.destination)
        modConnections.remove(at: idx)
    }

    func removeModulation(source: String, destination: String) {
        wrapper?.disconnectModulation(source, from: destination)
        modConnections.removeAll { $0.source == source && $0.destination == destination }
    }

    func refreshModulationLists() {
        if let src = wrapper?.modulationSourceNames() as? [String], !src.isEmpty {
            modulationSources = src
        }
        if let dst = wrapper?.modulationDestinationNames() as? [String], !dst.isEmpty {
            modulationDestinations = dst
        }
    }

    func refreshModulations() {
        refreshModulationLists()
        guard let list = wrapper?.listModulations() else {
            modConnections = []
            return
        }
        modConnections = list.compactMap { anyDict -> ModConnection? in
            guard let dict = anyDict as? [String: Any],
                  let source = dict["source"] as? String,
                  let destination = dict["destination"] as? String else { return nil }
            let amount: Float
            if let f = dict["amount"] as? Float {
                amount = f
            } else if let d = dict["amount"] as? Double {
                amount = Float(d)
            } else if let n = dict["amount"] as? NSNumber {
                amount = n.floatValue
            } else {
                amount = 0
            }
            let bipolar = (dict["bipolar"] as? NSNumber)?.boolValue ?? false
            let stereo = (dict["stereo"] as? NSNumber)?.boolValue ?? false
            let bypass = (dict["bypass"] as? NSNumber)?.boolValue ?? false
            let power = (dict["power"] as? NSNumber)?.floatValue ?? 0
            let index = (dict["index"] as? NSNumber)?.intValue ?? 0
            return ModConnection(source: source, destination: destination, amount: amount,
                                 bipolar: bipolar, stereo: stereo, bypass: bypass,
                                 power: power, index: index)
        }
    }

    // MARK: - Sync all published → engine (used on start)

    private func syncAllPublishedToEngine() {
        setMasterVolume(masterVolume)

        setOsc1On(osc1On); setOsc1Level(osc1Level); setOsc1Pan(osc1Pan)
        setOsc1Transpose(osc1Transpose); setOsc1WaveFrame(osc1WaveFrame)
        setOsc1UnisonVoices(osc1UnisonVoices); setOsc1UnisonDetune(osc1UnisonDetune)
        setOsc1DetunePower(osc1DetunePower); setOsc1Phase(osc1Phase); setOsc1RandomPhase(osc1RandomPhase)
        setOsc1SpectralMorphType(osc1SpectralMorphType); setOsc1SpectralMorphAmount(osc1SpectralMorphAmount)
        setOsc1DistortionType(osc1DistortionType); setOsc1DistortionAmount(osc1DistortionAmount)
        setOsc1Destination(osc1Destination)

        setOsc2On(osc2On); setOsc2Level(osc2Level); setOsc2Pan(osc2Pan)
        setOsc2Transpose(osc2Transpose); setOsc2WaveFrame(osc2WaveFrame)
        setOsc2UnisonVoices(osc2UnisonVoices); setOsc2UnisonDetune(osc2UnisonDetune)
        setOsc2DetunePower(osc2DetunePower); setOsc2Phase(osc2Phase); setOsc2RandomPhase(osc2RandomPhase)
        setOsc2SpectralMorphType(osc2SpectralMorphType); setOsc2SpectralMorphAmount(osc2SpectralMorphAmount)
        setOsc2DistortionType(osc2DistortionType); setOsc2DistortionAmount(osc2DistortionAmount)
        setOsc2Destination(osc2Destination)

        setOsc3On(osc3On); setOsc3Level(osc3Level); setOsc3Pan(osc3Pan)
        setOsc3Transpose(osc3Transpose); setOsc3WaveFrame(osc3WaveFrame)
        setOsc3UnisonVoices(osc3UnisonVoices); setOsc3UnisonDetune(osc3UnisonDetune)
        setOsc3DetunePower(osc3DetunePower); setOsc3Phase(osc3Phase); setOsc3RandomPhase(osc3RandomPhase)
        setOsc3SpectralMorphType(osc3SpectralMorphType); setOsc3SpectralMorphAmount(osc3SpectralMorphAmount)
        setOsc3DistortionType(osc3DistortionType); setOsc3DistortionAmount(osc3DistortionAmount)
        setOsc3Destination(osc3Destination)

        setSampleOn(sampleOn); setSampleLevel(sampleLevel); setSamplePan(samplePan)
        setSampleTranspose(sampleTranspose); setSampleLoop(sampleLoop)
        setSampleBounce(sampleBounce); setSampleKeytrack(sampleKeytrack)

        setFilter1On(filter1On); setFilterCutoff(filterCutoff); setFilterResonance(filterResonance)
        setFilterDrive(filterDrive); setFilterModel(filterModel)
        setFilter1Blend(filter1Blend); setFilter1Style(filter1Style)

        setFilter2On(filter2On); setFilter2Cutoff(filter2Cutoff); setFilter2Resonance(filter2Resonance)
        setFilter2Drive(filter2Drive); setFilter2Model(filter2Model)
        setFilter2Blend(filter2Blend); setFilter2Style(filter2Style)

        setEnv1Attack(env1Attack); setEnv1Hold(env1Hold); setEnv1Decay(env1Decay)
        setEnv1Sustain(env1Sustain); setEnv1Release(env1Release)
        setEnv2Attack(env2Attack); setEnv2Hold(env2Hold); setEnv2Decay(env2Decay)
        setEnv2Sustain(env2Sustain); setEnv2Release(env2Release)
        setEnv3Attack(env3Attack); setEnv3Hold(env3Hold); setEnv3Decay(env3Decay)
        setEnv3Sustain(env3Sustain); setEnv3Release(env3Release)
        setEnv4Attack(env4Attack); setEnv4Hold(env4Hold); setEnv4Decay(env4Decay)
        setEnv4Sustain(env4Sustain); setEnv4Release(env4Release)
        setEnv5Attack(env5Attack); setEnv5Hold(env5Hold); setEnv5Decay(env5Decay)
        setEnv5Sustain(env5Sustain); setEnv5Release(env5Release)
        setEnv6Attack(env6Attack); setEnv6Hold(env6Hold); setEnv6Decay(env6Decay)
        setEnv6Sustain(env6Sustain); setEnv6Release(env6Release)

        for i in 0..<8 {
            setLfoRate(i, lfoRates[i])
            setLfoPhase(i, lfoPhases[i])
            setLfoSync(i, lfoSyncs[i])
        }
        // Keep LFO 1 mirrors in sync
        lfo1Rate = lfoRates[0]
        lfo1Amount = lfoAmounts[0]
        lfo1Target = lfoTargets[0]

        for i in 0..<4 {
            setRandomStyle(i, randomStyle[i])
            setRandomRate(i, randomRate[i])
            setMacro(i, macro[i])
        }

        setChorusOn(chorusOn); setChorusMix(chorusMix)
        setChorusFeedback(chorusFeedback); setChorusModDepth(chorusModDepth); setChorusFrequency(chorusFrequency)
        setCompressorOn(compressorOn); setCompressorMix(compressorMix)
        setCompressorAttack(compressorAttack); setCompressorRelease(compressorRelease)
        setDelayOn(delayOn); setDelayMix(delayMix)
        setDelayFeedback(delayFeedback); setDelayFrequency(delayFrequency)
        setDistortionOn(distortionOn); setDistortionMix(distortionMix)
        setDistortionDrive(distortionDrive); setDistortionType(distortionType)
        setEqualizerOn(equalizerOn)
        setEqualizerLowGain(equalizerLowGain); setEqualizerMidGain(equalizerMidGain); setEqualizerHighGain(equalizerHighGain)
        setFilterFxOn(filterFxOn); setFilterFxCutoff(filterFxCutoff); setFilterFxResonance(filterFxResonance)
        setFlangerOn(flangerOn); setFlangerDryWet(flangerDryWet)
        setFlangerFeedback(flangerFeedback); setFlangerCenter(flangerCenter); setFlangerModDepth(flangerModDepth)
        setPhaserOn(phaserOn); setPhaserDryWet(phaserDryWet)
        setPhaserFeedback(phaserFeedback); setPhaserCenter(phaserCenter); setPhaserModDepth(phaserModDepth)
        setReverbOn(reverbOn); setReverbMix(reverbMix)
        setReverbSize(reverbSize); setReverbDecay(reverbDecay); setReverbChorusAmount(reverbChorusAmount)

        setPolyphony(polyphony)
        setLegato(legato)
        setGlide(glide)
        setPitchBendRange(pitchBendRange)
    }

    // MARK: - Preset capture / apply

    func capturePreset(name: String) -> VitalPreset {
        VitalPreset(
            name: name, category: "Custom",
            osc1On: osc1On,       osc1Level: osc1Level,    osc1Pan: osc1Pan,
            osc1Transpose: osc1Transpose, osc1WaveForm: osc1WaveForm,
            osc2On: osc2On,       osc2Level: osc2Level,    osc2Pan: osc2Pan,
            osc2Transpose: osc2Transpose, osc2WaveForm: osc2WaveForm,
            osc3On: osc3On,       osc3Level: osc3Level,    osc3Pan: osc3Pan,
            osc3Transpose: osc3Transpose, osc3WaveForm: osc3WaveForm,
            filterCutoff: filterCutoff,   filterResonance: filterResonance,
            filterDrive: filterDrive,     filterModel: filterModel,
            filter2On: filter2On,
            filter2Cutoff: filter2Cutoff, filter2Resonance: filter2Resonance,
            filter2Drive: filter2Drive,   filter2Model: filter2Model,
            osc1FilterRoute: osc1FilterRoute,
            osc2FilterRoute: osc2FilterRoute,
            osc3FilterRoute: osc3FilterRoute,
            env1Attack: env1Attack,  env1Decay: env1Decay,
            env1Sustain: env1Sustain, env1Release: env1Release,
            env2Attack: env2Attack,  env2Decay: env2Decay,
            env2Sustain: env2Sustain, env2Release: env2Release,
            lfo1Rate: lfo1Rate, lfo1Amount: lfo1Amount, lfo1Target: lfo1Target,
            reverbMix: reverbMix, delayMix: delayMix,
            chorusMix: chorusMix, distortionMix: distortionMix,
            legato: legato,
            glide: glide,
            masterVolume: masterVolume
        )
    }

    func resetToInit() {
        allNotesOff()
        wrapper?.loadDefaultWavetables()
        osc1DisplayFrames = []; osc2DisplayFrames = []; osc3DisplayFrames = []
        osc1WavetableName = "Init"; osc2WavetableName = "Init"; osc3WavetableName = "Init"
        applyPreset(VitalPreset(
            name: "Init",
            osc1On: true,  osc1Level: 1.0, osc1Pan: 0.5, osc1Transpose: 0.0,  osc1WaveForm: 0,
            osc2On: false, osc2Level: 0.0, osc2Pan: 0.5, osc2Transpose: 0.0,  osc2WaveForm: 0,
            osc3On: false, osc3Level: 0.0, osc3Pan: 0.5, osc3Transpose: 0.0,  osc3WaveForm: 0,
            filterCutoff: 100.0, filterResonance: 0.5, filterDrive: 0.0, filterModel: 0,
            env1Attack: 0.003, env1Decay: 0.25, env1Sustain: 0.70, env1Release: 0.40,
            env2Attack: 0.003, env2Decay: 0.40, env2Sustain: 0.0,  env2Release: 0.30,
            lfo1Rate: 0.25,
            reverbMix: 0.0, delayMix: 0.0, chorusMix: 0.0, distortionMix: 0.0,
            masterVolume: 0.8601
        ))
        // Extra engine params not represented on VitalPreset
        osc1WaveFrame = 0; osc2WaveFrame = 0; osc3WaveFrame = 0
        setOsc1UnisonVoices(1); setOsc1UnisonDetune(0.4472); setOsc1DetunePower(0.65)
        setOsc1Phase(0.5); setOsc1RandomPhase(1.0)
        setOsc1SpectralMorphType(0); setOsc1SpectralMorphAmount(0.5)
        setOsc1DistortionType(0); setOsc1DistortionAmount(0.5)
        setOsc2UnisonVoices(1); setOsc2UnisonDetune(0.4472); setOsc2DetunePower(0.65)
        setOsc2Phase(0.5); setOsc2RandomPhase(1.0)
        setOsc2SpectralMorphType(0); setOsc2SpectralMorphAmount(0.5)
        setOsc2DistortionType(0); setOsc2DistortionAmount(0.5)
        setOsc3UnisonVoices(1); setOsc3UnisonDetune(0.4472); setOsc3DetunePower(0.65)
        setOsc3Phase(0.5); setOsc3RandomPhase(1.0)
        setOsc3SpectralMorphType(0); setOsc3SpectralMorphAmount(0.5)
        setOsc3DistortionType(0); setOsc3DistortionAmount(0.5)

        setSampleOn(false); setSampleLevel(0.7071); setSamplePan(0.5)
        setSampleTranspose(0); setSampleLoop(true); setSampleBounce(false); setSampleKeytrack(false)

        setFilter1On(true); setFilter1Blend(0); setFilter1Style(0)
        setFilter2On(true); setFilter2Cutoff(100.0); setFilter2Resonance(0.5)
        setFilter2Drive(0.0); setFilter2Model(0); setFilter2Blend(0); setFilter2Style(0)
        setOsc1FilterRoute(0); setOsc2FilterRoute(0); setOsc3FilterRoute(0)

        setEnv1Hold(0); setEnv2Hold(0)
        setEnv3Attack(0); setEnv3Hold(0); setEnv3Decay(1); setEnv3Sustain(1); setEnv3Release(0.5476)
        setEnv4Attack(0); setEnv4Hold(0); setEnv4Decay(1); setEnv4Sustain(1); setEnv4Release(0.5476)
        setEnv5Attack(0); setEnv5Hold(0); setEnv5Decay(1); setEnv5Sustain(1); setEnv5Release(0.5476)
        setEnv6Attack(0); setEnv6Hold(0); setEnv6Decay(1); setEnv6Sustain(1); setEnv6Release(0.5476)

        for i in 0..<8 {
            setLfoRate(i, i == 0 ? 0.25 : 0.25)
            setLfoPhase(i, 0)
            setLfoSync(i, 1)
            setLfoTarget(i, 0)
            setLfoAmount(i, i == 0 ? 0.3 : 0)
        }
        for i in 0..<4 {
            setRandomStyle(i, 0)
            setRandomRate(i, 0.5)
            setMacro(i, 0)
        }

        setChorusOn(false); setChorusMix(0); setChorusFeedback(0.5); setChorusModDepth(0.5); setChorusFrequency(0.333)
        setCompressorOn(false); setCompressorMix(1); setCompressorAttack(0.5); setCompressorRelease(0.5)
        setDelayOn(false); setDelayMix(0); setDelayFeedback(0.5); setDelayFrequency(0.3636)
        setDistortionOn(false); setDistortionMix(0); setDistortionDrive(0.5); setDistortionType(0)
        setEqualizerOn(false); setEqualizerLowGain(0); setEqualizerMidGain(0); setEqualizerHighGain(0)
        setFilterFxOn(false); setFilterFxCutoff(60); setFilterFxResonance(0.5)
        setFlangerOn(false); setFlangerDryWet(0); setFlangerFeedback(0.5); setFlangerCenter(64); setFlangerModDepth(0.5)
        setPhaserOn(false); setPhaserDryWet(0); setPhaserFeedback(0.5); setPhaserCenter(80); setPhaserModDepth(0.5)
        setReverbOn(false); setReverbMix(0); setReverbSize(0.5); setReverbDecay(0.5); setReverbChorusAmount(0.2236)

        setPolyphony(16)
        setLegato(false)
        setGlide(0.0)
        setPitchBendRange(2.0)
    }

    func applyPreset(_ p: VitalPreset) {
        currentPatch = p.name
        setOsc1On(p.osc1On);    setOsc1Level(p.osc1Level); setOsc1Pan(p.osc1Pan)
        setOsc1Transpose(p.osc1Transpose); setOsc1Waveform(p.osc1WaveForm)
        setOsc2On(p.osc2On);    setOsc2Level(p.osc2Level); setOsc2Pan(p.osc2Pan)
        setOsc2Transpose(p.osc2Transpose); setOsc2Waveform(p.osc2WaveForm)
        setOsc3On(p.osc3On);    setOsc3Level(p.osc3Level); setOsc3Pan(p.osc3Pan)
        setOsc3Transpose(p.osc3Transpose); setOsc3Waveform(p.osc3WaveForm)
        setFilterCutoff(p.filterCutoff); setFilterResonance(p.filterResonance)
        setFilterDrive(p.filterDrive);   setFilterModel(p.filterModel)
        setFilter2On(p.filter2On)
        setFilter2Cutoff(p.filter2Cutoff); setFilter2Resonance(p.filter2Resonance)
        setFilter2Drive(p.filter2Drive);   setFilter2Model(p.filter2Model)
        setOsc1FilterRoute(p.osc1FilterRoute)
        setOsc2FilterRoute(p.osc2FilterRoute)
        setOsc3FilterRoute(p.osc3FilterRoute)
        setEnv1Attack(p.env1Attack); setEnv1Decay(p.env1Decay)
        setEnv1Sustain(p.env1Sustain); setEnv1Release(p.env1Release)
        setEnv2Attack(p.env2Attack); setEnv2Decay(p.env2Decay)
        setEnv2Sustain(p.env2Sustain); setEnv2Release(p.env2Release)
        setLfo1Rate(p.lfo1Rate)
        setLfo1Target(p.lfo1Target)
        setLfo1Amount(p.lfo1Amount)
        setReverbMix(p.reverbMix); setDelayMix(p.delayMix)
        setChorusMix(p.chorusMix); setDistortionMix(p.distortionMix)
        setLegato(p.legato)
        setGlide(p.glide)
        setMasterVolume(p.masterVolume)
    }

    // MARK: - Vital Preset Loading

    /// Loads a full .vital preset file: applies all synth parameters and wavetables.
    /// Call this while the security-scoped resource for the URL is still open.
    func loadVitalPreset(from url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let settings = json["settings"] as? [String: Any] else { return }

        let name = (json["name"] as? String) ?? url.deletingPathExtension().lastPathComponent

        allNotesOff()

        // 1. Apply every numeric parameter directly to the engine.
        //    Vital's parameter names match our engine's names exactly.
        for (key, value) in settings {
            guard key != "wavetables" else { continue }
            if let d = value as? Double {
                wrapper?.setParameter(key, value: Float(d))
            }
        }

        // 2. Sync all @Published UI vars so controls reflect the loaded preset.
        syncPublishedFromVitalSettings(settings)
        loadEffectChainOrder()
        currentPatch = name

        // 3. Load wavetables asynchronously (FFT work, must not block main thread).
        osc1DisplayFrames = []; osc2DisplayFrames = []; osc3DisplayFrames = []
        if let wavetables = settings["wavetables"] as? [[String: Any]], let w = wrapper {
            for (idx, wtDict) in wavetables.prefix(3).enumerated() {
                guard let wtData = try? JSONSerialization.data(withJSONObject: wtDict) else { continue }
                let oscIdx = idx
                loadQueue.async { [weak self] in
                    let ok = Self.processJSON(data: wtData, wrapper: w, oscillatorIndex: oscIdx)
                    if ok { DispatchQueue.main.async { self?.refreshDisplayFrames(oscillatorIndex: oscIdx) } }
                }
            }
        }

        refreshSampleDisplay()
        refreshModulations()
    }

    /// Maps Vital preset `settings` values back to @Published vars so the UI updates.
    private func syncPublishedFromVitalSettings(_ s: [String: Any]) {
        func f(_ key: String, _ def: Float = 0) -> Float { Float((s[key] as? Double) ?? Double(def)) }
        func b(_ key: String) -> Bool { f(key) >= 0.5 }

        // Oscillators
        osc1On = b("osc_1_on"); osc1Level = f("osc_1_level", 1)
        osc1Pan = (f("osc_1_pan") + 1) / 2
        osc1Transpose = f("osc_1_transpose")
        osc1WaveFrame = f("osc_1_wave_frame") / 255.0
        osc1UnisonVoices = Int(f("osc_1_unison_voices", 1).rounded())
        osc1UnisonDetune = f("osc_1_unison_detune", 4.472) / 10.0
        osc1DetunePower = (f("osc_1_detune_power", 1.5) + 5) / 10.0
        osc1Phase = f("osc_1_phase", 0.5)
        osc1RandomPhase = f("osc_1_random_phase", 1)
        osc1SpectralMorphType = Int(f("osc_1_spectral_morph_type").rounded())
        osc1SpectralMorphAmount = f("osc_1_spectral_morph_amount", 0.5)
        osc1DistortionType = Int(f("osc_1_distortion_type").rounded())
        osc1DistortionAmount = f("osc_1_distortion_amount", 0.5)
        osc1Destination = Int(f("osc_1_destination").rounded())

        osc2On = b("osc_2_on"); osc2Level = f("osc_2_level")
        osc2Pan = (f("osc_2_pan") + 1) / 2
        osc2Transpose = f("osc_2_transpose")
        osc2WaveFrame = f("osc_2_wave_frame") / 255.0
        osc2UnisonVoices = Int(f("osc_2_unison_voices", 1).rounded())
        osc2UnisonDetune = f("osc_2_unison_detune", 4.472) / 10.0
        osc2DetunePower = (f("osc_2_detune_power", 1.5) + 5) / 10.0
        osc2Phase = f("osc_2_phase", 0.5)
        osc2RandomPhase = f("osc_2_random_phase", 1)
        osc2SpectralMorphType = Int(f("osc_2_spectral_morph_type").rounded())
        osc2SpectralMorphAmount = f("osc_2_spectral_morph_amount", 0.5)
        osc2DistortionType = Int(f("osc_2_distortion_type").rounded())
        osc2DistortionAmount = f("osc_2_distortion_amount", 0.5)
        osc2Destination = Int(f("osc_2_destination").rounded())

        osc3On = b("osc_3_on"); osc3Level = f("osc_3_level")
        osc3Pan = (f("osc_3_pan") + 1) / 2
        osc3Transpose = f("osc_3_transpose")
        osc3WaveFrame = f("osc_3_wave_frame") / 255.0
        osc3UnisonVoices = Int(f("osc_3_unison_voices", 1).rounded())
        osc3UnisonDetune = f("osc_3_unison_detune", 4.472) / 10.0
        osc3DetunePower = (f("osc_3_detune_power", 1.5) + 5) / 10.0
        osc3Phase = f("osc_3_phase", 0.5)
        osc3RandomPhase = f("osc_3_random_phase", 1)
        osc3SpectralMorphType = Int(f("osc_3_spectral_morph_type").rounded())
        osc3SpectralMorphAmount = f("osc_3_spectral_morph_amount", 0.5)
        osc3DistortionType = Int(f("osc_3_distortion_type").rounded())
        osc3DistortionAmount = f("osc_3_distortion_amount", 0.5)
        osc3Destination = Int(f("osc_3_destination").rounded())

        // Sample
        sampleOn = b("sample_on")
        sampleLevel = f("sample_level", 0.7071)
        samplePan = (f("sample_pan") + 1) / 2
        sampleTranspose = f("sample_transpose")
        sampleLoop = f("sample_loop", 1) >= 0.5
        sampleBounce = b("sample_bounce")
        sampleKeytrack = b("sample_keytrack")

        // Filters
        filter1On = b("filter_1_on")
        filterCutoff = f("filter_1_cutoff", 100); filterResonance = f("filter_1_resonance", 0.5)
        filterDrive = f("filter_1_drive") / 20.0
        filterModel = Int(f("filter_1_model").rounded())
        filter1Blend = f("filter_1_blend") / 2.0
        filter1Style = Int(f("filter_1_style").rounded())

        filter2On = b("filter_2_on")
        filter2Cutoff = f("filter_2_cutoff", 100); filter2Resonance = f("filter_2_resonance", 0.5)
        filter2Drive = f("filter_2_drive") / 20.0
        filter2Model = Int(f("filter_2_model").rounded())
        filter2Blend = f("filter_2_blend") / 2.0
        filter2Style = Int(f("filter_2_style").rounded())

        // OSC → filter routing: filter_N_oscM_input (no underscore before osc index)
        func route(osc: Int) -> Int {
            let toF1 = f("filter_1_osc\(osc)_input") >= 0.5
            let toF2 = f("filter_2_osc\(osc)_input") >= 0.5
            if toF1 && toF2 { return 2 }
            return toF2 ? 1 : 0
        }
        osc1FilterRoute = route(osc: 1)
        osc2FilterRoute = route(osc: 2)
        osc3FilterRoute = route(osc: 3)

        // Envelopes 1-6
        env1Attack = f("env_1_attack", 0.003); env1Hold = f("env_1_hold")
        env1Decay = f("env_1_decay", 0.25); env1Sustain = f("env_1_sustain", 0.7)
        env1Release = f("env_1_release", 0.4)
        env2Attack = f("env_2_attack", 0.003); env2Hold = f("env_2_hold")
        env2Decay = f("env_2_decay", 0.4); env2Sustain = f("env_2_sustain")
        env2Release = f("env_2_release", 0.3)
        env3Attack = f("env_3_attack"); env3Hold = f("env_3_hold")
        env3Decay = f("env_3_decay", 1); env3Sustain = f("env_3_sustain", 1)
        env3Release = f("env_3_release", 0.5476)
        env4Attack = f("env_4_attack"); env4Hold = f("env_4_hold")
        env4Decay = f("env_4_decay", 1); env4Sustain = f("env_4_sustain", 1)
        env4Release = f("env_4_release", 0.5476)
        env5Attack = f("env_5_attack"); env5Hold = f("env_5_hold")
        env5Decay = f("env_5_decay", 1); env5Sustain = f("env_5_sustain", 1)
        env5Release = f("env_5_release", 0.5476)
        env6Attack = f("env_6_attack"); env6Hold = f("env_6_hold")
        env6Decay = f("env_6_decay", 1); env6Sustain = f("env_6_sustain", 1)
        env6Release = f("env_6_release", 0.5476)

        // LFOs
        for i in 0..<8 {
            let n = i + 1
            lfoRates[i] = Self.normalizedLfoRate(fromFrequency: f("lfo_\(n)_frequency", 1))
            lfoPhases[i] = f("lfo_\(n)_phase")
            lfoSyncs[i] = Int(f("lfo_\(n)_sync", 1).rounded())
        }
        lfo1Rate = lfoRates[0]

        // Random LFOs
        for i in 0..<4 {
            let n = i + 1
            randomStyle[i] = Int(f("random_\(n)_style").rounded())
            randomRate[i] = Self.normalizedLfoRate(fromFrequency: f("random_\(n)_frequency", 1))
        }

        // Macros
        for i in 0..<4 {
            macro[i] = f("macro_control_\(i + 1)")
        }

        // FX
        chorusOn = b("chorus_on"); chorusMix = f("chorus_dry_wet")
        chorusFeedback = (f("chorus_feedback", 0.4) + 0.95) / 1.9
        chorusModDepth = f("chorus_mod_depth", 0.5)
        chorusFrequency = (f("chorus_frequency", -3) + 6) / 9

        compressorOn = b("compressor_on"); compressorMix = f("compressor_mix", 1)
        compressorAttack = f("compressor_attack", 0.5)
        compressorRelease = f("compressor_release", 0.5)

        delayOn = b("delay_on"); delayMix = f("delay_dry_wet")
        delayFeedback = (f("delay_feedback", 0.5) + 1) / 2
        delayFrequency = (f("delay_frequency", 2) + 2) / 11

        distortionOn = b("distortion_on"); distortionMix = f("distortion_mix")
        distortionDrive = (f("distortion_drive") + 30) / 60
        distortionType = Int(f("distortion_type").rounded())

        equalizerOn = b("eq_on") || b("equalizer_on")
        equalizerLowGain = f("eq_low_gain")
        equalizerMidGain = f("eq_band_gain")
        equalizerHighGain = f("eq_high_gain")

        filterFxOn = b("filter_fx_on")
        filterFxCutoff = f("filter_fx_cutoff", 60)
        filterFxResonance = f("filter_fx_resonance", 0.5)

        flangerOn = b("flanger_on"); flangerDryWet = f("flanger_dry_wet")
        flangerFeedback = (f("flanger_feedback", 0.5) + 1) / 2
        flangerCenter = f("flanger_center", 64)
        flangerModDepth = f("flanger_mod_depth", 0.5)

        phaserOn = b("phaser_on"); phaserDryWet = f("phaser_dry_wet")
        phaserFeedback = f("phaser_feedback", 0.5)
        phaserCenter = f("phaser_center", 80)
        phaserModDepth = f("phaser_mod_depth", 24) / 48.0

        reverbOn = b("reverb_on"); reverbMix = f("reverb_dry_wet")
        reverbSize = f("reverb_size", 0.5)
        reverbDecay = (f("reverb_decay_time") + 6) / 12
        reverbChorusAmount = f("reverb_chorus_amount", 0.2236)

        // Voice
        polyphony = Int(f("polyphony", 16).rounded())
        legato = b("legato")
        let pt = f("portamento_time", -10)
        glide = min(1, max(0, (pt + 10) / 14))
        pitchBendRange = f("pitch_bend_range", 2)

        // Volume
        let rawVol = f("volume", Float(0.8601 * 0.8601 * 7399.44))
        masterVolume = min(1, max(0, sqrt(rawVol / 7399.44)))
    }

    // MARK: - Wavetable loading

    /// Load a wavetable from a file URL into the given oscillator (0=OSC1, 1=OSC2, 2=OSC3).
    /// Accepts: .wav/.aif/.aiff (audio), .vitaltable/.json (wavetable JSON), or .vital (full preset).
    /// File I/O happens on the CALLING thread (main) while the security-scoped
    /// resource is still open; only the Vital DSP (FFT) work runs in background.
    func loadWavetable(from url: URL, oscillatorIndex: Int) {
        guard let w = wrapper else { return }
        let idx = oscillatorIndex
        let ext = url.pathExtension.lowercased()
        let fileName = url.deletingPathExtension().lastPathComponent

        switch ext {
        case "wav", "aif", "aiff", "flac", "caf", "mp3", "m4a":
            guard let audioFile = try? AVAudioFile(forReading: url) else { return }
            let sr = audioFile.fileFormat.sampleRate
            let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: sr, channels: 1, interleaved: false)!
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard frameCount > 0,
                  let buf = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: frameCount),
                  (try? audioFile.read(into: buf)) != nil,
                  let ptr = buf.floatChannelData else { return }
            let samples = [Float](UnsafeBufferPointer(start: ptr[0], count: Int(buf.frameLength)))
            let sampleRate = Int32(sr)
            loadQueue.async { [weak self] in
                let ok = samples.withUnsafeBufferPointer {
                    w.loadWavetable(fromSamples: $0.baseAddress!,
                                    sampleCount: Int32(samples.count),
                                    sampleRate: sampleRate,
                                    oscillatorIndex: Int32(idx))
                }
                if ok {
                    w.setWavetableName(fileName, oscillatorIndex: Int32(idx))
                    DispatchQueue.main.async { self?.refreshDisplayFrames(oscillatorIndex: idx) }
                }
            }

        default:
            // JSON / .vitaltable / .vital — read on main thread while scope is open
            guard let data = try? Data(contentsOf: url) else { return }
            loadQueue.async { [weak self] in
                let ok = Self.processJSON(data: data, wrapper: w, oscillatorIndex: idx)
                if ok {
                    // Prefer JSON "name"; fall back to filename if engine still has a placeholder.
                    let engineName = w.wavetableName(forOscillator: Int32(idx)) ?? ""
                    if engineName.isEmpty || engineName == "Wavetable" {
                        w.setWavetableName(fileName, oscillatorIndex: Int32(idx))
                    }
                    DispatchQueue.main.async { self?.refreshDisplayFrames(oscillatorIndex: idx) }
                }
            }
        }
    }

    /// Extracts and loads a wavetable from JSON data.
    /// Handles three formats:
    ///   • Full .vital preset  — { "settings": { "wavetables": [...] } }
    ///   • Wavetable preset    — { "wavetables": [...] }
    ///   • Single wavetable    — { "groups": [...] }
    static func processJSON(data: Data, wrapper: VitalEngineWrapper, oscillatorIndex: Int) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }

        // Full .vital preset: dig into settings.wavetables
        if let settings = json["settings"] as? [String: Any],
           let wavetables = settings["wavetables"] as? [[String: Any]], !wavetables.isEmpty {
            let idx = min(oscillatorIndex, wavetables.count - 1)
            guard let wtData = try? JSONSerialization.data(withJSONObject: wavetables[idx]) else { return false }
            return wrapper.loadWavetable(fromJSON: wtData, oscillatorIndex: Int32(oscillatorIndex))
        }

        // Wavetable-only JSON with top-level wavetables array
        if let wavetables = json["wavetables"] as? [[String: Any]], !wavetables.isEmpty {
            let idx = min(oscillatorIndex, wavetables.count - 1)
            guard let wtData = try? JSONSerialization.data(withJSONObject: wavetables[idx]) else { return false }
            return wrapper.loadWavetable(fromJSON: wtData, oscillatorIndex: Int32(oscillatorIndex))
        }

        // Single wavetable JSON with top-level groups
        if json["groups"] != nil {
            return wrapper.loadWavetable(fromJSON: data, oscillatorIndex: Int32(oscillatorIndex))
        }

        return false
    }

    // MARK: - Private helpers

    private func refreshDisplayFrames(oscillatorIndex: Int) {
        let rawFrames = wrapper?.getDisplayFrames(Int32(oscillatorIndex)) ?? []
        let frames: [[Float]] = rawFrames.map { data in
            data.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self))
            }
        }
        let name = wrapper?.wavetableName(forOscillator: Int32(oscillatorIndex)) ?? ""
        let displayName = name.isEmpty ? "Init" : name
        switch oscillatorIndex {
        case 0:
            osc1DisplayFrames = frames
            osc1WavetableName = displayName
        case 1:
            osc2DisplayFrames = frames
            osc2WavetableName = displayName
        case 2:
            osc3DisplayFrames = frames
            osc3WavetableName = displayName
        default: break
        }
    }

    func refreshSampleDisplay() {
        guard let data = wrapper?.getSampleDisplayBuffer() else {
            sampleDisplayFrames = []
            return
        }
        sampleDisplayFrames = data.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self))
        }
    }

    // MARK: - Wavetable editing

    func wavetableFrameCount(oscillatorIndex: Int) -> Int {
        Int(wrapper?.numFrames(forOscillator: Int32(oscillatorIndex)) ?? 1)
    }

    func waveFramePosition(oscillatorIndex: Int) -> Float {
        let raw = wrapper?.getParameter("osc_\(oscillatorIndex + 1)_wave_frame") ?? 0
        return max(0, min(1, raw / 255.0))
    }

    func setWaveFramePosition(oscillatorIndex: Int, normalized: Float) {
        let v = max(0, min(1, normalized))
        switch oscillatorIndex {
        case 0: setOsc1WaveFrame(v)
        case 1: setOsc2WaveFrame(v)
        case 2: setOsc3WaveFrame(v)
        default: break
        }
    }

    func getWavetableFrame(oscillatorIndex: Int, frame: Int) -> [Float] {
        guard let data = wrapper?.getFrameSamples(Int32(oscillatorIndex), frame: Int32(frame)) else {
            return []
        }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    @discardableResult
    func setWavetableFrame(_ samples: [Float], oscillatorIndex: Int, frame: Int) -> Bool {
        let data = samples.withUnsafeBufferPointer { Data(buffer: $0) }
        return wrapper?.setFrameSamples(data, oscillator: Int32(oscillatorIndex), frame: Int32(frame)) ?? false
    }

    @discardableResult
    func fillWavetableFrame(shape: Int, oscillatorIndex: Int, frame: Int) -> Bool {
        wrapper?.fillFrame(withShape: Int32(shape),
                           oscillator: Int32(oscillatorIndex),
                           frame: Int32(frame)) ?? false
    }

    @discardableResult
    func commitWavetable(oscillatorIndex: Int) -> Bool {
        let ok = wrapper?.commitWavetable(Int32(oscillatorIndex)) ?? false
        if ok { refreshDisplayFrames(oscillatorIndex: oscillatorIndex) }
        return ok
    }

    @discardableResult
    func expandWavetable(toFrames count: Int, oscillatorIndex: Int, interpolate: Bool = true) -> Bool {
        let ok = wrapper?.expandWavetable(toFrames: Int32(count),
                                          oscillator: Int32(oscillatorIndex),
                                          interpolate: interpolate) ?? false
        if ok { refreshDisplayFrames(oscillatorIndex: oscillatorIndex) }
        return ok
    }

    func getWavetableAmplitudes(oscillatorIndex: Int, frame: Int, harmonicCount: Int = 64) -> [Float] {
        guard let data = wrapper?.getFrameAmplitudes(Int32(oscillatorIndex),
                                                     frame: Int32(frame),
                                                     harmonicCount: Int32(harmonicCount)) else {
            return Array(repeating: 0, count: harmonicCount)
        }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    func getWavetablePhases(oscillatorIndex: Int, frame: Int, harmonicCount: Int = 64) -> [Float] {
        guard let data = wrapper?.getFramePhases(Int32(oscillatorIndex),
                                                 frame: Int32(frame),
                                                 harmonicCount: Int32(harmonicCount)) else {
            return Array(repeating: 0, count: harmonicCount)
        }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    @discardableResult
    func setWavetableSpectrum(amplitudes: [Float],
                              phases: [Float]?,
                              oscillatorIndex: Int,
                              frame: Int) -> Bool {
        let ampData = amplitudes.withUnsafeBufferPointer { Data(buffer: $0) }
        let phaseData = phases.map { $0.withUnsafeBufferPointer { Data(buffer: $0) } }
        return wrapper?.setFrameSpectrumAmplitudes(ampData,
                                                   phases: phaseData,
                                                   oscillator: Int32(oscillatorIndex),
                                                   frame: Int32(frame)) ?? false
    }

    // MARK: - LFO shape editing

    struct LfoPoint: Equatable {
        var x: Float
        var y: Float
    }

    func lfoPoints(index: Int) -> [LfoPoint] {
        guard let data = wrapper?.getLfoPoints(Int32(index)) else { return [] }
        let vals = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        var pts: [LfoPoint] = []
        pts.reserveCapacity(vals.count / 2)
        var i = 0
        while i + 1 < vals.count {
            pts.append(LfoPoint(x: vals[i], y: vals[i + 1]))
            i += 2
        }
        return pts
    }

    func lfoDisplayBuffer(index: Int) -> [Float] {
        guard let data = wrapper?.getLfoDisplayBuffer(Int32(index)) else {
            return Array(repeating: 0.5, count: 256)
        }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    @discardableResult
    func setLfoPoint(index: Int, pointIndex: Int, x: Float, y: Float) -> Bool {
        wrapper?.setLfoPoint(Int32(index), index: Int32(pointIndex), x: x, y: y) ?? false
    }

    @discardableResult
    func setLfoPoints(index: Int, points: [LfoPoint]) -> Bool {
        var xy = [Float]()
        xy.reserveCapacity(points.count * 2)
        for p in points {
            xy.append(p.x)
            xy.append(p.y)
        }
        let data = xy.withUnsafeBufferPointer { Data(buffer: $0) }
        return wrapper?.setLfoPoints(Int32(index), interleavedXY: data) ?? false
    }

    @discardableResult
    func addLfoPoint(index: Int, after: Int, x: Float, y: Float) -> Bool {
        wrapper?.addLfoPoint(Int32(index), after: Int32(after), x: x, y: y) ?? false
    }

    @discardableResult
    func removeLfoPoint(index: Int, pointIndex: Int) -> Bool {
        wrapper?.removeLfoPoint(Int32(index), index: Int32(pointIndex)) ?? false
    }

    @discardableResult
    func initLfoShape(index: Int, shape: Int) -> Bool {
        wrapper?.initLfoShape(Int32(index), shape: Int32(shape)) ?? false
    }

    func lfoPowers(index: Int) -> [Float] {
        guard let data = wrapper?.getLfoPowers(Int32(index)) else { return [] }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    @discardableResult
    func setLfoPower(index: Int, pointIndex: Int, value: Float) -> Bool {
        wrapper?.setLfoPower(Int32(index), index: Int32(pointIndex), value: value) ?? false
    }

    func lfoSmooth(index: Int) -> Bool {
        wrapper?.lfoSmooth(Int32(index)) ?? false
    }

    @discardableResult
    func setLfoSmooth(index: Int, enabled: Bool) -> Bool {
        wrapper?.setLfoSmooth(Int32(index), enabled: enabled) ?? false
    }

    @discardableResult
    func flipLfoHorizontal(index: Int) -> Bool {
        wrapper?.flipLfoHorizontal(Int32(index)) ?? false
    }

    @discardableResult
    func flipLfoVertical(index: Int) -> Bool {
        wrapper?.flipLfoVertical(Int32(index)) ?? false
    }

    @discardableResult
    func normalizeWavetableFrame(oscillatorIndex: Int, frame: Int, removeDC: Bool = true) -> Bool {
        let ok = wrapper?.normalizeFrame(Int32(frame),
                                         oscillator: Int32(oscillatorIndex),
                                         removeDC: removeDC) ?? false
        return ok
    }

    func lfoStateJSON(index: Int) -> Data? {
        wrapper?.getLfoStateJSON(Int32(index)) as Data?
    }

    @discardableResult
    func setLfoStateJSON(index: Int, data: Data) -> Bool {
        wrapper?.setLfoStateJSON(Int32(index), data: data) ?? false
    }

    @discardableResult
    func interpolateWavetableFrames(from: Int, to: Int, spectral: Bool, oscillatorIndex: Int) -> Bool {
        wrapper?.interpolateFrames(from: Int32(from),
                                   to: Int32(to),
                                   mode: spectral ? 1 : 0,
                                   oscillator: Int32(oscillatorIndex)) ?? false
    }

    @discardableResult
    func copyWavetableFrame(from: Int, to: Int, oscillatorIndex: Int) -> Bool {
        wrapper?.copyFrame(Int32(from), toFrame: Int32(to), oscillator: Int32(oscillatorIndex)) ?? false
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(44100)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("VitalAudioEngine: Audio session config failed: \(error)")
        }
    }
}
