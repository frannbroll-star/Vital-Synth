//
//  VitalAUAudioUnit.swift
//  VitalAU
//
//  AUv3 Audio Unit wrapping the Vital DSP engine.
//  Hybrid parameter model: AUParameterTree for host-automatable params,
//  plus setEngineParameter/getEngineParameter for overflow UI params.
//
//  Address map (legacy 0–46 kept for host state compatibility):
//    0–4    OSC 1 on/level/pan/transpose/waveform
//    5–9    OSC 2 …
//    10–14  OSC 3 …
//    15–18  Filter 1 cutoff/res/drive/model (model 0–7)
//    19–22  ENV 1 ADSR
//    23–26  ENV 2 ADSR
//    27     LFO 1 rate (normalized 0–1 → Vital −7…9)
//    28–31  Reverb/Delay/Chorus/Distortion mix
//    32     Master volume
//    33–35  OSC 1–3 wave frame
//    36–39  Filter 2 cutoff/res/drive/model
//    40–42  OSC 1–3 filter route (0=F1,1=F2,2=Both)
//    43–44  LFO 1 amount / target index
//    45–46  Legato / Glide
//    47–50  Macro 1–4
//    51–57  LFO 2–8 rate
//    58–60  OSC 1–3 unison voices (1–16)
//    61–63  OSC 1–3 unison detune (0–1 → ×10)
//    64–66  OSC 1–3 phase
//    67–68  Sample on / level
//    69–70  Filter 1–2 blend (0–1 → ×2)
//

import AudioToolbox
import AVFoundation

private let lfoTargets = [
    "filter_1_cutoff", "filter_2_cutoff",
    "osc_1_level", "osc_2_level", "osc_3_level",
    "osc_1_wave_frame", "osc_2_wave_frame", "osc_3_wave_frame",
    "volume", "reverb_dry_wet", "delay_dry_wet"
]

public class VitalAUAudioUnit: AUAudioUnit {

    // MARK: - Private state

    private var wrapper: VitalEngineWrapper?
    private var outputBus: AUAudioUnitBus!
    private var outputBuses: AUAudioUnitBusArray!
    private var paramValues: [AUParameterAddress: AUValue] = [:]
    private let loadQueue = DispatchQueue(label: "com.vitalsynth.au.wavetableLoad", qos: .userInitiated)
    private lazy var _renderBlock: AUInternalRenderBlock = self.makeRenderBlock()

    // MARK: - Lifecycle

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        outputBus   = try AUAudioUnitBus(format: format)
        outputBuses = AUAudioUnitBusArray(audioUnit: self,
                                          busType: .output,
                                          busses: [outputBus])
        self.parameterTree = makeParameterTree()
    }

    public override var outputBusses: AUAudioUnitBusArray { outputBuses }

    // MARK: - Rendering

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        let sr = outputBus.format.sampleRate
        let w  = VitalEngineWrapper(sampleRate: sr)
        for (addr, val) in paramValues {
            applyParam(addr: addr, value: val, to: w)
        }
        // Pre-connect all 8 LFOs to every target at amount 0, then activate selections.
        for lfoIdx in 1...8 {
            let source = "lfo_\(lfoIdx)"
            for t in lfoTargets {
                _ = w.connectModulation(source, to: t, amount: 0.0)
            }
        }
        let targetIdx = Int((paramValues[44] ?? 0).rounded())
        let targetParam = lfoTargets[min(targetIdx, lfoTargets.count - 1)]
        let lfoAmt = paramValues[43] ?? 0.3
        w.setModulationAmount(lfoAmt, source: "lfo_1", destination: targetParam)
        _ = w.connectModulation("mod_wheel", to: "filter_1_cutoff", amount: 0.5)
        wrapper = w
    }

    public override func deallocateRenderResources() {
        wrapper = nil
        super.deallocateRenderResources()
    }

    private func makeRenderBlock() -> AUInternalRenderBlock {
        return { [weak self] _, _, frameCount, _, outputData, realtimeEventListHead, _ in
            guard let w = self?.wrapper else { return noErr }

            let ablp = UnsafeMutableAudioBufferListPointer(outputData)
            let n    = Int(frameCount)
            guard ablp.count >= 2,
                  let l = ablp[0].mData?.assumingMemoryBound(to: Float.self),
                  let r = ablp[1].mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            var event = realtimeEventListHead?.pointee
            while event != nil {
                if event!.head.eventType == AURenderEventType.MIDI {
                    let m = event!.MIDI
                    let status  = m.data.0 & 0xF0
                    let channel = Int32((m.data.0 & 0x0F)) + 1
                    switch status {
                    case 0x90 where m.data.2 > 0:
                        w.note(on: Int32(m.data.1), velocity: Float(m.data.2) / 127.0, channel: channel)
                    case 0x80, 0x90:
                        w.noteOff(Int32(m.data.1), lift: 0, channel: channel)
                    case 0xE0:
                        let raw        = Int32(m.data.1) | (Int32(m.data.2) << 7)
                        let normalized = (Float(raw) / 8192.0) - 1.0
                        w.setPitchWheel(normalized, channel: channel)
                    case 0xB0 where m.data.1 == 1:
                        w.setModWheel(Float(m.data.2) / 127.0, channel: channel)
                    default: break
                    }
                }
                if let nextPtr = event?.head.next { event = nextPtr.pointee }
                else { event = nil }
            }

            w.render(intoLeft: l, right: r, numFrames: Int32(n))
            return noErr
        }
    }

    public override var internalRenderBlock: AUInternalRenderBlock { _renderBlock }

    // MARK: - Side-channel engine params (not in AUParameterTree)

    func setEngineParameter(_ name: String, value: Float) {
        wrapper?.setParameter(name, value: value)
    }

    func getEngineParameter(_ name: String) -> Float {
        wrapper?.getParameter(name) ?? 0
    }

    // MARK: - Real-time MIDI from on-screen keyboard

    func noteOn(note: Int32, velocity: Float) {
        wrapper?.note(on: note, velocity: velocity, channel: 1)
    }

    func noteOff(_ note: Int32) {
        wrapper?.noteOff(note, lift: 0, channel: 1)
    }

    func allNotesOff() {
        wrapper?.allNotesOff()
    }

    func sendPitchBend(_ value: Float) {
        wrapper?.setPitchWheel((value - 0.5) * 2.0, channel: 1)
    }

    func sendModWheel(_ value: Float) {
        wrapper?.setModWheel(value, channel: 1)
    }

    func setFilterOn(_ filterNum: Int, _ on: Bool) {
        wrapper?.setParameter("filter_\(filterNum)_on", value: on ? 1 : 0)
    }

    func connectModulation(_ source: String, to destination: String, amount: Float) -> Bool {
        wrapper?.connectModulation(source, to: destination, amount: amount) ?? false
    }

    func disconnectModulation(_ source: String, from destination: String) {
        wrapper?.disconnectModulation(source, from: destination)
    }

    func setModulationAmount(_ amount: Float, source: String, destination: String) {
        wrapper?.setModulationAmount(amount, source: source, destination: destination)
    }

    func setModulationBipolar(_ bipolar: Bool, source: String, destination: String) {
        wrapper?.setModulationBipolar(bipolar, source: source, destination: destination)
    }

    func setModulationStereo(_ stereo: Bool, source: String, destination: String) {
        wrapper?.setModulationStereo(stereo, source: source, destination: destination)
    }

    func setModulationBypass(_ bypass: Bool, source: String, destination: String) {
        wrapper?.setModulationBypass(bypass, source: source, destination: destination)
    }

    func setModulationPower(_ power: Float, source: String, destination: String) {
        wrapper?.setModulationPower(power, source: source, destination: destination)
    }

    func modulationSourceNames() -> [String] {
        (wrapper?.modulationSourceNames() as? [String]) ?? []
    }

    func modulationDestinationNames() -> [String] {
        (wrapper?.modulationDestinationNames() as? [String]) ?? []
    }

    func listModulations() -> [[String: Any]] {
        guard let list = wrapper?.listModulations() else { return [] }
        return list.compactMap { $0 as? [String: Any] }
    }

    // MARK: - Init patch

    func resetToInit() {
        allNotesOff()
        wrapper?.loadDefaultWavetables()
        let defaults: [(AUParameterAddress, Float)] = [
            (0,1),(1,1),(2,0.5),(3,0),(4,0),
            (5,0),(6,0),(7,0.5),(8,0),(9,0),
            (10,0),(11,0),(12,0.5),(13,0),(14,0),
            (15,100),(16,0.5),(17,0),(18,0),
            (19,0.003),(20,0.25),(21,0.70),(22,0.40),
            (23,0.003),(24,0.40),(25,0.0),(26,0.30),
            (27,0.25),
            (28,0),(29,0),(30,0),(31,0),
            (32,0.8601),
            (33,0),(34,0),(35,0),
            (36,100),(37,0.5),(38,0),(39,0),
            (40,0),(41,0),(42,0),
            (43,0.3),(44,0),
            (45,0),(46,0),
            (47,0),(48,0),(49,0),(50,0),
            (51,0.25),(52,0.25),(53,0.25),(54,0.25),(55,0.25),(56,0.25),(57,0.25),
            (58,1),(59,1),(60,1),
            (61,0.4472),(62,0.4472),(63,0.4472),
            (64,0.5),(65,0.5),(66,0.5),
            (67,0),(68,0.7071),
            (69,0),(70,0),
        ]
        for (addr, val) in defaults {
            paramValues[addr] = val
            if let w = wrapper { applyParam(addr: addr, value: val, to: w) }
            parameterTree?.parameter(withAddress: addr)?.setValue(val, originator: nil)
        }
    }

    // MARK: - Wavetable display frames

    func getDisplayFrames(oscillatorIndex: Int) -> [[Float]] {
        let rawFrames = wrapper?.getDisplayFrames(Int32(oscillatorIndex)) ?? []
        return rawFrames.map { data in
            data.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self))
            }
        }
    }

    func sampleDisplayFrames() -> [Float] {
        guard let data = wrapper?.getSampleDisplayBuffer() else { return [] }
        return data.withUnsafeBytes { ptr in
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
        let addr: AUParameterAddress
        switch oscillatorIndex {
        case 0: addr = 33
        case 1: addr = 34
        case 2: addr = 35
        default: return
        }
        paramValues[addr] = v
        if let w = wrapper { applyParam(addr: addr, value: v, to: w) }
        parameterTree?.parameter(withAddress: addr)?.setValue(v, originator: nil)
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
        wrapper?.commitWavetable(Int32(oscillatorIndex)) ?? false
    }

    @discardableResult
    func expandWavetable(toFrames count: Int, oscillatorIndex: Int, interpolate: Bool = true) -> Bool {
        wrapper?.expandWavetable(toFrames: Int32(count),
                                 oscillator: Int32(oscillatorIndex),
                                 interpolate: interpolate) ?? false
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
        wrapper?.normalizeFrame(Int32(frame),
                                oscillator: Int32(oscillatorIndex),
                                removeDC: removeDC) ?? false
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

    func displayFrames(forOscillator index: Int) -> [[Float]] {
        getDisplayFrames(oscillatorIndex: index)
    }

    // MARK: - Wavetable loading

    func loadWavetableAsync(from url: URL, oscillatorIndex: Int, completion: @escaping (Bool) -> Void) {
        guard let w = wrapper else { completion(false); return }
        let idx = oscillatorIndex
        let ext = url.pathExtension.lowercased()
        let fileName = url.deletingPathExtension().lastPathComponent

        switch ext {
        case "wav", "aif", "aiff", "flac", "caf", "mp3", "m4a":
            guard let audioFile = try? AVAudioFile(forReading: url) else { completion(false); return }
            let sr = audioFile.fileFormat.sampleRate
            let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: sr, channels: 1, interleaved: false)!
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard frameCount > 0,
                  let buf = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: frameCount),
                  (try? audioFile.read(into: buf)) != nil,
                  let ptr = buf.floatChannelData else { completion(false); return }
            let samples = [Float](UnsafeBufferPointer(start: ptr[0], count: Int(buf.frameLength)))
            let sampleRate = Int32(sr)
            loadQueue.async {
                let ok = samples.withUnsafeBufferPointer {
                    w.loadWavetable(fromSamples: $0.baseAddress!,
                                    sampleCount: Int32(samples.count),
                                    sampleRate: sampleRate,
                                    oscillatorIndex: Int32(idx))
                }
                if ok { w.setWavetableName(fileName, oscillatorIndex: Int32(idx)) }
                DispatchQueue.main.async { completion(ok) }
            }

        default:
            guard let data = try? Data(contentsOf: url) else { completion(false); return }
            loadQueue.async {
                let ok = Self.processJSON(data: data, wrapper: w, oscillatorIndex: idx)
                if ok {
                    let engineName = w.wavetableName(forOscillator: Int32(idx)) ?? ""
                    if engineName.isEmpty || engineName == "Wavetable" {
                        w.setWavetableName(fileName, oscillatorIndex: Int32(idx))
                    }
                }
                DispatchQueue.main.async { completion(ok) }
            }
        }
    }

    func wavetableName(forOscillator index: Int) -> String {
        let name = wrapper?.wavetableName(forOscillator: Int32(index)) ?? ""
        return name.isEmpty ? "Init" : name
    }

    // MARK: - Full .vital preset loading

    func loadVitalPreset(from url: URL, completion: @escaping (String) -> Void) {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let settings = json["settings"] as? [String: Any] else { return }

        let name = (json["name"] as? String) ?? url.deletingPathExtension().lastPathComponent
        allNotesOff()

        if let w = wrapper {
            for (key, value) in settings where key != "wavetables" {
                if let d = value as? Double { w.setParameter(key, value: Float(d)) }
            }
        }

        let mapped = auValues(from: settings)
        for (addr, val) in mapped {
            paramValues[addr] = val
            parameterTree?.parameter(withAddress: addr)?.setValue(val, originator: nil)
        }

        let wavetables = settings["wavetables"] as? [[String: Any]] ?? []
        guard !wavetables.isEmpty, let w = wrapper else {
            DispatchQueue.main.async { completion(name) }
            return
        }
        loadQueue.async {
            for (idx, wtDict) in wavetables.prefix(3).enumerated() {
                guard let wtData = try? JSONSerialization.data(withJSONObject: wtDict) else { continue }
                _ = w.loadWavetable(fromJSON: wtData, oscillatorIndex: Int32(idx))
            }
            DispatchQueue.main.async { completion(name) }
        }
    }

    private func auValues(from s: [String: Any]) -> [AUParameterAddress: Float] {
        func f(_ k: String, _ def: Float = 0) -> Float { Float((s[k] as? Double) ?? Double(def)) }
        func b(_ k: String) -> Bool { f(k) >= 0.5 }
        /// Vital names are `filter_N_oscM_input` (no underscore between osc and index).
        func route(osc: Int) -> Float {
            let toF1 = f("filter_1_osc\(osc)_input") >= 0.5
            let toF2 = f("filter_2_osc\(osc)_input") >= 0.5
            if toF1 && toF2 { return 2 }; return toF2 ? 1 : 0
        }
        func normLfo(_ k: String, _ defFreq: Float = 5) -> Float {
            min(1, max(0, (f(k, defFreq) + 7) / 16))
        }
        var r: [AUParameterAddress: Float] = [:]
        r[0]  = b("osc_1_on") ? 1 : 0;  r[1] = f("osc_1_level", 1)
        r[2]  = (f("osc_1_pan") + 1) / 2; r[3] = f("osc_1_transpose")
        r[33] = f("osc_1_wave_frame") / 255.0
        r[5]  = b("osc_2_on") ? 1 : 0;  r[6] = f("osc_2_level")
        r[7]  = (f("osc_2_pan") + 1) / 2; r[8] = f("osc_2_transpose")
        r[34] = f("osc_2_wave_frame") / 255.0
        r[10] = b("osc_3_on") ? 1 : 0;  r[11] = f("osc_3_level")
        r[12] = (f("osc_3_pan") + 1) / 2; r[13] = f("osc_3_transpose")
        r[35] = f("osc_3_wave_frame") / 255.0
        r[15] = f("filter_1_cutoff", 100); r[16] = f("filter_1_resonance", 0.5)
        r[17] = f("filter_1_drive") / 20.0; r[18] = Float(Int(f("filter_1_model").rounded()))
        r[36] = f("filter_2_cutoff", 100); r[37] = f("filter_2_resonance", 0.5)
        r[38] = f("filter_2_drive") / 20.0; r[39] = Float(Int(f("filter_2_model").rounded()))
        r[40] = route(osc: 1); r[41] = route(osc: 2); r[42] = route(osc: 3)
        r[19] = f("env_1_attack", 0.003); r[20] = f("env_1_decay", 0.25)
        r[21] = f("env_1_sustain", 0.7);  r[22] = f("env_1_release", 0.4)
        r[23] = f("env_2_attack", 0.003); r[24] = f("env_2_decay", 0.4)
        r[25] = f("env_2_sustain");        r[26] = f("env_2_release", 0.3)
        r[27] = normLfo("lfo_1_frequency")
        r[28] = f("reverb_dry_wet"); r[29] = f("delay_dry_wet")
        r[30] = f("chorus_dry_wet"); r[31] = f("distortion_mix")
        let rawVol = f("volume", Float(0.8601 * 0.8601 * 7399.44))
        r[32] = min(1, max(0, sqrt(rawVol / 7399.44)))
        let poly = Int(f("polyphony", 16).rounded())
        r[45] = (b("legato") || poly == 1) ? 1 : 0
        r[46] = min(1, max(0, (f("portamento_time", -10) + 10) / 14))
        r[47] = f("macro_control_1"); r[48] = f("macro_control_2")
        r[49] = f("macro_control_3"); r[50] = f("macro_control_4")
        for i in 2...8 { r[AUParameterAddress(49 + i)] = normLfo("lfo_\(i)_frequency") } // 51…57
        r[58] = f("osc_1_unison_voices", 1); r[59] = f("osc_2_unison_voices", 1); r[60] = f("osc_3_unison_voices", 1)
        r[61] = f("osc_1_unison_detune", 4.472) / 10; r[62] = f("osc_2_unison_detune", 4.472) / 10
        r[63] = f("osc_3_unison_detune", 4.472) / 10
        r[64] = f("osc_1_phase", 0.5); r[65] = f("osc_2_phase", 0.5); r[66] = f("osc_3_phase", 0.5)
        r[67] = b("sample_on") ? 1 : 0; r[68] = f("sample_level", 0.7071)
        r[69] = f("filter_1_blend") / 2; r[70] = f("filter_2_blend") / 2
        return r
    }

    private static func processJSON(data: Data, wrapper: VitalEngineWrapper, oscillatorIndex: Int) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }

        if let wavetables = json["wavetables"] as? [[String: Any]], !wavetables.isEmpty {
            let idx = min(oscillatorIndex, wavetables.count - 1)
            guard let wtData = try? JSONSerialization.data(withJSONObject: wavetables[idx]) else { return false }
            return wrapper.loadWavetable(fromJSON: wtData, oscillatorIndex: Int32(oscillatorIndex))
        }

        if json["groups"] != nil {
            return wrapper.loadWavetable(fromJSON: data, oscillatorIndex: Int32(oscillatorIndex))
        }

        return false
    }

    // MARK: - Parameters

    private func makeParameterTree() -> AUParameterTree {
        func p(_ addr: AUParameterAddress, _ identifier: String, _ name: String,
               _ unit: AudioUnitParameterUnit, _ min: Float, _ max: Float, _ def: Float)
            -> AUParameter
        {
            let param = AUParameterTree.createParameter(
                withIdentifier: identifier, name: name, address: addr,
                min: AUValue(min), max: AUValue(max), unit: unit,
                unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable],
                valueStrings: nil, dependentParameters: nil)
            param.value = AUValue(def)
            paramValues[addr] = def
            return param
        }

        var params: [AUParameter] = [
            p(0,  "osc1On",        "OSC 1 On",         .boolean,       0, 1,    1.0),
            p(1,  "osc1Level",     "OSC 1 Level",       .linearGain,    0, 1,    1.0),
            p(2,  "osc1Pan",       "OSC 1 Pan",         .pan,           0, 1,    0.5),
            p(3,  "osc1Transpose", "OSC 1 Transpose",   .relativeSemiTones, -48, 48, 0),
            p(4,  "osc1WaveForm",  "OSC 1 Waveform",    .indexed,       0, 3,    0.0),
            p(5,  "osc2On",        "OSC 2 On",         .boolean,       0, 1,    0.0),
            p(6,  "osc2Level",     "OSC 2 Level",       .linearGain,    0, 1,    0.0),
            p(7,  "osc2Pan",       "OSC 2 Pan",         .pan,           0, 1,    0.5),
            p(8,  "osc2Transpose", "OSC 2 Transpose",   .relativeSemiTones, -48, 48, 0),
            p(9,  "osc2WaveForm",  "OSC 2 Waveform",    .indexed,       0, 3,    0.0),
            p(10, "osc3On",        "OSC 3 On",         .boolean,       0, 1,    0.0),
            p(11, "osc3Level",     "OSC 3 Level",       .linearGain,    0, 1,    0.0),
            p(12, "osc3Pan",       "OSC 3 Pan",         .pan,           0, 1,    0.5),
            p(13, "osc3Transpose", "OSC 3 Transpose",   .relativeSemiTones, -48, 48, 0),
            p(14, "osc3WaveForm",  "OSC 3 Waveform",    .indexed,       0, 3,    0.0),
            p(15, "filterCutoff",   "Filter Cutoff",    .midiNoteNumber, 8, 136, 100.0),
            p(16, "filterRes",      "Filter Resonance", .percent,       0, 1,    0.5),
            p(17, "filterDrive",    "Filter Drive",     .percent,       0, 1,    0.0),
            p(18, "filterModel",    "Filter Model",     .indexed,       0, 7,    0.0),
            p(19, "env1Attack",  "ENV1 Attack",  .seconds,    0, 4, 0.003),
            p(20, "env1Decay",   "ENV1 Decay",   .seconds,    0, 4, 0.25),
            p(21, "env1Sustain", "ENV1 Sustain", .linearGain, 0, 1, 0.70),
            p(22, "env1Release", "ENV1 Release", .seconds,    0, 8, 0.40),
            p(23, "env2Attack",  "ENV2 Attack",  .seconds,    0, 4, 0.003),
            p(24, "env2Decay",   "ENV2 Decay",   .seconds,    0, 4, 0.40),
            p(25, "env2Sustain", "ENV2 Sustain", .linearGain, 0, 1, 0.0),
            p(26, "env2Release", "ENV2 Release", .seconds,    0, 8, 0.30),
            p(27, "lfo1Rate",    "LFO 1 Rate",   .generic,    0, 1, 0.25),
            p(28, "reverbMix",      "Reverb Mix",      .percent, 0, 1, 0.0),
            p(29, "delayMix",       "Delay Mix",       .percent, 0, 1, 0.0),
            p(30, "chorusMix",      "Chorus Mix",      .percent, 0, 1, 0.0),
            p(31, "distortionMix",  "Distortion Mix",  .percent, 0, 1, 0.0),
            p(32, "masterVolume",   "Master Volume",   .linearGain, 0, 1, 0.8601),
            p(33, "osc1WaveFrame",  "OSC 1 Wave Frame", .percent, 0, 1, 0.0),
            p(34, "osc2WaveFrame",  "OSC 2 Wave Frame", .percent, 0, 1, 0.0),
            p(35, "osc3WaveFrame",  "OSC 3 Wave Frame", .percent, 0, 1, 0.0),
            p(36, "filter2Cutoff",  "Filter 2 Cutoff",     .midiNoteNumber, 8, 136, 100.0),
            p(37, "filter2Res",     "Filter 2 Resonance",  .percent,        0, 1,   0.5),
            p(38, "filter2Drive",   "Filter 2 Drive",      .percent,        0, 1,   0.0),
            p(39, "filter2Model",   "Filter 2 Model",      .indexed,        0, 7,   0.0),
            p(40, "osc1FilterRoute", "OSC 1 Filter Route", .indexed, 0, 2, 0.0),
            p(41, "osc2FilterRoute", "OSC 2 Filter Route", .indexed, 0, 2, 0.0),
            p(42, "osc3FilterRoute", "OSC 3 Filter Route", .indexed, 0, 2, 0.0),
            p(43, "lfo1Amount", "LFO 1 Amount", .percent, 0, 1, 0.3),
            p(44, "lfo1Target", "LFO 1 Target", .indexed, 0, Float(lfoTargets.count - 1), 0.0),
            p(45, "legato",     "Legato",        .boolean, 0, 1, 0.0),
            p(46, "glide",      "Glide",         .percent, 0, 1, 0.0),
            p(47, "macro1", "Macro 1", .percent, 0, 1, 0),
            p(48, "macro2", "Macro 2", .percent, 0, 1, 0),
            p(49, "macro3", "Macro 3", .percent, 0, 1, 0),
            p(50, "macro4", "Macro 4", .percent, 0, 1, 0),
        ]

        for i in 2...8 {
            params.append(p(AUParameterAddress(49 + i), "lfo\(i)Rate", "LFO \(i) Rate", .generic, 0, 1, 0.25))
        }
        params += [
            p(58, "osc1UnisonVoices", "OSC 1 Unison", .indexed, 1, 16, 1),
            p(59, "osc2UnisonVoices", "OSC 2 Unison", .indexed, 1, 16, 1),
            p(60, "osc3UnisonVoices", "OSC 3 Unison", .indexed, 1, 16, 1),
            p(61, "osc1UnisonDetune", "OSC 1 Detune", .percent, 0, 1, 0.4472),
            p(62, "osc2UnisonDetune", "OSC 2 Detune", .percent, 0, 1, 0.4472),
            p(63, "osc3UnisonDetune", "OSC 3 Detune", .percent, 0, 1, 0.4472),
            p(64, "osc1Phase", "OSC 1 Phase", .percent, 0, 1, 0.5),
            p(65, "osc2Phase", "OSC 2 Phase", .percent, 0, 1, 0.5),
            p(66, "osc3Phase", "OSC 3 Phase", .percent, 0, 1, 0.5),
            p(67, "sampleOn", "Sample On", .boolean, 0, 1, 0),
            p(68, "sampleLevel", "Sample Level", .linearGain, 0, 1, 0.7071),
            p(69, "filter1Blend", "Filter 1 Blend", .percent, 0, 1, 0),
            p(70, "filter2Blend", "Filter 2 Blend", .percent, 0, 1, 0),
        ]

        let tree = AUParameterTree.createTree(withChildren: params)

        tree.implementorValueObserver = { [weak self] param, value in
            self?.paramValues[param.address] = value
            if let w = self?.wrapper { self?.applyParam(addr: param.address, value: value, to: w) }
        }
        tree.implementorValueProvider = { [weak self] param in
            self?.paramValues[param.address] ?? param.value
        }
        return tree
    }

    private static func lfoFrequency(fromNormalized v: Float) -> Float { -7 + 16 * v }

    private func applyOscRouting(_ oscIdx: Int, route: Float, to w: VitalEngineWrapper) {
        // Vital names: filter_N_oscM_input (no underscore between osc and index)
        let f1: Float = route == 1 ? 0 : 1
        let f2: Float = route == 0 ? 0 : 1
        w.setParameter("filter_1_osc\(oscIdx)_input", value: f1)
        w.setParameter("filter_2_osc\(oscIdx)_input", value: f2)
        w.setParameter("osc_\(oscIdx)_destination", value: route)
    }

    private func applyParam(addr: AUParameterAddress, value: AUValue, to w: VitalEngineWrapper) {
        let waveFrames: [Float] = [0, 0.25, 0.5, 0.75, 1.0]
        switch addr {
        case 0:  w.setParameter("osc_1_on",          value: value)
        case 1:  w.setParameter("osc_1_level",        value: value)
        case 2:  w.setParameter("osc_1_pan",          value: value * 2 - 1)
        case 3:  w.setParameter("osc_1_transpose",    value: value)
        case 4:  w.setParameter("osc_1_wave_frame",   value: waveFrames[min(Int(value), 4)] * 255.0)
        case 5:  w.setParameter("osc_2_on",          value: value)
        case 6:  w.setParameter("osc_2_level",        value: value)
        case 7:  w.setParameter("osc_2_pan",          value: value * 2 - 1)
        case 8:  w.setParameter("osc_2_transpose",    value: value)
        case 9:  w.setParameter("osc_2_wave_frame",   value: waveFrames[min(Int(value), 4)] * 255.0)
        case 10: w.setParameter("osc_3_on",          value: value)
        case 11: w.setParameter("osc_3_level",        value: value)
        case 12: w.setParameter("osc_3_pan",          value: value * 2 - 1)
        case 13: w.setParameter("osc_3_transpose",    value: value)
        case 14: w.setParameter("osc_3_wave_frame",   value: waveFrames[min(Int(value), 4)] * 255.0)
        case 15: w.setParameter("filter_1_cutoff",    value: value)
        case 16: w.setParameter("filter_1_resonance", value: value)
        case 17: w.setParameter("filter_1_drive",     value: value * 20.0)
        case 18: w.setParameter("filter_1_model",     value: value)
        case 19: w.setParameter("env_1_attack",       value: value)
        case 20: w.setParameter("env_1_decay",        value: value)
        case 21: w.setParameter("env_1_sustain",      value: value)
        case 22: w.setParameter("env_1_release",      value: value)
        case 23: w.setParameter("env_2_attack",       value: value)
        case 24: w.setParameter("env_2_decay",        value: value)
        case 25: w.setParameter("env_2_sustain",      value: value)
        case 26: w.setParameter("env_2_release",      value: value)
        case 27: w.setParameter("lfo_1_frequency",    value: Self.lfoFrequency(fromNormalized: value))
        case 28:
            w.setParameter("reverb_dry_wet", value: value)
            w.setParameter("reverb_on",      value: value > 0.01 ? 1 : 0)
        case 29:
            w.setParameter("delay_dry_wet",  value: value)
            w.setParameter("delay_on",       value: value > 0.01 ? 1 : 0)
        case 30:
            w.setParameter("chorus_dry_wet", value: value)
            w.setParameter("chorus_on",      value: value > 0.01 ? 1 : 0)
        case 31:
            w.setParameter("distortion_mix", value: value)
            w.setParameter("distortion_on",  value: value > 0.01 ? 1 : 0)
        case 32: w.setParameter("volume",             value: value * value * 7399.44)
        case 33: w.setParameter("osc_1_wave_frame",   value: value * 255.0)
        case 34: w.setParameter("osc_2_wave_frame",   value: value * 255.0)
        case 35: w.setParameter("osc_3_wave_frame",   value: value * 255.0)
        case 36: w.setParameter("filter_2_cutoff",    value: value)
        case 37: w.setParameter("filter_2_resonance", value: value)
        case 38: w.setParameter("filter_2_drive",     value: value * 20.0)
        case 39: w.setParameter("filter_2_model",     value: value)
        case 40: applyOscRouting(1, route: value, to: w)
        case 41: applyOscRouting(2, route: value, to: w)
        case 42: applyOscRouting(3, route: value, to: w)
        case 43:
            let targetIdx = Int((paramValues[44] ?? 0).rounded())
            let targetParam = lfoTargets[min(targetIdx, lfoTargets.count - 1)]
            w.setModulationAmount(value, source: "lfo_1", destination: targetParam)
        case 44:
            let oldIdx = Int((paramValues[44] ?? 0).rounded())
            let oldParam = lfoTargets[min(oldIdx, lfoTargets.count - 1)]
            w.setModulationAmount(0, source: "lfo_1", destination: oldParam)
            let newIdx = Int(value.rounded())
            let newParam = lfoTargets[min(newIdx, lfoTargets.count - 1)]
            let amt = paramValues[43] ?? 0.3
            w.setModulationAmount(amt, source: "lfo_1", destination: newParam)
        case 45:
            w.setParameter("legato",    value: value)
            w.setParameter("polyphony", value: value > 0.5 ? 1 : 16)
        case 46:
            w.setParameter("portamento_time", value: -10 + 14 * value)
        case 47: w.setParameter("macro_control_1", value: value)
        case 48: w.setParameter("macro_control_2", value: value)
        case 49: w.setParameter("macro_control_3", value: value)
        case 50: w.setParameter("macro_control_4", value: value)
        case 51...57:
            let lfoN = Int(addr - 49) // 51→2 … 57→8
            w.setParameter("lfo_\(lfoN)_frequency", value: Self.lfoFrequency(fromNormalized: value))
        case 58: w.setParameter("osc_1_unison_voices", value: value)
        case 59: w.setParameter("osc_2_unison_voices", value: value)
        case 60: w.setParameter("osc_3_unison_voices", value: value)
        case 61: w.setParameter("osc_1_unison_detune", value: value * 10)
        case 62: w.setParameter("osc_2_unison_detune", value: value * 10)
        case 63: w.setParameter("osc_3_unison_detune", value: value * 10)
        case 64: w.setParameter("osc_1_phase", value: value)
        case 65: w.setParameter("osc_2_phase", value: value)
        case 66: w.setParameter("osc_3_phase", value: value)
        case 67: w.setParameter("sample_on", value: value)
        case 68: w.setParameter("sample_level", value: value)
        case 69: w.setParameter("filter_1_blend", value: value * 2)
        case 70: w.setParameter("filter_2_blend", value: value * 2)
        default: break
        }
    }

    // MARK: - State persistence

    public override var fullState: [String: Any]? {
        get {
            var d: [String: Any] = [:]
            for (k, v) in paramValues { d["\(k)"] = v }
            return d
        }
        set {
            guard let d = newValue else { return }
            for (ks, val) in d {
                if let k = AUParameterAddress(ks), let v = val as? Float {
                    paramValues[k] = v
                    if let w = wrapper { applyParam(addr: k, value: v, to: w) }
                }
            }
        }
    }
}
