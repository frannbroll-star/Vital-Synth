//
//  VitalAUView.swift
//  VitalAU
//
//  ViewModel and SwiftUI editor view for the Vital AUv3 extension.
//  Mirrors standalone ContentView: VOICE | EFFECTS | MATRIX | ADVANCED.
//

import SwiftUI
import AudioToolbox

// MARK: - ViewModel

@MainActor
final class VitalAUViewModel: ObservableObject {
    private let au: VitalAUAudioUnit

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
    static let filterModelNames = ["Analog", "Dirty", "Ladder", "Digital", "Diode", "Formant", "Comb", "Phaser"]

    // MARK: Oscillators
    @Published var osc1On = true
    @Published var osc1Level: Float = 1.0
    @Published var osc1Pan: Float = 0.5
    @Published var osc1Transpose: Float = 0
    @Published var osc1WaveForm = 0
    @Published var osc1WaveFrame: Float = 0
    @Published var osc1UnisonVoices = 1
    @Published var osc1UnisonDetune: Float = 0.4472
    @Published var osc1DetunePower: Float = 0.65
    @Published var osc1Phase: Float = 0.5
    @Published var osc1RandomPhase: Float = 1.0
    @Published var osc1SpectralMorphType = 0
    @Published var osc1SpectralMorphAmount: Float = 0.5
    @Published var osc1DistortionType = 0
    @Published var osc1DistortionAmount: Float = 0.5
    @Published var osc1Destination = 0
    @Published var osc1FilterRoute = 0
    @Published var osc1DisplayFrames: [[Float]] = []
    @Published var osc1WavetableName = "Init"

    @Published var osc2On = false
    @Published var osc2Level: Float = 0
    @Published var osc2Pan: Float = 0.5
    @Published var osc2Transpose: Float = 0
    @Published var osc2WaveForm = 0
    @Published var osc2WaveFrame: Float = 0
    @Published var osc2UnisonVoices = 1
    @Published var osc2UnisonDetune: Float = 0.4472
    @Published var osc2DetunePower: Float = 0.65
    @Published var osc2Phase: Float = 0.5
    @Published var osc2RandomPhase: Float = 1.0
    @Published var osc2SpectralMorphType = 0
    @Published var osc2SpectralMorphAmount: Float = 0.5
    @Published var osc2DistortionType = 0
    @Published var osc2DistortionAmount: Float = 0.5
    @Published var osc2Destination = 0
    @Published var osc2FilterRoute = 0
    @Published var osc2DisplayFrames: [[Float]] = []
    @Published var osc2WavetableName = "Init"

    @Published var osc3On = false
    @Published var osc3Level: Float = 0
    @Published var osc3Pan: Float = 0.5
    @Published var osc3Transpose: Float = 0
    @Published var osc3WaveForm = 0
    @Published var osc3WaveFrame: Float = 0
    @Published var osc3UnisonVoices = 1
    @Published var osc3UnisonDetune: Float = 0.4472
    @Published var osc3DetunePower: Float = 0.65
    @Published var osc3Phase: Float = 0.5
    @Published var osc3RandomPhase: Float = 1.0
    @Published var osc3SpectralMorphType = 0
    @Published var osc3SpectralMorphAmount: Float = 0.5
    @Published var osc3DistortionType = 0
    @Published var osc3DistortionAmount: Float = 0.5
    @Published var osc3Destination = 0
    @Published var osc3FilterRoute = 0
    @Published var osc3DisplayFrames: [[Float]] = []
    @Published var osc3WavetableName = "Init"

    // MARK: Sample
    @Published var sampleOn = false
    @Published var sampleLevel: Float = 0.7071
    @Published var samplePan: Float = 0.5
    @Published var sampleTranspose: Float = 0
    @Published var sampleLoop = true
    @Published var sampleBounce = false
    @Published var sampleKeytrack = false
    @Published var sampleDisplayFrames: [Float] = []

    // MARK: Filters
    @Published var filter1On = true
    @Published var filterCutoff: Float = 100
    @Published var filterResonance: Float = 0.5
    @Published var filterDrive: Float = 0
    @Published var filterModel = 0
    @Published var filter1Blend: Float = 0
    @Published var filter1Style = 0

    @Published var filter2On = true
    @Published var filter2Cutoff: Float = 100
    @Published var filter2Resonance: Float = 0.5
    @Published var filter2Drive: Float = 0
    @Published var filter2Model = 0
    @Published var filter2Blend: Float = 0
    @Published var filter2Style = 0

    // MARK: Envelopes
    @Published var env1Attack: Float = 0.003
    @Published var env1Hold: Float = 0
    @Published var env1Decay: Float = 0.25
    @Published var env1Sustain: Float = 0.70
    @Published var env1Release: Float = 0.40

    @Published var env2Attack: Float = 0.003
    @Published var env2Hold: Float = 0
    @Published var env2Decay: Float = 0.40
    @Published var env2Sustain: Float = 0
    @Published var env2Release: Float = 0.30

    @Published var env3Attack: Float = 0
    @Published var env3Hold: Float = 0
    @Published var env3Decay: Float = 1
    @Published var env3Sustain: Float = 1
    @Published var env3Release: Float = 0.5476

    @Published var env4Attack: Float = 0
    @Published var env4Hold: Float = 0
    @Published var env4Decay: Float = 1
    @Published var env4Sustain: Float = 1
    @Published var env4Release: Float = 0.5476

    @Published var env5Attack: Float = 0
    @Published var env5Hold: Float = 0
    @Published var env5Decay: Float = 1
    @Published var env5Sustain: Float = 1
    @Published var env5Release: Float = 0.5476

    @Published var env6Attack: Float = 0
    @Published var env6Hold: Float = 0
    @Published var env6Decay: Float = 1
    @Published var env6Sustain: Float = 1
    @Published var env6Release: Float = 0.5476

    // MARK: LFOs
    @Published var lfoRates: [Float] = Array(repeating: 0.25, count: 8)
    @Published var lfoPhases: [Float] = Array(repeating: 0, count: 8)
    @Published var lfoSyncs: [Int] = Array(repeating: 1, count: 8)
    @Published var lfoAmounts: [Float] = [0.3, 0, 0, 0, 0, 0, 0, 0]
    @Published var lfoTargets: [Int] = Array(repeating: 0, count: 8)
    @Published var lfo1Rate: Float = 0.25
    @Published var lfo1Amount: Float = 0.3
    @Published var lfo1Target = 0

    // MARK: Random / Macros
    @Published var randomStyle: [Int] = Array(repeating: 0, count: 4)
    @Published var randomRate: [Float] = Array(repeating: 0.5, count: 4)
    @Published var macro: [Float] = Array(repeating: 0, count: 4)

    // MARK: FX
    @Published var chorusOn = false
    @Published var chorusMix: Float = 0
    @Published var chorusFeedback: Float = 0.5
    @Published var chorusModDepth: Float = 0.5
    @Published var chorusFrequency: Float = 0.333

    @Published var compressorOn = false
    @Published var compressorMix: Float = 1
    @Published var compressorAttack: Float = 0.5
    @Published var compressorRelease: Float = 0.5

    @Published var delayOn = false
    @Published var delayMix: Float = 0
    @Published var delayFeedback: Float = 0.5
    @Published var delayFrequency: Float = 0.3636

    @Published var distortionOn = false
    @Published var distortionMix: Float = 0
    @Published var distortionDrive: Float = 0.5
    @Published var distortionType = 0

    @Published var equalizerOn = false
    @Published var equalizerLowGain: Float = 0
    @Published var equalizerMidGain: Float = 0
    @Published var equalizerHighGain: Float = 0

    @Published var filterFxOn = false
    @Published var filterFxCutoff: Float = 60
    @Published var filterFxResonance: Float = 0.5

    @Published var flangerOn = false
    @Published var flangerDryWet: Float = 0
    @Published var flangerFeedback: Float = 0.5
    @Published var flangerCenter: Float = 64
    @Published var flangerModDepth: Float = 0.5

    @Published var phaserOn = false
    @Published var phaserDryWet: Float = 0
    @Published var phaserFeedback: Float = 0.5
    @Published var phaserCenter: Float = 80
    @Published var phaserModDepth: Float = 0.5

    @Published var reverbOn = false
    @Published var reverbMix: Float = 0
    @Published var reverbSize: Float = 0.5
    @Published var reverbDecay: Float = 0.5
    @Published var reverbChorusAmount: Float = 0.2236

    @Published var effectChainOrder: [Int] = Array(0..<9)

    // MARK: Voice / Master
    @Published var legato = false
    @Published var glide: Float = 0
    @Published var polyphony = 16
    @Published var pitchBendRange: Float = 2
    @Published var masterVolume: Float = 0.8601
    @Published var currentPatch = "Init"
    @Published var modConnections: [ModConnection] = []

    init(au: VitalAUAudioUnit) {
        self.au = au
        loadFromAU()
    }

    // MARK: Tree / engine helpers

    func set(_ addr: AUParameterAddress, _ value: Float) {
        au.parameterTree?.parameter(withAddress: addr)?.setValue(value, originator: nil)
    }

    func setEngineParameter(_ name: String, _ value: Float) {
        au.setEngineParameter(name, value: value)
    }

    private func eng(_ name: String, _ value: Float) {
        au.setEngineParameter(name, value: value)
    }

    private func tree(_ addr: AUParameterAddress) -> Float {
        au.parameterTree?.parameter(withAddress: addr)?.value ?? 0
    }

    func refreshDisplayFrames(oscillatorIndex: Int) {
        let frames = au.displayFrames(forOscillator: oscillatorIndex)
        let name = au.wavetableName(forOscillator: oscillatorIndex)
        switch oscillatorIndex {
        case 0:
            osc1DisplayFrames = frames
            osc1WavetableName = name
        case 1:
            osc2DisplayFrames = frames
            osc2WavetableName = name
        case 2:
            osc3DisplayFrames = frames
            osc3WavetableName = name
        default: break
        }
    }

    func refreshSampleDisplay() {
        sampleDisplayFrames = au.sampleDisplayFrames()
    }

    // MARK: Wavetable editing

    func wavetableFrameCount(oscillatorIndex: Int) -> Int {
        au.wavetableFrameCount(oscillatorIndex: oscillatorIndex)
    }

    func waveFramePosition(oscillatorIndex: Int) -> Float {
        au.waveFramePosition(oscillatorIndex: oscillatorIndex)
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
        au.getWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frame)
    }

    @discardableResult
    func setWavetableFrame(_ samples: [Float], oscillatorIndex: Int, frame: Int) -> Bool {
        au.setWavetableFrame(samples, oscillatorIndex: oscillatorIndex, frame: frame)
    }

    @discardableResult
    func fillWavetableFrame(shape: Int, oscillatorIndex: Int, frame: Int) -> Bool {
        au.fillWavetableFrame(shape: shape, oscillatorIndex: oscillatorIndex, frame: frame)
    }

    @discardableResult
    func commitWavetable(oscillatorIndex: Int) -> Bool {
        let ok = au.commitWavetable(oscillatorIndex: oscillatorIndex)
        if ok { refreshDisplayFrames(oscillatorIndex: oscillatorIndex) }
        return ok
    }

    @discardableResult
    func expandWavetable(toFrames count: Int, oscillatorIndex: Int, interpolate: Bool = true) -> Bool {
        let ok = au.expandWavetable(toFrames: count, oscillatorIndex: oscillatorIndex, interpolate: interpolate)
        if ok { refreshDisplayFrames(oscillatorIndex: oscillatorIndex) }
        return ok
    }

    func getWavetableAmplitudes(oscillatorIndex: Int, frame: Int, harmonicCount: Int = 64) -> [Float] {
        au.getWavetableAmplitudes(oscillatorIndex: oscillatorIndex, frame: frame, harmonicCount: harmonicCount)
    }

    func getWavetablePhases(oscillatorIndex: Int, frame: Int, harmonicCount: Int = 64) -> [Float] {
        au.getWavetablePhases(oscillatorIndex: oscillatorIndex, frame: frame, harmonicCount: harmonicCount)
    }

    @discardableResult
    func setWavetableSpectrum(amplitudes: [Float], phases: [Float]?, oscillatorIndex: Int, frame: Int) -> Bool {
        au.setWavetableSpectrum(amplitudes: amplitudes, phases: phases,
                                oscillatorIndex: oscillatorIndex, frame: frame)
    }

    typealias LfoPoint = VitalAUAudioUnit.LfoPoint

    func lfoPoints(index: Int) -> [LfoPoint] { au.lfoPoints(index: index) }
    func lfoDisplayBuffer(index: Int) -> [Float] { au.lfoDisplayBuffer(index: index) }

    @discardableResult
    func setLfoPoint(index: Int, pointIndex: Int, x: Float, y: Float) -> Bool {
        au.setLfoPoint(index: index, pointIndex: pointIndex, x: x, y: y)
    }

    @discardableResult
    func addLfoPoint(index: Int, after: Int, x: Float, y: Float) -> Bool {
        au.addLfoPoint(index: index, after: after, x: x, y: y)
    }

    @discardableResult
    func removeLfoPoint(index: Int, pointIndex: Int) -> Bool {
        au.removeLfoPoint(index: index, pointIndex: pointIndex)
    }

    @discardableResult
    func initLfoShape(index: Int, shape: Int) -> Bool {
        au.initLfoShape(index: index, shape: shape)
    }

    func lfoPowers(index: Int) -> [Float] { au.lfoPowers(index: index) }

    @discardableResult
    func setLfoPower(index: Int, pointIndex: Int, value: Float) -> Bool {
        au.setLfoPower(index: index, pointIndex: pointIndex, value: value)
    }

    func lfoSmooth(index: Int) -> Bool { au.lfoSmooth(index: index) }

    @discardableResult
    func setLfoSmooth(index: Int, enabled: Bool) -> Bool {
        au.setLfoSmooth(index: index, enabled: enabled)
    }

    @discardableResult
    func flipLfoHorizontal(index: Int) -> Bool { au.flipLfoHorizontal(index: index) }

    @discardableResult
    func flipLfoVertical(index: Int) -> Bool { au.flipLfoVertical(index: index) }

    @discardableResult
    func normalizeWavetableFrame(oscillatorIndex: Int, frame: Int, removeDC: Bool = true) -> Bool {
        au.normalizeWavetableFrame(oscillatorIndex: oscillatorIndex, frame: frame, removeDC: removeDC)
    }

    func lfoStateJSON(index: Int) -> Data? { au.lfoStateJSON(index: index) }

    @discardableResult
    func setLfoStateJSON(index: Int, data: Data) -> Bool {
        au.setLfoStateJSON(index: index, data: data)
    }

    @discardableResult
    func interpolateWavetableFrames(from: Int, to: Int, spectral: Bool, oscillatorIndex: Int) -> Bool {
        au.interpolateWavetableFrames(from: from, to: to, spectral: spectral, oscillatorIndex: oscillatorIndex)
    }

    @discardableResult
    func copyWavetableFrame(from: Int, to: Int, oscillatorIndex: Int) -> Bool {
        au.copyWavetableFrame(from: from, to: to, oscillatorIndex: oscillatorIndex)
    }

    private func loadFromAU() {
        osc1On = tree(0) > 0.5; osc1Level = tree(1); osc1Pan = tree(2)
        osc1Transpose = tree(3); osc1WaveForm = Int(tree(4).rounded()); osc1WaveFrame = tree(33)
        osc2On = tree(5) > 0.5; osc2Level = tree(6); osc2Pan = tree(7)
        osc2Transpose = tree(8); osc2WaveForm = Int(tree(9).rounded()); osc2WaveFrame = tree(34)
        osc3On = tree(10) > 0.5; osc3Level = tree(11); osc3Pan = tree(12)
        osc3Transpose = tree(13); osc3WaveForm = Int(tree(14).rounded()); osc3WaveFrame = tree(35)

        filterCutoff = tree(15); filterResonance = tree(16)
        filterDrive = tree(17); filterModel = Int(tree(18).rounded())
        filter2Cutoff = tree(36); filter2Resonance = tree(37)
        filter2Drive = tree(38); filter2Model = Int(tree(39).rounded())
        osc1FilterRoute = Int(tree(40).rounded()); osc1Destination = osc1FilterRoute
        osc2FilterRoute = Int(tree(41).rounded()); osc2Destination = osc2FilterRoute
        osc3FilterRoute = Int(tree(42).rounded()); osc3Destination = osc3FilterRoute

        env1Attack = tree(19); env1Decay = tree(20); env1Sustain = tree(21); env1Release = tree(22)
        env2Attack = tree(23); env2Decay = tree(24); env2Sustain = tree(25); env2Release = tree(26)

        lfo1Rate = tree(27); lfoRates[0] = lfo1Rate
        lfo1Amount = tree(43); lfoAmounts[0] = lfo1Amount
        lfo1Target = Int(tree(44).rounded()); lfoTargets[0] = lfo1Target
        for i in 1..<8 { lfoRates[i] = tree(AUParameterAddress(50 + i)) } // 51…57

        reverbMix = tree(28); delayMix = tree(29); chorusMix = tree(30); distortionMix = tree(31)
        reverbOn = reverbMix > 0.01; delayOn = delayMix > 0.01
        chorusOn = chorusMix > 0.01; distortionOn = distortionMix > 0.01
        masterVolume = tree(32)
        legato = tree(45) > 0.5; glide = tree(46)

        for i in 0..<4 { macro[i] = tree(AUParameterAddress(47 + i)) }
        osc1UnisonVoices = Int(tree(58).rounded()); osc2UnisonVoices = Int(tree(59).rounded())
        osc3UnisonVoices = Int(tree(60).rounded())
        osc1UnisonDetune = tree(61); osc2UnisonDetune = tree(62); osc3UnisonDetune = tree(63)
        osc1Phase = tree(64); osc2Phase = tree(65); osc3Phase = tree(66)
        sampleOn = tree(67) > 0.5; sampleLevel = tree(68)
        filter1Blend = tree(69); filter2Blend = tree(70)
        refreshModulations()
        refreshSampleDisplay()
    }


    func setOsc1On(_ v: Bool) { osc1On = v; set(0, v ? 1 : 0) }
    func setOsc1Level(_ v: Float) { osc1Level = v; set(1, v) }
    func setOsc1Pan(_ v: Float) { osc1Pan = v; set(2, v) }
    func setOsc1Transpose(_ v: Float) { osc1Transpose = v; set(3, v) }
    func setOsc1Waveform(_ shape: Int) {
        osc1WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc1WaveFrame = f
        set(4, Float(shape)); set(33, f)
    }
    func setOsc1WaveFrame(_ v: Float) { osc1WaveFrame = v; set(33, v) }
    func setOsc1UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16); osc1UnisonVoices = c; set(58, Float(c))
    }
    func setOsc1UnisonDetune(_ v: Float) { osc1UnisonDetune = v; set(61, v) }
    func setOsc1DetunePower(_ v: Float) {
        osc1DetunePower = v; eng("osc_1_detune_power", -5 + 10 * v)
    }
    func setOsc1Phase(_ v: Float) { osc1Phase = v; set(64, v) }
    func setOsc1RandomPhase(_ v: Float) {
        osc1RandomPhase = v; eng("osc_1_random_phase", v)
    }
    func setOsc1SpectralMorphType(_ v: Int) {
        osc1SpectralMorphType = min(max(v, 0), 11)
        eng("osc_1_spectral_morph_type", Float(osc1SpectralMorphType))
    }
    func setOsc1SpectralMorphAmount(_ v: Float) {
        osc1SpectralMorphAmount = v; eng("osc_1_spectral_morph_amount", v)
    }
    func setOsc1DistortionType(_ v: Int) {
        osc1DistortionType = min(max(v, 0), 12)
        eng("osc_1_distortion_type", Float(osc1DistortionType))
    }
    func setOsc1DistortionAmount(_ v: Float) {
        osc1DistortionAmount = v; eng("osc_1_distortion_amount", v)
    }
    func setOsc1Destination(_ v: Int) {
        osc1Destination = v
        eng("osc_1_destination", Float(v))
        if v <= 2 {
            osc1FilterRoute = v
            set(40, Float(v))
        }
    }
    func setOsc1FilterRoute(_ v: Int) {
        osc1FilterRoute = v; osc1Destination = v; set(40, Float(v))
    }

    func setOsc2On(_ v: Bool) { osc2On = v; set(5, v ? 1 : 0) }
    func setOsc2Level(_ v: Float) { osc2Level = v; set(6, v) }
    func setOsc2Pan(_ v: Float) { osc2Pan = v; set(7, v) }
    func setOsc2Transpose(_ v: Float) { osc2Transpose = v; set(8, v) }
    func setOsc2Waveform(_ shape: Int) {
        osc2WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc2WaveFrame = f
        set(9, Float(shape)); set(34, f)
    }
    func setOsc2WaveFrame(_ v: Float) { osc2WaveFrame = v; set(34, v) }
    func setOsc2UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16); osc2UnisonVoices = c; set(59, Float(c))
    }
    func setOsc2UnisonDetune(_ v: Float) { osc2UnisonDetune = v; set(62, v) }
    func setOsc2DetunePower(_ v: Float) {
        osc2DetunePower = v; eng("osc_2_detune_power", -5 + 10 * v)
    }
    func setOsc2Phase(_ v: Float) { osc2Phase = v; set(65, v) }
    func setOsc2RandomPhase(_ v: Float) {
        osc2RandomPhase = v; eng("osc_2_random_phase", v)
    }
    func setOsc2SpectralMorphType(_ v: Int) {
        osc2SpectralMorphType = min(max(v, 0), 11)
        eng("osc_2_spectral_morph_type", Float(osc2SpectralMorphType))
    }
    func setOsc2SpectralMorphAmount(_ v: Float) {
        osc2SpectralMorphAmount = v; eng("osc_2_spectral_morph_amount", v)
    }
    func setOsc2DistortionType(_ v: Int) {
        osc2DistortionType = min(max(v, 0), 12)
        eng("osc_2_distortion_type", Float(osc2DistortionType))
    }
    func setOsc2DistortionAmount(_ v: Float) {
        osc2DistortionAmount = v; eng("osc_2_distortion_amount", v)
    }
    func setOsc2Destination(_ v: Int) {
        osc2Destination = v
        eng("osc_2_destination", Float(v))
        if v <= 2 {
            osc2FilterRoute = v
            set(41, Float(v))
        }
    }
    func setOsc2FilterRoute(_ v: Int) {
        osc2FilterRoute = v; osc2Destination = v; set(41, Float(v))
    }

    func setOsc3On(_ v: Bool) { osc3On = v; set(10, v ? 1 : 0) }
    func setOsc3Level(_ v: Float) { osc3Level = v; set(11, v) }
    func setOsc3Pan(_ v: Float) { osc3Pan = v; set(12, v) }
    func setOsc3Transpose(_ v: Float) { osc3Transpose = v; set(13, v) }
    func setOsc3Waveform(_ shape: Int) {
        osc3WaveForm = shape
        let frames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        let f = frames[min(max(shape, 0), frames.count - 1)]
        osc3WaveFrame = f
        set(14, Float(shape)); set(35, f)
    }
    func setOsc3WaveFrame(_ v: Float) { osc3WaveFrame = v; set(35, v) }
    func setOsc3UnisonVoices(_ v: Int) {
        let c = min(max(v, 1), 16); osc3UnisonVoices = c; set(60, Float(c))
    }
    func setOsc3UnisonDetune(_ v: Float) { osc3UnisonDetune = v; set(63, v) }
    func setOsc3DetunePower(_ v: Float) {
        osc3DetunePower = v; eng("osc_3_detune_power", -5 + 10 * v)
    }
    func setOsc3Phase(_ v: Float) { osc3Phase = v; set(66, v) }
    func setOsc3RandomPhase(_ v: Float) {
        osc3RandomPhase = v; eng("osc_3_random_phase", v)
    }
    func setOsc3SpectralMorphType(_ v: Int) {
        osc3SpectralMorphType = min(max(v, 0), 11)
        eng("osc_3_spectral_morph_type", Float(osc3SpectralMorphType))
    }
    func setOsc3SpectralMorphAmount(_ v: Float) {
        osc3SpectralMorphAmount = v; eng("osc_3_spectral_morph_amount", v)
    }
    func setOsc3DistortionType(_ v: Int) {
        osc3DistortionType = min(max(v, 0), 12)
        eng("osc_3_distortion_type", Float(osc3DistortionType))
    }
    func setOsc3DistortionAmount(_ v: Float) {
        osc3DistortionAmount = v; eng("osc_3_distortion_amount", v)
    }
    func setOsc3Destination(_ v: Int) {
        osc3Destination = v
        eng("osc_3_destination", Float(v))
        if v <= 2 {
            osc3FilterRoute = v
            set(42, Float(v))
        }
    }
    func setOsc3FilterRoute(_ v: Int) {
        osc3FilterRoute = v; osc3Destination = v; set(42, Float(v))
    }

    // MARK: Sample
    func setSampleOn(_ v: Bool) { sampleOn = v; set(67, v ? 1 : 0) }
    func setSampleLevel(_ v: Float) { sampleLevel = v; set(68, v) }
    func setSamplePan(_ v: Float) { samplePan = v; eng("sample_pan", v * 2 - 1) }
    func setSampleTranspose(_ v: Float) { sampleTranspose = v; eng("sample_transpose", v) }
    func setSampleLoop(_ v: Bool) { sampleLoop = v; eng("sample_loop", v ? 1 : 0) }
    func setSampleBounce(_ v: Bool) { sampleBounce = v; eng("sample_bounce", v ? 1 : 0) }
    func setSampleKeytrack(_ v: Bool) { sampleKeytrack = v; eng("sample_keytrack", v ? 1 : 0) }

    // MARK: Filters
    func setFilter1On(_ v: Bool) { filter1On = v; au.setFilterOn(1, v) }
    func setFilterCutoff(_ v: Float) { filterCutoff = v; set(15, v) }
    func setFilterResonance(_ v: Float) { filterResonance = v; set(16, v) }
    func setFilterDrive(_ v: Float) { filterDrive = v; set(17, v) }
    func setFilterModel(_ model: Int) { filterModel = min(max(model, 0), 7); set(18, Float(filterModel)) }
    func setFilter1Blend(_ v: Float) { filter1Blend = v; set(69, v) }
    func setFilter1Style(_ v: Int) { filter1Style = v; eng("filter_1_style", Float(v)) }

    func setFilter2On(_ v: Bool) { filter2On = v; au.setFilterOn(2, v) }
    func setFilter2Cutoff(_ v: Float) { filter2Cutoff = v; set(36, v) }
    func setFilter2Resonance(_ v: Float) { filter2Resonance = v; set(37, v) }
    func setFilter2Drive(_ v: Float) { filter2Drive = v; set(38, v) }
    func setFilter2Model(_ model: Int) { filter2Model = min(max(model, 0), 7); set(39, Float(filter2Model)) }
    func setFilter2Blend(_ v: Float) { filter2Blend = v; set(70, v) }
    func setFilter2Style(_ v: Int) { filter2Style = v; eng("filter_2_style", Float(v)) }

    // MARK: Envelopes
    func setEnv1Attack(_ v: Float) { env1Attack = v; set(19, v) }
    func setEnv1Hold(_ v: Float) { env1Hold = v; eng("env_1_hold", v) }
    func setEnv1Decay(_ v: Float) { env1Decay = v; set(20, v) }
    func setEnv1Sustain(_ v: Float) { env1Sustain = v; set(21, v) }
    func setEnv1Release(_ v: Float) { env1Release = v; set(22, v) }

    func setEnv2Attack(_ v: Float) { env2Attack = v; set(23, v) }
    func setEnv2Hold(_ v: Float) { env2Hold = v; eng("env_2_hold", v) }
    func setEnv2Decay(_ v: Float) { env2Decay = v; set(24, v) }
    func setEnv2Sustain(_ v: Float) { env2Sustain = v; set(25, v) }
    func setEnv2Release(_ v: Float) { env2Release = v; set(26, v) }

    func setEnv3Attack(_ v: Float) { env3Attack = v; eng("env_3_attack", v) }
    func setEnv3Hold(_ v: Float) { env3Hold = v; eng("env_3_hold", v) }
    func setEnv3Decay(_ v: Float) { env3Decay = v; eng("env_3_decay", v) }
    func setEnv3Sustain(_ v: Float) { env3Sustain = v; eng("env_3_sustain", v) }
    func setEnv3Release(_ v: Float) { env3Release = v; eng("env_3_release", v) }

    func setEnv4Attack(_ v: Float) { env4Attack = v; eng("env_4_attack", v) }
    func setEnv4Hold(_ v: Float) { env4Hold = v; eng("env_4_hold", v) }
    func setEnv4Decay(_ v: Float) { env4Decay = v; eng("env_4_decay", v) }
    func setEnv4Sustain(_ v: Float) { env4Sustain = v; eng("env_4_sustain", v) }
    func setEnv4Release(_ v: Float) { env4Release = v; eng("env_4_release", v) }

    func setEnv5Attack(_ v: Float) { env5Attack = v; eng("env_5_attack", v) }
    func setEnv5Hold(_ v: Float) { env5Hold = v; eng("env_5_hold", v) }
    func setEnv5Decay(_ v: Float) { env5Decay = v; eng("env_5_decay", v) }
    func setEnv5Sustain(_ v: Float) { env5Sustain = v; eng("env_5_sustain", v) }
    func setEnv5Release(_ v: Float) { env5Release = v; eng("env_5_release", v) }

    func setEnv6Attack(_ v: Float) { env6Attack = v; eng("env_6_attack", v) }
    func setEnv6Hold(_ v: Float) { env6Hold = v; eng("env_6_hold", v) }
    func setEnv6Decay(_ v: Float) { env6Decay = v; eng("env_6_decay", v) }
    func setEnv6Sustain(_ v: Float) { env6Sustain = v; eng("env_6_sustain", v) }
    func setEnv6Release(_ v: Float) { env6Release = v; eng("env_6_release", v) }


    // MARK: LFO
    private static func lfoFrequency(fromNormalized v: Float) -> Float { -7 + 16 * v }

    func setLfoRate(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoRates[index] = v
        if index == 0 { lfo1Rate = v; set(27, v) }
        else { set(AUParameterAddress(50 + index), v) } // 51…57
    }
    func setLfoPhase(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoPhases[index] = v
        eng("lfo_\(index + 1)_phase", v)
    }
    func setLfoSync(_ index: Int, _ v: Int) {
        guard (0..<8).contains(index) else { return }
        lfoSyncs[index] = v
        eng("lfo_\(index + 1)_sync", Float(v))
    }
    func setLfoAmount(_ index: Int, _ v: Float) {
        guard (0..<8).contains(index) else { return }
        lfoAmounts[index] = v
        if index == 0 { lfo1Amount = v; set(43, v) }
        let ti = min(lfoTargets[index], Self.lfoTargets.count - 1)
        au.setModulationAmount(v, source: "lfo_\(index + 1)", destination: Self.lfoTargets[ti])
    }
    func setLfoTarget(_ index: Int, _ t: Int) {
        guard (0..<8).contains(index) else { return }
        let oldTi = min(lfoTargets[index], Self.lfoTargets.count - 1)
        au.setModulationAmount(0, source: "lfo_\(index + 1)", destination: Self.lfoTargets[oldTi])
        lfoTargets[index] = t
        if index == 0 { lfo1Target = t; set(44, Float(t)) }
        let newTi = min(t, Self.lfoTargets.count - 1)
        au.setModulationAmount(lfoAmounts[index], source: "lfo_\(index + 1)", destination: Self.lfoTargets[newTi])
    }
    func setLfo1Rate(_ v: Float) { setLfoRate(0, v) }
    func setLfo1Amount(_ v: Float) { setLfoAmount(0, v) }
    func setLfo1Target(_ t: Int) { setLfoTarget(0, t) }

    func setRandomStyle(_ index: Int, _ v: Int) {
        guard (0..<4).contains(index) else { return }
        randomStyle[index] = v; eng("random_\(index + 1)_style", Float(v))
    }
    func setRandomRate(_ index: Int, _ v: Float) {
        guard (0..<4).contains(index) else { return }
        randomRate[index] = v; eng("random_\(index + 1)_frequency", Self.lfoFrequency(fromNormalized: v))
    }
    func setMacro(_ index: Int, _ v: Float) {
        guard (0..<4).contains(index) else { return }
        macro[index] = v; set(AUParameterAddress(47 + index), v)
    }

    // MARK: FX
    func setChorusOn(_ v: Bool) { chorusOn = v; eng("chorus_on", v ? 1 : 0) }
    func setChorusMix(_ v: Float) {
        chorusMix = v; set(30, v)
        if v > 0.01 { chorusOn = true }
        eng("chorus_on", (chorusOn || v > 0.01) ? 1 : 0)
    }
    func setChorusFeedback(_ v: Float) { chorusFeedback = v; eng("chorus_feedback", -0.95 + 1.9 * v) }
    func setChorusModDepth(_ v: Float) { chorusModDepth = v; eng("chorus_mod_depth", v) }
    func setChorusFrequency(_ v: Float) { chorusFrequency = v; eng("chorus_frequency", -6 + 9 * v) }

    func setCompressorOn(_ v: Bool) { compressorOn = v; eng("compressor_on", v ? 1 : 0) }
    func setCompressorMix(_ v: Float) { compressorMix = v; eng("compressor_mix", v) }
    func setCompressorAttack(_ v: Float) { compressorAttack = v; eng("compressor_attack", v) }
    func setCompressorRelease(_ v: Float) { compressorRelease = v; eng("compressor_release", v) }

    func setDelayOn(_ v: Bool) { delayOn = v; eng("delay_on", v ? 1 : 0) }
    func setDelayMix(_ v: Float) {
        delayMix = v; set(29, v)
        if v > 0.01 { delayOn = true }
        eng("delay_on", (delayOn || v > 0.01) ? 1 : 0)
    }
    func setDelayFeedback(_ v: Float) { delayFeedback = v; eng("delay_feedback", v * 2 - 1) }
    func setDelayFrequency(_ v: Float) { delayFrequency = v; eng("delay_frequency", -2 + 11 * v) }

    func setDistortionOn(_ v: Bool) { distortionOn = v; eng("distortion_on", v ? 1 : 0) }
    func setDistortionMix(_ v: Float) {
        distortionMix = v; set(31, v)
        if v > 0.01 { distortionOn = true }
        eng("distortion_on", (distortionOn || v > 0.01) ? 1 : 0)
    }
    func setDistortionDrive(_ v: Float) { distortionDrive = v; eng("distortion_drive", -30 + 60 * v) }
    func setDistortionType(_ v: Int) { distortionType = v; eng("distortion_type", Float(v)) }

    func setEqualizerOn(_ v: Bool) {
        equalizerOn = v; eng("eq_on", v ? 1 : 0); eng("equalizer_on", v ? 1 : 0)
    }
    func setEqualizerLowGain(_ v: Float) { equalizerLowGain = v; eng("eq_low_gain", v) }
    func setEqualizerMidGain(_ v: Float) { equalizerMidGain = v; eng("eq_band_gain", v) }
    func setEqualizerHighGain(_ v: Float) { equalizerHighGain = v; eng("eq_high_gain", v) }

    func setFilterFxOn(_ v: Bool) { filterFxOn = v; eng("filter_fx_on", v ? 1 : 0) }
    func setFilterFxCutoff(_ v: Float) { filterFxCutoff = v; eng("filter_fx_cutoff", v) }
    func setFilterFxResonance(_ v: Float) { filterFxResonance = v; eng("filter_fx_resonance", v) }

    func setFlangerOn(_ v: Bool) { flangerOn = v; eng("flanger_on", v ? 1 : 0) }
    func setFlangerDryWet(_ v: Float) {
        flangerDryWet = v; eng("flanger_dry_wet", v)
        if v > 0.01 { flangerOn = true }
        eng("flanger_on", (flangerOn || v > 0.01) ? 1 : 0)
    }
    func setFlangerFeedback(_ v: Float) { flangerFeedback = v; eng("flanger_feedback", v * 2 - 1) }
    func setFlangerCenter(_ v: Float) { flangerCenter = v; eng("flanger_center", v) }
    func setFlangerModDepth(_ v: Float) { flangerModDepth = v; eng("flanger_mod_depth", v) }

    func setPhaserOn(_ v: Bool) { phaserOn = v; eng("phaser_on", v ? 1 : 0) }
    func setPhaserDryWet(_ v: Float) {
        phaserDryWet = v; eng("phaser_dry_wet", v)
        if v > 0.01 { phaserOn = true }
        eng("phaser_on", (phaserOn || v > 0.01) ? 1 : 0)
    }
    func setPhaserFeedback(_ v: Float) { phaserFeedback = v; eng("phaser_feedback", v) }
    func setPhaserCenter(_ v: Float) { phaserCenter = v; eng("phaser_center", v) }
    func setPhaserModDepth(_ v: Float) { phaserModDepth = v; eng("phaser_mod_depth", v * 48) }

    func setReverbOn(_ v: Bool) { reverbOn = v; eng("reverb_on", v ? 1 : 0) }
    func setReverbMix(_ v: Float) {
        reverbMix = v; set(28, v)
        if v > 0.01 { reverbOn = true }
        eng("reverb_on", (reverbOn || v > 0.01) ? 1 : 0)
    }
    func setReverbSize(_ v: Float) { reverbSize = v; eng("reverb_size", v) }
    func setReverbDecay(_ v: Float) { reverbDecay = v; eng("reverb_decay_time", -6 + 12 * v) }
    func setReverbChorusAmount(_ v: Float) { reverbChorusAmount = v; eng("reverb_chorus_amount", v) }

    func loadEffectChainOrder() {
        let code = au.getEngineParameter("effect_chain_order")
        effectChainOrder = Self.decodeEffectOrder(code, size: 9)
    }

    func setEffectChainOrder(_ order: [Int]) {
        guard order.count == 9, Set(order) == Set(0..<9) else { return }
        effectChainOrder = order
        eng("effect_chain_order", Self.encodeEffectOrder(order))
    }

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

    // MARK: Voice
    func setLegato(_ v: Bool) {
        legato = v; set(45, v ? 1 : 0)
        eng("polyphony", v ? 1 : Float(polyphony))
    }
    func setGlide(_ v: Float) { glide = v; set(46, v) }
    func setPolyphony(_ v: Int) {
        let c = min(max(v, 1), 32); polyphony = c
        if !legato { eng("polyphony", Float(c)) }
    }
    func setPitchBendRange(_ v: Float) {
        pitchBendRange = min(max(v, 0), 48); eng("pitch_bend_range", pitchBendRange)
    }
    func setMasterVolume(_ v: Float) { masterVolume = v; set(32, v) }

    // MARK: Modulation matrix
    @Published var modulationSources: [String] = []
    @Published var modulationDestinations: [String] = []

    func addModulation(source: String, destination: String, amount: Float) {
        _ = au.connectModulation(source, to: destination, amount: amount)
        refreshModulations()
    }
    func updateModulation(source: String, destination: String, amount: Float) {
        au.setModulationAmount(amount, source: source, destination: destination)
        if let idx = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[idx].amount = amount
        } else { refreshModulations() }
    }
    func setModulationBipolar(source: String, destination: String, _ v: Bool) {
        au.setModulationBipolar(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].bipolar = v
        }
    }
    func setModulationStereo(source: String, destination: String, _ v: Bool) {
        au.setModulationStereo(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].stereo = v
        }
    }
    func setModulationBypass(source: String, destination: String, _ v: Bool) {
        au.setModulationBypass(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].bypass = v
        }
    }
    func setModulationPower(source: String, destination: String, _ v: Float) {
        au.setModulationPower(v, source: source, destination: destination)
        if let i = modConnections.firstIndex(where: { $0.source == source && $0.destination == destination }) {
            modConnections[i].power = v
        }
    }
    func removeModulation(source: String, destination: String) {
        au.disconnectModulation(source, from: destination)
        modConnections.removeAll { $0.source == source && $0.destination == destination }
    }
    func refreshModulationLists() {
        let src = au.modulationSourceNames()
        let dst = au.modulationDestinationNames()
        if !src.isEmpty { modulationSources = src }
        if !dst.isEmpty { modulationDestinations = dst }
    }
    func refreshModulations() {
        refreshModulationLists()
        modConnections = au.listModulations().compactMap { dict -> ModConnection? in
            guard let source = dict["source"] as? String,
                  let destination = dict["destination"] as? String else { return nil }
            let amount: Float
            if let f = dict["amount"] as? Float { amount = f }
            else if let d = dict["amount"] as? Double { amount = Float(d) }
            else if let n = dict["amount"] as? NSNumber { amount = n.floatValue }
            else { amount = 0 }
            return ModConnection(
                source: source, destination: destination, amount: amount,
                bipolar: (dict["bipolar"] as? NSNumber)?.boolValue ?? false,
                stereo: (dict["stereo"] as? NSNumber)?.boolValue ?? false,
                bypass: (dict["bypass"] as? NSNumber)?.boolValue ?? false,
                power: (dict["power"] as? NSNumber)?.floatValue ?? 0,
                index: (dict["index"] as? NSNumber)?.intValue ?? 0
            )
        }
    }

    // MARK: MIDI / loading
    func noteOn(note: Int32, velocity: Float) { au.noteOn(note: note, velocity: velocity) }
    func noteOff(_ note: Int32) { au.noteOff(note) }
    func allNotesOff() { au.allNotesOff() }
    func sendPitchBend(_ v: Float) { au.sendPitchBend(v) }
    func sendModWheel(_ v: Float) { au.sendModWheel(v) }

    func loadVitalPreset(from url: URL) {
        osc1DisplayFrames = []; osc2DisplayFrames = []; osc3DisplayFrames = []
        sampleDisplayFrames = []
        au.loadVitalPreset(from: url) { [weak self] name in
            guard let self else { return }
            self.loadFromAU()
            self.currentPatch = name
            self.refreshDisplayFrames(oscillatorIndex: 0)
            self.refreshDisplayFrames(oscillatorIndex: 1)
            self.refreshDisplayFrames(oscillatorIndex: 2)
            self.refreshSampleDisplay()
            self.refreshModulations()
        }
    }

    func resetToInit() {
        au.resetToInit()
        au.setFilterOn(1, true); au.setFilterOn(2, true)
        filter1On = true; filter2On = true
        osc1DisplayFrames = []; osc2DisplayFrames = []; osc3DisplayFrames = []
        osc1WavetableName = "Init"; osc2WavetableName = "Init"; osc3WavetableName = "Init"
        sampleDisplayFrames = []
        // Overflow defaults
        setOsc1DetunePower(0.65); setOsc1RandomPhase(1); setOsc1SpectralMorphType(0)
        setOsc1SpectralMorphAmount(0.5); setOsc1DistortionType(0); setOsc1DistortionAmount(0.5)
        setOsc2DetunePower(0.65); setOsc2RandomPhase(1); setOsc2SpectralMorphType(0)
        setOsc2SpectralMorphAmount(0.5); setOsc2DistortionType(0); setOsc2DistortionAmount(0.5)
        setOsc3DetunePower(0.65); setOsc3RandomPhase(1); setOsc3SpectralMorphType(0)
        setOsc3SpectralMorphAmount(0.5); setOsc3DistortionType(0); setOsc3DistortionAmount(0.5)
        setSamplePan(0.5); setSampleTranspose(0); setSampleLoop(true)
        setEnv1Hold(0); setEnv2Hold(0)
        for e in 3...6 {
            eng("env_\(e)_attack", 0); eng("env_\(e)_hold", 0)
            eng("env_\(e)_decay", 1); eng("env_\(e)_sustain", 1); eng("env_\(e)_release", 0.5476)
        }
        env3Attack = 0; env3Hold = 0; env3Decay = 1; env3Sustain = 1; env3Release = 0.5476
        env4Attack = 0; env4Hold = 0; env4Decay = 1; env4Sustain = 1; env4Release = 0.5476
        env5Attack = 0; env5Hold = 0; env5Decay = 1; env5Sustain = 1; env5Release = 0.5476
        env6Attack = 0; env6Hold = 0; env6Decay = 1; env6Sustain = 1; env6Release = 0.5476
        for i in 0..<8 {
            setLfoPhase(i, 0); setLfoSync(i, 1); setLfoTarget(i, 0)
            setLfoAmount(i, i == 0 ? 0.3 : 0)
        }
        for i in 0..<4 { setRandomStyle(i, 0); setRandomRate(i, 0.5) }
        setChorusOn(false); setCompressorOn(false); setEqualizerOn(false)
        setFilterFxOn(false); setFlangerOn(false); setPhaserOn(false)
        setPolyphony(16); setPitchBendRange(2)
        loadFromAU()
        currentPatch = "Init"
        refreshSampleDisplay()
        refreshModulations()
    }

    func loadWavetable(from url: URL, oscillatorIndex: Int) {
        au.loadWavetableAsync(from: url, oscillatorIndex: oscillatorIndex) { [weak self] ok in
            if ok { self?.refreshDisplayFrames(oscillatorIndex: oscillatorIndex) }
        }
    }

    func capturePreset(name: String) -> VitalPreset {
        VitalPreset(
            name: name,
            osc1On: osc1On, osc1Level: osc1Level, osc1Pan: osc1Pan,
            osc1Transpose: osc1Transpose, osc1WaveForm: osc1WaveForm,
            osc2On: osc2On, osc2Level: osc2Level, osc2Pan: osc2Pan,
            osc2Transpose: osc2Transpose, osc2WaveForm: osc2WaveForm,
            osc3On: osc3On, osc3Level: osc3Level, osc3Pan: osc3Pan,
            osc3Transpose: osc3Transpose, osc3WaveForm: osc3WaveForm,
            filterCutoff: filterCutoff, filterResonance: filterResonance,
            filterDrive: filterDrive, filterModel: filterModel,
            filter2On: filter2On,
            filter2Cutoff: filter2Cutoff, filter2Resonance: filter2Resonance,
            filter2Drive: filter2Drive, filter2Model: filter2Model,
            osc1FilterRoute: osc1FilterRoute, osc2FilterRoute: osc2FilterRoute,
            osc3FilterRoute: osc3FilterRoute,
            env1Attack: env1Attack, env1Decay: env1Decay,
            env1Sustain: env1Sustain, env1Release: env1Release,
            env2Attack: env2Attack, env2Decay: env2Decay,
            env2Sustain: env2Sustain, env2Release: env2Release,
            lfo1Rate: lfo1Rate, lfo1Amount: lfo1Amount, lfo1Target: lfo1Target,
            reverbMix: reverbMix, delayMix: delayMix,
            chorusMix: chorusMix, distortionMix: distortionMix,
            legato: legato, glide: glide, masterVolume: masterVolume
        )
    }

    func applyPreset(_ p: VitalPreset) {
        currentPatch = p.name
        setOsc1On(p.osc1On); setOsc1Level(p.osc1Level); setOsc1Pan(p.osc1Pan)
        setOsc1Transpose(p.osc1Transpose); setOsc1Waveform(p.osc1WaveForm)
        setOsc2On(p.osc2On); setOsc2Level(p.osc2Level); setOsc2Pan(p.osc2Pan)
        setOsc2Transpose(p.osc2Transpose); setOsc2Waveform(p.osc2WaveForm)
        setOsc3On(p.osc3On); setOsc3Level(p.osc3Level); setOsc3Pan(p.osc3Pan)
        setOsc3Transpose(p.osc3Transpose); setOsc3Waveform(p.osc3WaveForm)
        setFilterCutoff(p.filterCutoff); setFilterResonance(p.filterResonance)
        setFilterDrive(p.filterDrive); setFilterModel(p.filterModel)
        setFilter2On(p.filter2On)
        setFilter2Cutoff(p.filter2Cutoff); setFilter2Resonance(p.filter2Resonance)
        setFilter2Drive(p.filter2Drive); setFilter2Model(p.filter2Model)
        setOsc1FilterRoute(p.osc1FilterRoute)
        setOsc2FilterRoute(p.osc2FilterRoute)
        setOsc3FilterRoute(p.osc3FilterRoute)
        setEnv1Attack(p.env1Attack); setEnv1Decay(p.env1Decay)
        setEnv1Sustain(p.env1Sustain); setEnv1Release(p.env1Release)
        setEnv2Attack(p.env2Attack); setEnv2Decay(p.env2Decay)
        setEnv2Sustain(p.env2Sustain); setEnv2Release(p.env2Release)
        setLfo1Rate(p.lfo1Rate); setLfo1Target(p.lfo1Target); setLfo1Amount(p.lfo1Amount)
        setReverbMix(p.reverbMix); setDelayMix(p.delayMix)
        setChorusMix(p.chorusMix); setDistortionMix(p.distortionMix)
        setLegato(p.legato); setGlide(p.glide); setMasterVolume(p.masterVolume)
    }
}

// MARK: - AU Editor View

private struct IdentifiedOsc: Identifiable {
    let id: Int
    init(_ id: Int) { self.id = id }
}

struct VitalAUView: View {
    @ObservedObject var viewModel: VitalAUViewModel
    @StateObject private var presetManager = PresetManager()
    @State private var showPresetSheet = false
    @State private var currentPresetIndex: Int? = nil
    @State private var selectedTab = 0
    @State private var keyboardHeight: CGFloat = 56
    @GestureState private var kbDrag: CGFloat = 0
    @State private var pitchBend: Float = 0.5
    @State private var modWheel: Float = 0.0
    @State private var editingOscillator: Int? = nil

    private var effectiveKbHeight: CGFloat { max(40, min(110, keyboardHeight - kbDrag)) }
    private let tabs = ["VOICE", "EFFECTS", "MATRIX", "ADVANCED"]

    private var allPresets: [AUNavEntry] {
        presetManager.presets.map { AUNavEntry.custom($0) } +
        presetManager.importedPresets.map { AUNavEntry.imported($0) }
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
        viewModel.allNotesOff()
        switch all[idx] {
        case .custom(let p):   viewModel.applyPreset(p)
        case .imported(let p): viewModel.loadVitalPreset(from: p.url)
        }
    }

    private func randomLibraryPreset() {
        let all = allPresets
        guard !all.isEmpty else { return }
        let idx = Int.random(in: 0..<all.count)
        currentPresetIndex = idx
        viewModel.allNotesOff()
        switch all[idx] {
        case .custom(let p):   viewModel.applyPreset(p)
        case .imported(let p): viewModel.loadVitalPreset(from: p.url)
        }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                headerBar
                mainBody(width: geo.size.width)
                keyboardHandle
                AUKeyboardView(
                    onNoteOn:     { note, vel in viewModel.noteOn(note: note, velocity: vel) },
                    onNoteOff:    { note in viewModel.noteOff(note) },
                    onAllNotesOff:{ viewModel.allNotesOff() }
                )
                .frame(height: effectiveKbHeight)
            }
        }
        .background(VitalColors.background.ignoresSafeArea())
        .onAppear {
            viewModel.refreshSampleDisplay()
            viewModel.loadEffectChainOrder()
        }
        .sheet(isPresented: $showPresetSheet) {
            PresetSheet(manager: presetManager, viewModel: viewModel)
        }
        .fullScreenCover(item: Binding(
            get: { editingOscillator.map { IdentifiedOsc($0) } },
            set: { editingOscillator = $0?.id }
        )) { item in
            AUWavetableEditorView(viewModel: viewModel, oscillatorIndex: item.id) {
                editingOscillator = nil
            }
        }
    }

    // MARK: Header (44pt)

    private var headerBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Rectangle().fill(VitalColors.accent).frame(width: 3, height: 18)
                VStack(alignment: .leading, spacing: 0) {
                    Text("VITAL")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: VitalColors.accent.opacity(0.45), radius: 4)
                    Text("AUv3 · Derbin Hamler")
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

                Text(viewModel.currentPatch)
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

            Button { viewModel.resetToInit(); currentPresetIndex = nil } label: {
                Text("INIT")
                    .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    .foregroundColor(VitalColors.labelText)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(VitalColors.body).cornerRadius(4)
            }.buttonStyle(.plain).padding(.leading, 4)

            HStack(spacing: 3) {
                Text("VOL").font(.system(size: 8)).foregroundColor(VitalColors.labelText)
                VitalKnob(label: "", value: Binding(
                    get: { viewModel.masterVolume },
                    set: { viewModel.setMasterVolume($0) }
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
                            AUEffectsInterfaceView(engine: viewModel)
                        } else if selectedTab == 2 {
                            AUMatrixInterfaceView(engine: viewModel)
                        } else {
                            tabContent
                        }
                        ModulationSidePanel(engine: viewModel)
                    }
                    .padding(5)
                }
            } else {
                Group {
                    if selectedTab == 1 {
                        AUEffectsInterfaceView(engine: viewModel)
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if selectedTab == 2 {
                        AUMatrixInterfaceView(engine: viewModel)
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
                    ModulationSidePanel(engine: viewModel)
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
                        get: { (0..<viewModel.macro.count).contains(i) ? viewModel.macro[i] : 0 },
                        set: { viewModel.setMacro(i, $0) }
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
                .onChange(of: pitchBend) { viewModel.sendPitchBend($0) }

            WheelControl(label: "MOD", value: $modWheel,
                         springReturn: false, color: VitalColors.modTeal)
                .frame(height: 90)
                .onChange(of: modWheel) { viewModel.sendModWheel($0) }
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
        case 2: MatrixTab(engine: viewModel)
        default: AdvancedTab(engine: viewModel)
        }
    }

    // MARK: VOICE

    private var voiceTab: some View {
        VStack(spacing: 5) {
            oscSection(1)
            oscSection(2)
            oscSection(3)
            SampleSection(engine: viewModel)
            HStack(alignment: .top, spacing: 5) {
                FilterSection(
                    filterNumber: 1, accentColor: VitalColors.warmOrange,
                    isOn: Binding(get: { viewModel.filter1On }, set: { viewModel.setFilter1On($0) }),
                    cutoff: Binding(get: { (viewModel.filterCutoff - 8) / 128 },
                                    set: { viewModel.setFilterCutoff($0 * 128 + 8) }),
                    resonance: Binding(get: { viewModel.filterResonance }, set: { viewModel.setFilterResonance($0) }),
                    drive: Binding(get: { viewModel.filterDrive }, set: { viewModel.setFilterDrive($0) }),
                    model: Binding(get: { viewModel.filterModel }, set: { viewModel.setFilterModel($0) }),
                    blend: Binding(get: { viewModel.filter1Blend }, set: { viewModel.setFilter1Blend($0) })
                )
                FilterSection(
                    filterNumber: 2, accentColor: VitalColors.warmOrange,
                    isOn: Binding(get: { viewModel.filter2On }, set: { viewModel.setFilter2On($0) }),
                    cutoff: Binding(get: { (viewModel.filter2Cutoff - 8) / 128 },
                                    set: { viewModel.setFilter2Cutoff($0 * 128 + 8) }),
                    resonance: Binding(get: { viewModel.filter2Resonance }, set: { viewModel.setFilter2Resonance($0) }),
                    drive: Binding(get: { viewModel.filter2Drive }, set: { viewModel.setFilter2Drive($0) }),
                    model: Binding(get: { viewModel.filter2Model }, set: { viewModel.setFilter2Model($0) }),
                    blend: Binding(get: { viewModel.filter2Blend }, set: { viewModel.setFilter2Blend($0) })
                )
            }
        }
    }

    private func oscSection(_ n: Int) -> some View {
        switch n {
        case 2:
            return AnyView(OscillatorSection(
                title: "OSC 2",
                isOn: Binding(get: { viewModel.osc2On }, set: { viewModel.setOsc2On($0) }),
                waveform: Binding(get: { viewModel.osc2WaveForm }, set: { viewModel.setOsc2Waveform($0) }),
                waveFrame: Binding(get: { viewModel.osc2WaveFrame }, set: { viewModel.setOsc2WaveFrame($0) }),
                level: Binding(get: { viewModel.osc2Level }, set: { viewModel.setOsc2Level($0) }),
                pan: Binding(get: { viewModel.osc2Pan }, set: { viewModel.setOsc2Pan($0) }),
                transpose: Binding(get: { (viewModel.osc2Transpose + 48) / 96 },
                                   set: { viewModel.setOsc2Transpose($0 * 96 - 48) }),
                destination: Binding(get: { viewModel.osc2Destination }, set: { viewModel.setOsc2Destination($0) }),
                unisonVoices: Binding(get: { viewModel.osc2UnisonVoices }, set: { viewModel.setOsc2UnisonVoices($0) }),
                unisonDetune: Binding(get: { viewModel.osc2UnisonDetune }, set: { viewModel.setOsc2UnisonDetune($0) }),
                phase: Binding(get: { viewModel.osc2Phase }, set: { viewModel.setOsc2Phase($0) }),
                spectralMorphType: Binding(get: { viewModel.osc2SpectralMorphType }, set: { viewModel.setOsc2SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { viewModel.osc2SpectralMorphAmount }, set: { viewModel.setOsc2SpectralMorphAmount($0) }),
                distortionType: Binding(get: { viewModel.osc2DistortionType }, set: { viewModel.setOsc2DistortionType($0) }),
                distortionAmount: Binding(get: { viewModel.osc2DistortionAmount }, set: { viewModel.setOsc2DistortionAmount($0) }),
                displayFrames: viewModel.osc2DisplayFrames,
                wavetableName: viewModel.osc2WavetableName,
                onWavetableLoaded: { viewModel.loadWavetable(from: $0, oscillatorIndex: 1) },
                onTuneChanged: { viewModel.setEngineParameter("osc_2_tune", $0 * 2 - 1) },
                onEditWavetable: { editingOscillator = 1 }
            ))
        case 3:
            return AnyView(OscillatorSection(
                title: "OSC 3",
                isOn: Binding(get: { viewModel.osc3On }, set: { viewModel.setOsc3On($0) }),
                waveform: Binding(get: { viewModel.osc3WaveForm }, set: { viewModel.setOsc3Waveform($0) }),
                waveFrame: Binding(get: { viewModel.osc3WaveFrame }, set: { viewModel.setOsc3WaveFrame($0) }),
                level: Binding(get: { viewModel.osc3Level }, set: { viewModel.setOsc3Level($0) }),
                pan: Binding(get: { viewModel.osc3Pan }, set: { viewModel.setOsc3Pan($0) }),
                transpose: Binding(get: { (viewModel.osc3Transpose + 48) / 96 },
                                   set: { viewModel.setOsc3Transpose($0 * 96 - 48) }),
                destination: Binding(get: { viewModel.osc3Destination }, set: { viewModel.setOsc3Destination($0) }),
                unisonVoices: Binding(get: { viewModel.osc3UnisonVoices }, set: { viewModel.setOsc3UnisonVoices($0) }),
                unisonDetune: Binding(get: { viewModel.osc3UnisonDetune }, set: { viewModel.setOsc3UnisonDetune($0) }),
                phase: Binding(get: { viewModel.osc3Phase }, set: { viewModel.setOsc3Phase($0) }),
                spectralMorphType: Binding(get: { viewModel.osc3SpectralMorphType }, set: { viewModel.setOsc3SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { viewModel.osc3SpectralMorphAmount }, set: { viewModel.setOsc3SpectralMorphAmount($0) }),
                distortionType: Binding(get: { viewModel.osc3DistortionType }, set: { viewModel.setOsc3DistortionType($0) }),
                distortionAmount: Binding(get: { viewModel.osc3DistortionAmount }, set: { viewModel.setOsc3DistortionAmount($0) }),
                displayFrames: viewModel.osc3DisplayFrames,
                wavetableName: viewModel.osc3WavetableName,
                onWavetableLoaded: { viewModel.loadWavetable(from: $0, oscillatorIndex: 2) },
                onTuneChanged: { viewModel.setEngineParameter("osc_3_tune", $0 * 2 - 1) },
                onEditWavetable: { editingOscillator = 2 }
            ))
        default:
            return AnyView(OscillatorSection(
                title: "OSC 1",
                isOn: Binding(get: { viewModel.osc1On }, set: { viewModel.setOsc1On($0) }),
                waveform: Binding(get: { viewModel.osc1WaveForm }, set: { viewModel.setOsc1Waveform($0) }),
                waveFrame: Binding(get: { viewModel.osc1WaveFrame }, set: { viewModel.setOsc1WaveFrame($0) }),
                level: Binding(get: { viewModel.osc1Level }, set: { viewModel.setOsc1Level($0) }),
                pan: Binding(get: { viewModel.osc1Pan }, set: { viewModel.setOsc1Pan($0) }),
                transpose: Binding(get: { (viewModel.osc1Transpose + 48) / 96 },
                                   set: { viewModel.setOsc1Transpose($0 * 96 - 48) }),
                destination: Binding(get: { viewModel.osc1Destination }, set: { viewModel.setOsc1Destination($0) }),
                unisonVoices: Binding(get: { viewModel.osc1UnisonVoices }, set: { viewModel.setOsc1UnisonVoices($0) }),
                unisonDetune: Binding(get: { viewModel.osc1UnisonDetune }, set: { viewModel.setOsc1UnisonDetune($0) }),
                phase: Binding(get: { viewModel.osc1Phase }, set: { viewModel.setOsc1Phase($0) }),
                spectralMorphType: Binding(get: { viewModel.osc1SpectralMorphType }, set: { viewModel.setOsc1SpectralMorphType($0) }),
                spectralMorphAmount: Binding(get: { viewModel.osc1SpectralMorphAmount }, set: { viewModel.setOsc1SpectralMorphAmount($0) }),
                distortionType: Binding(get: { viewModel.osc1DistortionType }, set: { viewModel.setOsc1DistortionType($0) }),
                distortionAmount: Binding(get: { viewModel.osc1DistortionAmount }, set: { viewModel.setOsc1DistortionAmount($0) }),
                displayFrames: viewModel.osc1DisplayFrames,
                wavetableName: viewModel.osc1WavetableName,
                onWavetableLoaded: { viewModel.loadWavetable(from: $0, oscillatorIndex: 0) },
                onTuneChanged: { viewModel.setEngineParameter("osc_1_tune", $0 * 2 - 1) },
                onEditWavetable: { editingOscillator = 0 }
            ))
        }
    }

    // MARK: EFFECTS

    private var effectsTab: some View {
        AUEffectsInterfaceView(engine: viewModel)
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

