//
//  VitalEngineWrapper.mm
//  Vital Synth
//
//  ObjC++ wrapper around vital::SoundEngine.
//

#import "VitalEngineWrapper.h"

// Vital synthesis headers
#include "sound_engine.h"
#include "tuning.h"
#include "wavetable.h"
#include "wave_frame.h"
#include "synth_parameters.h"
#include "synth_constants.h"
#include "synth_types.h"
#include "modulation_connection_processor.h"
#include "value.h"
#include "sample_source.h"
#include "line_generator.h"
#include "json/json.h"

#include <mutex>
#include <string>
#include <map>
#include <vector>
#include <complex>
#include <cmath>
#include <algorithm>

// poly_float::kSize is 4; stereo is indices 0 (L) and 1 (R)
static constexpr int kPolySize = vital::poly_float::kSize;
static constexpr int kDisplaySamples = 256;  // samples per display frame

/// Capture display frames from raw float samples (256 pts per kWaveformSize block).
static NSMutableArray<NSData *> *vitalCaptureDisplayFrames(const float *samples, int count) {
    const int kSize = vital::WaveFrame::kWaveformSize;
    int numFrames = std::max(1, count / kSize);
    numFrames = std::min(numFrames, vital::kNumOscillatorWaveFrames);
    NSMutableArray<NSData *> *arr = [NSMutableArray arrayWithCapacity:numFrames];
    for (int f = 0; f < numFrames; ++f) {
        float disp[kDisplaySamples];
        for (int i = 0; i < kDisplaySamples; ++i) {
            int si = f * kSize + i * kSize / kDisplaySamples;
            disp[i] = (si < count) ? samples[si] : 0.0f;
        }
        [arr addObject:[NSData dataWithBytes:disp length:kDisplaySamples * sizeof(float)]];
    }
    return arr;
}

@implementation VitalEngineWrapper {
    vital::SoundEngine *_engine;
    Tuning              _tuning;
    vital::control_map  _controls;
    std::mutex          _lock;
    int                 _sampleRate;
    // Active modulation connections: (source, destination) → ModulationConnection*
    std::map<std::pair<std::string,std::string>, vital::ModulationConnection*> _modConnections;
    // Cached display frames (256 float32 samples per frame) per oscillator
    NSMutableArray<NSData *> *_displayFrames[3];
}

- (instancetype)initWithSampleRate:(double)sampleRate {
    if (!(self = [super init])) return nil;

    _sampleRate = (int)sampleRate;

    // SoundEngine::SoundEngine() calls init() internally
    _engine = new vital::SoundEngine();
    _engine->setTuning(&_tuning);
    _engine->setSampleRate(_sampleRate);

    // Build parameter map once
    _controls = _engine->getControls();

    // Only override params that differ from Vital's built-in defaults.
    // "volume" default = 5473.04 (≈ -6 dB via sqrt scale) — leave as-is.
    // "osc_1_on" default is patched to 1.0 in synth_parameters.cpp — leave as-is.
    // Filter cutoff default = 60 (MIDI C4), resonance = 0.5 — leave as-is.
    // Envelope defaults: attack=0.1495, decay=1.0, sustain=1.0, release=0.5476 — leave as-is.

    // Enable filter 1 (defaults to off)
    [self _setRaw:"filter_1_on"     value:1.0f];

    // Enable filter 2 and set default routing: all oscillators → filter 1
    // Vital parameter names are filter_N_oscM_input (no underscore before osc index).
    [self _setRaw:"filter_2_on"         value:1.0f];
    [self _setRaw:"filter_1_osc1_input" value:1.0f];
    [self _setRaw:"filter_1_osc2_input" value:1.0f];
    [self _setRaw:"filter_1_osc3_input" value:1.0f];
    [self _setRaw:"filter_2_osc1_input" value:0.0f];
    [self _setRaw:"filter_2_osc2_input" value:0.0f];
    [self _setRaw:"filter_2_osc3_input" value:0.0f];
    // Osc destinations: 0=Filter1, 1=Filter2, 2=Filter1+2, 3=Effects, 4=Direct Out
    [self _setRaw:"osc_1_destination" value:0.0f];
    [self _setRaw:"osc_2_destination" value:0.0f];
    [self _setRaw:"osc_3_destination" value:0.0f];

    // Disable all FX (they're off by default but be explicit)
    [self _setRaw:"reverb_on"       value:0.0f];
    [self _setRaw:"delay_on"        value:0.0f];
    [self _setRaw:"chorus_on"       value:0.0f];
    [self _setRaw:"compressor_on"   value:0.0f];
    [self _setRaw:"distortion_on"   value:0.0f];
    [self _setRaw:"phaser_on"       value:0.0f];
    [self _setRaw:"flanger_on"      value:0.0f];
    [self _setRaw:"equalizer_on"    value:0.0f];
    [self _setRaw:"pitch_bend_range" value:2.0f];

    [self loadDefaultWavetables];

    return self;
}

- (void)dealloc {
    delete _engine;
}

// ─── Private helper ──────────────────────────────────────────────────────────

- (void)_setRaw:(const char *)name value:(float)v {
    auto it = _controls.find(std::string(name));
    if (it != _controls.end())
        it->second->set(vital::poly_float(v));
}

// ─── Public API ──────────────────────────────────────────────────────────────

- (void)loadDefaultWavetables {
    // Populate each oscillator's wavetable with basic predefined waveforms
    const vital::PredefinedWaveFrames::Shape shapes[3] = {
        vital::PredefinedWaveFrames::kSaw,
        vital::PredefinedWaveFrames::kSaw,
        vital::PredefinedWaveFrames::kSaw
    };
    for (int i = 0; i < vital::kNumOscillators; ++i) {
        vital::Wavetable* wt = _engine->getWavetable(i);
        if (!wt) continue;
        const vital::WaveFrame* frame =
            vital::PredefinedWaveFrames::getWaveFrame(shapes[i]);
        wt->loadWaveFrame(frame);
        wt->setName("Init");
        wt->postProcess(1.0f);
        wt->markUsed();
        // Leave _displayFrames[i] nil — predefined waveforms are drawn
        // by the math-based WavetableView in the UI, not the 3D view.
    }
}

- (void)noteOn:(int)note velocity:(float)velocity channel:(int)channel {
    std::lock_guard<std::mutex> lock(_lock);
    _engine->noteOn(note, velocity, 0, channel - 1);
}

- (void)noteOff:(int)note lift:(float)lift channel:(int)channel {
    std::lock_guard<std::mutex> lock(_lock);
    _engine->noteOff(note, lift, 0, channel - 1);
}

- (void)allNotesOff {
    std::lock_guard<std::mutex> lock(_lock);
    _engine->allNotesOff(0);
    _engine->allSoundsOff();
}

- (void)setPitchWheel:(float)value channel:(int)channel {
    std::lock_guard<std::mutex> lock(_lock);
    _engine->setPitchWheel(value, channel - 1);
}

- (void)setModWheel:(float)value channel:(int)channel {
    std::lock_guard<std::mutex> lock(_lock);
    _engine->setModWheelAllChannels(value);
}

- (void)renderIntoLeft:(float *)left right:(float *)right numFrames:(int)numFrames {
    // Use try_lock so the audio thread never blocks if a wavetable load is in progress.
    // Output silence instead of stalling the render callback.
    if (!_lock.try_lock()) {
        memset(left,  0, numFrames * sizeof(float));
        memset(right, 0, numFrames * sizeof(float));
        return;
    }

    // Process in kMaxBufferSize chunks
    const int kChunk = vital::kMaxBufferSize; // 128
    int offset = 0;

    while (offset < numFrames) {
        int block = std::min(kChunk, numFrames - offset);
        _engine->process(block);

        const float *buf = reinterpret_cast<const float *>(_engine->output(0)->buffer);
        for (int i = 0; i < block; ++i) {
            left [offset + i] = buf[i * kPolySize + 0];
            right[offset + i] = buf[i * kPolySize + 1];
        }
        offset += block;
    }

    _lock.unlock();
}

- (void)setParameter:(NSString *)name value:(float)value {
    std::lock_guard<std::mutex> lock(_lock);
    [self _setRaw:name.UTF8String value:value];
}

- (float)getParameter:(NSString *)name {
    auto it = _controls.find(std::string(name.UTF8String));
    if (it != _controls.end())
        return it->second->value();
    return 0.0f;
}

// ─── Wavetable loading helpers ────────────────────────────────────────────────

/// Decode a Base64 string to raw bytes.
static std::vector<uint8_t> vitalBase64Decode(const std::string& s) {
    static const int8_t kLUT[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    };
    std::vector<uint8_t> out;
    out.reserve(s.size() * 3 / 4);
    int val = 0, bits = -8;
    for (unsigned char c : s) {
        if (c == '=') break;
        int v = kLUT[c];
        if (v < 0) continue;
        val = (val << 6) | v;
        bits += 6;
        if (bits >= 0) { out.push_back((val >> bits) & 0xFF); bits -= 8; }
    }
    return out;
}

/// Load float samples into a Wavetable by slicing into kWaveformSize frames.
static bool vitalLoadFrames(vital::Wavetable *wt, const float *samples, int count) {
    const int kSize = vital::WaveFrame::kWaveformSize;
    int numFrames = std::max(1, count / kSize);
    numFrames = std::min(numFrames, vital::kNumOscillatorWaveFrames);
    wt->setNumFrames(numFrames);
    vital::WaveFrame frame;
    for (int f = 0; f < numFrames; ++f) {
        float buf[kSize] = {};
        int start = f * kSize;
        int avail = std::min(kSize, count - start);
        if (avail > 0) std::copy(samples + start, samples + start + avail, buf);
        frame.loadTimeDomain(buf);   // loadTimeDomain calls toFrequencyDomain internally
        wt->loadWaveFrame(&frame, f);
    }
    wt->postProcess(1.0f);
    wt->markUsed();
    return true;
}

// ─── Wavetable loading ────────────────────────────────────────────────────────

- (BOOL)loadWavetableFromJSON:(NSData *)jsonData oscillatorIndex:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    if (!jsonData) return NO;
    try {
        NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (!str) return NO;
        json j = json::parse(str.UTF8String);
        vital::Wavetable *wt = _engine->getWavetable(oscIndex);
        if (!wt) return NO;

        std::string tableName = "Wavetable";
        if (j.count("name") && j["name"].is_string())
            tableName = j["name"].get<std::string>();

        // Walk groups → components looking for an "audio_file" Base64 payload.
        for (auto& group : j.value("groups", json::array())) {
            for (auto& comp : group.value("components", json::array())) {
                if (!comp.count("audio_file")) continue;
                std::string b64 = comp["audio_file"].get<std::string>();
                auto raw = vitalBase64Decode(b64);
                if (raw.size() < 2) continue;

                // Vital stores 16-bit signed little-endian PCM in audio_file.
                int numSamples = (int)(raw.size() / 2);
                std::vector<float> floats(numSamples);
                for (int i = 0; i < numSamples; ++i) {
                    int16_t s = (int16_t)(raw[2*i] | (raw[2*i+1] << 8));
                    floats[i] = s / 32768.0f;
                }

                // Run FFT work WITHOUT holding _lock.
                // Vital's Wavetable uses separate current_data_ (written by loader) and
                // active_audio_data_ (read atomically by the audio thread). markUsed()
                // atomically publishes. No lock needed during the heavy FFT work.
                BOOL ok = vitalLoadFrames(wt, floats.data(), numSamples) ? YES : NO;
                if (ok) {
                    wt->setName(tableName);
                    NSMutableArray<NSData*>* frames = vitalCaptureDisplayFrames(floats.data(), numSamples);
                    // Brief lock only for bookkeeping (_displayFrames, wave_frame re-trigger)
                    std::lock_guard<std::mutex> lock(_lock);
                    _displayFrames[oscIndex] = frames;
                    [self _refreshOscillatorWavetable:oscIndex];
                }
                return ok;
            }
        }
        return NO;
    } catch (...) {
        return NO;
    }
}

// ─── Modulation routing ──────────────────────────────────────────────────────

- (BOOL)connectModulation:(NSString *)source to:(NSString *)destination amount:(float)amount {
    std::lock_guard<std::mutex> lock(_lock);
    std::string src = source.UTF8String;
    std::string dst = destination.UTF8String;
    auto key = std::make_pair(src, dst);

    // If already connected, just update the amount.
    auto existing = _modConnections.find(key);
    if (existing != _modConnections.end()) {
        existing->second->modulation_processor->setBaseValue(amount);
        return YES;
    }

    vital::ModulationConnectionBank& bank = _engine->getModulationBank();
    vital::ModulationConnection* connection = bank.createConnection(src, dst);
    if (!connection) return NO;

    vital::modulation_change change;
    change.source                = _engine->getModulationSource(src);
    change.mono_destination      = _engine->getMonoModulationDestination(dst);
    change.mono_modulation_switch= _engine->getMonoModulationSwitch(dst);

    // Validate BEFORE calling getParameterRange — it asserts on unknown destinations.
    if (!change.source || !change.mono_destination || !change.mono_modulation_switch)
        return NO;

    change.poly_modulation_switch= _engine->getPolyModulationSwitch(dst);
    change.poly_destination      = _engine->getPolyModulationDestination(dst);
    change.destination_scale     = vital::Parameters::getParameterRange(dst);
    change.modulation_processor  = connection->modulation_processor.get();
    change.disconnecting         = false;
    change.num_audio_rate        = 0;

    change.modulation_processor->setBaseValue(amount);
    change.modulation_processor->setBipolar(
        vital::ModulationConnection::isModulationSourceDefaultBipolar(src));
    _engine->connectModulation(change);
    _modConnections[key] = connection;
    return YES;
}

- (vital::ModulationConnection *)_modConnectionLocked:(NSString *)source destination:(NSString *)destination {
    auto key = std::make_pair(std::string(source.UTF8String), std::string(destination.UTF8String));
    auto it = _modConnections.find(key);
    return (it == _modConnections.end()) ? nullptr : it->second;
}

- (void)setModulationAmount:(float)amount source:(NSString *)source destination:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    if (auto *c = [self _modConnectionLocked:source destination:destination])
        c->modulation_processor->setBaseValue(amount);
}

- (void)setModulationBipolar:(BOOL)bipolar source:(NSString *)source destination:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    if (auto *c = [self _modConnectionLocked:source destination:destination])
        c->modulation_processor->setBipolar(bipolar);
}

- (void)setModulationStereo:(BOOL)stereo source:(NSString *)source destination:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    if (auto *c = [self _modConnectionLocked:source destination:destination])
        c->modulation_processor->setStereo(stereo);
}

- (void)setModulationBypass:(BOOL)bypass source:(NSString *)source destination:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    auto *c = [self _modConnectionLocked:source destination:destination];
    if (!c) return;
    int idx = c->modulation_processor->index();
    std::string name = "modulation_" + std::to_string(idx + 1) + "_bypass";
    auto it = _controls.find(name);
    if (it != _controls.end())
        it->second->set(bypass ? 1.0f : 0.0f);
}

- (void)setModulationPower:(float)power source:(NSString *)source destination:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    auto *c = [self _modConnectionLocked:source destination:destination];
    if (!c) return;
    int idx = c->modulation_processor->index();
    // UI -1…1 → Vital control -10…10
    float raw = std::max(-10.0f, std::min(10.0f, power * 10.0f));
    std::string name = "modulation_" + std::to_string(idx + 1) + "_power";
    auto it = _controls.find(name);
    if (it != _controls.end())
        it->second->set(raw);
}

- (NSArray<NSString *> *)modulationSourceNames {
    vital::output_map &sources = _engine->getModulationSources();
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:sources.size()];
    for (const auto &entry : sources)
        [names addObject:[NSString stringWithUTF8String:entry.first.c_str()]];
    [names sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return names;
}

- (NSArray<NSString *> *)modulationDestinationNames {
    vital::input_map &dests = _engine->getMonoModulationDestinations();
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:dests.size()];
    for (const auto &entry : dests)
        [names addObject:[NSString stringWithUTF8String:entry.first.c_str()]];
    [names sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return names;
}

- (void)disconnectModulation:(NSString *)source from:(NSString *)destination {
    std::lock_guard<std::mutex> lock(_lock);
    std::string src = source.UTF8String;
    std::string dst = destination.UTF8String;
    auto key = std::make_pair(src, dst);
    auto it = _modConnections.find(key);
    if (it == _modConnections.end()) return;

    vital::ModulationConnection* connection = it->second;
    vital::modulation_change change;
    change.source                = _engine->getModulationSource(src);
    change.mono_destination      = _engine->getMonoModulationDestination(dst);
    change.mono_modulation_switch= _engine->getMonoModulationSwitch(dst);

    // Validate BEFORE calling getParameterRange — it asserts on unknown destinations.
    if (change.source && change.mono_destination && change.mono_modulation_switch) {
        change.poly_modulation_switch= _engine->getPolyModulationSwitch(dst);
        change.poly_destination      = _engine->getPolyModulationDestination(dst);
        change.destination_scale     = vital::Parameters::getParameterRange(dst);
        change.modulation_processor  = connection->modulation_processor.get();
        change.disconnecting         = true;
        change.num_audio_rate        = 0;
        _engine->disconnectModulation(change);
    }
    _modConnections.erase(key);
}

- (NSArray<NSData *> *)getDisplayFrames:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return @[];
    return _displayFrames[oscIndex] ?: @[];
}

/// Force the oscillator to re-read its wavetable by nudging the wave_frame parameter.
- (void)_refreshOscillatorWavetable:(int)oscIndex {
    static const char* kFrameParams[3] = {
        "osc_1_wave_frame", "osc_2_wave_frame", "osc_3_wave_frame"
    };
    if (oscIndex < 0 || oscIndex >= 3) return;
    auto it = _controls.find(std::string(kFrameParams[oscIndex]));
    if (it == _controls.end()) return;
    // Re-set the current value to force Vital to re-evaluate the wavetable lookup.
    vital::poly_float cur = it->second->value();
    it->second->set(cur);
}

- (BOOL)loadWavetableFromSamples:(const float *)samples
                     sampleCount:(int)sampleCount
                      sampleRate:(int)sampleRate
                  oscillatorIndex:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    if (!samples || sampleCount <= 0) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;

    // Run FFT work WITHOUT holding _lock.
    // Vital's Wavetable uses separate current_data_ (written by loader) and
    // active_audio_data_ (read atomically by the audio thread). markUsed()
    // atomically publishes. No lock needed during the heavy FFT work.
    BOOL ok = vitalLoadFrames(wt, samples, sampleCount) ? YES : NO;
    if (ok) {
        NSMutableArray<NSData*>* frames = vitalCaptureDisplayFrames(samples, sampleCount);
        // Brief lock only for bookkeeping (_displayFrames, wave_frame re-trigger)
        std::lock_guard<std::mutex> lock(_lock);
        _displayFrames[oscIndex] = frames;
        [self _refreshOscillatorWavetable:oscIndex];
    }
    return ok;
}

- (NSString *)wavetableNameForOscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return @"";
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return @"";
    std::string name = wt->getName();
    return [NSString stringWithUTF8String:name.c_str()];
}

- (void)setWavetableName:(NSString *)name oscillatorIndex:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return;
    if (!name) return;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return;
    wt->setName(name.UTF8String);
}

- (NSArray<NSDictionary<NSString *, id> *> *)listModulations {
    std::lock_guard<std::mutex> lock(_lock);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:_modConnections.size()];
    for (const auto &entry : _modConnections) {
        auto *proc = entry.second->modulation_processor.get();
        float amount = proc->currentBaseValue();
        int idx = proc->index();
        float power = 0.0f;
        bool bypass = proc->isBypassed();
        {
            std::string pname = "modulation_" + std::to_string(idx + 1) + "_power";
            auto pit = _controls.find(pname);
            if (pit != _controls.end())
                power = ((float)pit->second->value()) / 10.0f; // normalize to ~-1…1
        }
        [result addObject:@{
            @"source":      [NSString stringWithUTF8String:entry.first.first.c_str()],
            @"destination": [NSString stringWithUTF8String:entry.first.second.c_str()],
            @"amount":      @(amount),
            @"bipolar":     @(proc->isBipolar() ? YES : NO),
            @"stereo":      @(proc->isStereo() ? YES : NO),
            @"bypass":      @(bypass ? YES : NO),
            @"power":       @(power),
            @"index":       @(idx)
        }];
    }
    return result;
}

- (NSArray<NSString *> *)allParameterNames {
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:_controls.size()];
    for (const auto &entry : _controls)
        [names addObject:[NSString stringWithUTF8String:entry.first.c_str()]];
    return names;
}

- (NSData *)getSampleDisplayBuffer {
    std::lock_guard<std::mutex> lock(_lock);
    vital::Sample *sample = _engine->getSample();
    if (!sample) return [NSData data];
    int length = sample->originalLength();
    const float *buf = sample->buffer();
    if (!buf || length <= 0) return [NSData data];

    float disp[kDisplaySamples];
    for (int i = 0; i < kDisplaySamples; ++i) {
        int si = i * length / kDisplaySamples;
        if (si >= length) si = length - 1;
        disp[i] = buf[si];
    }
    return [NSData dataWithBytes:disp length:kDisplaySamples * sizeof(float)];
}

// MARK: - Wavetable editing

- (int)waveformSize {
    return vital::WaveFrame::kWaveformSize;
}

- (int)maxWavetableFrames {
    return vital::kNumOscillatorWaveFrames;
}

- (int)numFramesForOscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return 0;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    return wt ? wt->numFrames() : 0;
}

- (BOOL)setNumFrames:(int)numFrames forOscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    int n = std::max(1, std::min(numFrames, vital::kNumOscillatorWaveFrames));
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    // setNumFrames may wait for audio thread; avoid holding our mutex across it.
    wt->setNumFrames(n);
    return YES;
}

- (NSData *)getFrameSamples:(int)oscIndex frame:(int)frameIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return nil;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return nil;
    int frames = wt->numFrames();
    if (frameIndex < 0 || frameIndex >= frames) return nil;
    const float *buf = wt->getBuffer(frameIndex);
    if (!buf) return nil;
    return [NSData dataWithBytes:buf length:vital::WaveFrame::kWaveformSize * sizeof(float)];
}

- (BOOL)setFrameSamples:(NSData *)samples oscillator:(int)oscIndex frame:(int)frameIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    if (!samples) return NO;
    const int kSize = vital::WaveFrame::kWaveformSize;
    if ((int)(samples.length / sizeof(float)) < kSize) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    int frames = wt->numFrames();
    if (frameIndex < 0 || frameIndex >= frames) return NO;

    const float *src = (const float *)samples.bytes;
    float buf[kSize];
    std::copy(src, src + kSize, buf);

    vital::WaveFrame frame;
    frame.loadTimeDomain(buf);
    wt->loadWaveFrame(&frame, frameIndex);
    return YES;
}

- (BOOL)_fillFrameLocked:(vital::Wavetable *)wt
                   shape:(int)shape
                   frame:(int)frameIndex {
    if (shape < 0 || shape >= vital::PredefinedWaveFrames::kNumShapes) return NO;
    if (frameIndex < 0 || frameIndex >= wt->numFrames()) return NO;
    const vital::WaveFrame *src = vital::PredefinedWaveFrames::getWaveFrame(
        (vital::PredefinedWaveFrames::Shape)shape);
    if (!src) return NO;
    vital::WaveFrame frame;
    frame.copy(src);
    wt->loadWaveFrame(&frame, frameIndex);
    return YES;
}

- (BOOL)fillFrameWithShape:(int)shape oscillator:(int)oscIndex frame:(int)frameIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    return [self _fillFrameLocked:wt shape:shape frame:frameIndex];
}

- (BOOL)fillAllFramesWithShape:(int)shape oscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    int n = wt->numFrames();
    for (int f = 0; f < n; ++f) {
        if (![self _fillFrameLocked:wt shape:shape frame:f]) return NO;
    }
    return YES;
}

- (BOOL)copyFrame:(int)fromFrame toFrame:(int)toFrame oscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    int n = wt->numFrames();
    if (fromFrame < 0 || fromFrame >= n || toFrame < 0 || toFrame >= n) return NO;
    const float *src = wt->getBuffer(fromFrame);
    if (!src) return NO;
    float buf[vital::WaveFrame::kWaveformSize];
    std::copy(src, src + vital::WaveFrame::kWaveformSize, buf);
    vital::WaveFrame frame;
    frame.loadTimeDomain(buf);
    wt->loadWaveFrame(&frame, toFrame);
    return YES;
}

- (void)_rebuildDisplayFrames:(int)oscIndex {
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) {
        _displayFrames[oscIndex] = nil;
        return;
    }
    int n = wt->numFrames();
    NSMutableArray<NSData *> *arr = [NSMutableArray arrayWithCapacity:n];
    for (int f = 0; f < n; ++f) {
        const float *buf = wt->getBuffer(f);
        float disp[kDisplaySamples];
        for (int i = 0; i < kDisplaySamples; ++i) {
            int si = i * vital::WaveFrame::kWaveformSize / kDisplaySamples;
            disp[i] = buf ? buf[si] : 0.0f;
        }
        [arr addObject:[NSData dataWithBytes:disp length:kDisplaySamples * sizeof(float)]];
    }
    std::lock_guard<std::mutex> lock(_lock);
    _displayFrames[oscIndex] = arr;
}

- (BOOL)commitWavetable:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    wt->postProcess(1.0f);
    wt->markUsed();
    [self _rebuildDisplayFrames:oscIndex];
    std::lock_guard<std::mutex> lock(_lock);
    [self _refreshOscillatorWavetable:oscIndex];
    return YES;
}

- (BOOL)expandWavetableToFrames:(int)numFrames oscillator:(int)oscIndex interpolate:(BOOL)interpolate {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    int target = std::max(1, std::min(numFrames, vital::kNumOscillatorWaveFrames));
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;

    const int kSize = vital::WaveFrame::kWaveformSize;
    int oldN = wt->numFrames();
    if (oldN <= 0) return NO;
    if (oldN == target) return YES;

    // Snapshot existing frames before resize (setNumFrames reallocates).
    std::vector<std::vector<float>> oldFrames(oldN, std::vector<float>(kSize));
    for (int f = 0; f < oldN; ++f) {
        const float *buf = wt->getBuffer(f);
        if (buf) std::copy(buf, buf + kSize, oldFrames[f].begin());
    }

    wt->setNumFrames(target);

    if (!interpolate || oldN == 1 || target == 1) {
        // Copy-fill already done by setNumFrames for growth; for shrink, frames are truncated.
        // When shrinking with no interpolate, nothing else needed.
        if (oldN == 1 && target > 1) {
            vital::WaveFrame frame;
            frame.loadTimeDomain(oldFrames[0].data());
            for (int f = 0; f < target; ++f)
                wt->loadWaveFrame(&frame, f);
        }
        return YES;
    }

    for (int f = 0; f < target; ++f) {
        float t = (target == 1) ? 0.0f : (float)f * (float)(oldN - 1) / (float)(target - 1);
        int i0 = (int)t;
        int i1 = std::min(oldN - 1, i0 + 1);
        float frac = t - (float)i0;
        float mixed[kSize];
        for (int s = 0; s < kSize; ++s)
            mixed[s] = oldFrames[i0][s] * (1.0f - frac) + oldFrames[i1][s] * frac;
        vital::WaveFrame frame;
        frame.loadTimeDomain(mixed);
        wt->loadWaveFrame(&frame, f);
    }
    return YES;
}

- (NSData *)getFrameAmplitudes:(int)oscIndex frame:(int)frameIndex harmonicCount:(int)harmonicCount {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return nil;
    if (harmonicCount <= 0) return nil;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return nil;
    if (frameIndex < 0 || frameIndex >= wt->numFrames()) return nil;
    const float *buf = wt->getBuffer(frameIndex);
    if (!buf) return nil;

    float timeBuf[vital::WaveFrame::kWaveformSize];
    std::copy(buf, buf + vital::WaveFrame::kWaveformSize, timeBuf);
    vital::WaveFrame frame;
    frame.loadTimeDomain(timeBuf); // includes toFrequencyDomain

    int count = std::min(harmonicCount, vital::WaveFrame::kNumRealComplex - 1);
    std::vector<float> amps(count);
    const float scale = 1.0f / (float)vital::WaveFrame::kWaveformSize;
    for (int h = 0; h < count; ++h) {
        // harmonics 1…count
        amps[h] = std::abs(frame.frequency_domain[h + 1]) * scale;
    }
    return [NSData dataWithBytes:amps.data() length:count * sizeof(float)];
}

- (NSData *)getFramePhases:(int)oscIndex frame:(int)frameIndex harmonicCount:(int)harmonicCount {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return nil;
    if (harmonicCount <= 0) return nil;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return nil;
    if (frameIndex < 0 || frameIndex >= wt->numFrames()) return nil;
    const float *buf = wt->getBuffer(frameIndex);
    if (!buf) return nil;

    float timeBuf[vital::WaveFrame::kWaveformSize];
    std::copy(buf, buf + vital::WaveFrame::kWaveformSize, timeBuf);
    vital::WaveFrame frame;
    frame.loadTimeDomain(timeBuf);

    int count = std::min(harmonicCount, vital::WaveFrame::kNumRealComplex - 1);
    std::vector<float> phases(count);
    for (int h = 0; h < count; ++h) {
        std::complex<float> c = frame.frequency_domain[h + 1];
        float amp = std::abs(c);
        phases[h] = (amp > 1.0e-8f) ? (std::arg(c) / vital::kPi) : 0.0f;
    }
    return [NSData dataWithBytes:phases.data() length:count * sizeof(float)];
}

- (BOOL)setFrameSpectrumAmplitudes:(NSData *)amps
                             phases:(NSData *)phases
                        oscillator:(int)oscIndex
                             frame:(int)frameIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    if (!amps) return NO;
    int count = (int)(amps.length / sizeof(float));
    if (count <= 0) return NO;
    if (phases && (int)(phases.length / sizeof(float)) < count) return NO;

    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    if (frameIndex < 0 || frameIndex >= wt->numFrames()) return NO;
    const float *buf = wt->getBuffer(frameIndex);
    if (!buf) return NO;

    float timeBuf[vital::WaveFrame::kWaveformSize];
    std::copy(buf, buf + vital::WaveFrame::kWaveformSize, timeBuf);
    vital::WaveFrame frame;
    frame.loadTimeDomain(timeBuf);

    const float *ampPtr = (const float *)amps.bytes;
    const float *phasePtr = phases ? (const float *)phases.bytes : nullptr;
    int maxH = std::min(count, vital::WaveFrame::kNumRealComplex - 1);
    for (int h = 0; h < maxH; ++h) {
        float amplitude = std::max(0.0f, ampPtr[h]) * (float)vital::WaveFrame::kWaveformSize;
        float phaseNorm;
        if (phasePtr) {
            phaseNorm = phasePtr[h];
        } else {
            float a = std::abs(frame.frequency_domain[h + 1]);
            phaseNorm = (a > 1.0e-8f) ? (std::arg(frame.frequency_domain[h + 1]) / vital::kPi) : 0.0f;
        }
        frame.frequency_domain[h + 1] = std::polar(amplitude, phaseNorm * vital::kPi);
    }

    frame.toTimeDomain();
    frame.normalize();
    frame.toFrequencyDomain();
    wt->loadWaveFrame(&frame, frameIndex);
    return YES;
}

// MARK: - LFO shape editing

- (LineGenerator *)_lfoSource:(int)lfoIndex {
    if (!_engine || lfoIndex < 0 || lfoIndex >= vital::kNumLfos) return nullptr;
    return _engine->getLfoSource(lfoIndex);
}

- (int)lfoPointCount:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    return src ? src->getNumPoints() : 0;
}

- (NSData *)getLfoPoints:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return nil;
    int n = src->getNumPoints();
    if (n <= 0) return nil;
    std::vector<float> xy(n * 2);
    for (int i = 0; i < n; ++i) {
        auto p = src->getPoint(i);
        xy[i * 2] = p.first;
        xy[i * 2 + 1] = p.second;
    }
    return [NSData dataWithBytes:xy.data() length:xy.size() * sizeof(float)];
}

- (BOOL)setLfoPoints:(int)lfoIndex interleavedXY:(NSData *)data {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src || !data) return NO;
    int n = (int)(data.length / (sizeof(float) * 2));
    if (n < 2 || n > LineGenerator::kMaxPoints) return NO;
    const float *xy = (const float *)data.bytes;
    src->setNumPoints(n);
    for (int i = 0; i < n; ++i) {
        float x = xy[i * 2];
        float y = xy[i * 2 + 1];
        if (i == 0) x = 0.0f;
        if (i == n - 1) x = 1.0f;
        x = std::max(0.0f, std::min(1.0f, x));
        y = std::max(0.0f, std::min(1.0f, y));
        src->setPoint(i, { x, y });
        src->setPower(i, 0.0f);
    }
    src->render();
    return YES;
}

- (BOOL)setLfoPoint:(int)lfoIndex index:(int)pointIndex x:(float)x y:(float)y {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    int n = src->getNumPoints();
    if (pointIndex < 0 || pointIndex >= n) return NO;

    float cx = std::max(0.0f, std::min(1.0f, x));
    float cy = std::max(0.0f, std::min(1.0f, y));
    if (pointIndex == 0) cx = 0.0f;
    else if (pointIndex == n - 1) cx = 1.0f;
    else {
        float minX = src->getPoint(pointIndex - 1).first;
        float maxX = src->getPoint(pointIndex + 1).first;
        cx = std::max(minX, std::min(maxX, cx));
    }
    src->setPoint(pointIndex, { cx, cy });
    src->render();
    return YES;
}

- (BOOL)addLfoPoint:(int)lfoIndex afterIndex:(int)afterIndex x:(float)x y:(float)y {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    int n = src->getNumPoints();
    if (n >= LineGenerator::kMaxPoints) return NO;
    int insertAt = std::max(1, std::min(n - 1, afterIndex + 1));
    float cx = std::max(0.0f, std::min(1.0f, x));
    float cy = std::max(0.0f, std::min(1.0f, y));
    src->addPoint(insertAt, { cx, cy });
    src->render();
    return YES;
}

- (BOOL)removeLfoPoint:(int)lfoIndex index:(int)pointIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    int n = src->getNumPoints();
    if (n <= 2) return NO;
    if (pointIndex <= 0 || pointIndex >= n - 1) return NO;
    src->removePoint(pointIndex);
    src->render();
    return YES;
}

- (BOOL)initLfoShape:(int)lfoIndex shape:(int)shape {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    switch (shape) {
        case 0: src->initLinear(); break;
        case 1: src->initTriangle(); break;
        case 2: src->initSquare(); break;
        case 3: src->initSin(); break;
        case 4: src->initSawUp(); break;
        case 5: src->initSawDown(); break;
        default: return NO;
    }
    return YES;
}

- (NSData *)getLfoPowers:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return nil;
    int n = src->getNumPoints();
    if (n <= 0) return nil;
    std::vector<float> powers(n);
    for (int i = 0; i < n; ++i)
        powers[i] = src->getPower(i);
    return [NSData dataWithBytes:powers.data() length:n * sizeof(float)];
}

- (BOOL)setLfoPower:(int)lfoIndex index:(int)pointIndex value:(float)value {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    int n = src->getNumPoints();
    if (pointIndex < 0 || pointIndex >= n) return NO;
    static constexpr float kMaxPower = 20.0f;
    float p = std::max(-kMaxPower, std::min(kMaxPower, value));
    src->setPower(pointIndex, p);
    src->render();
    return YES;
}

- (BOOL)lfoSmooth:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    return src ? src->smooth() : NO;
}

- (BOOL)setLfoSmooth:(int)lfoIndex enabled:(BOOL)enabled {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    src->setSmooth(enabled);
    return YES;
}

- (BOOL)flipLfoHorizontal:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    src->flipHorizontal();
    return YES;
}

- (BOOL)flipLfoVertical:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return NO;
    src->flipVertical();
    return YES;
}

- (NSData *)getLfoDisplayBuffer:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return nil;
    const vital::mono_float *buf = src->getBuffer();
    if (!buf) return nil;
    int res = src->resolution();
    float disp[kDisplaySamples];
    for (int i = 0; i < kDisplaySamples; ++i) {
        int si = (res <= 1) ? 0 : i * (res - 1) / (kDisplaySamples - 1);
        disp[i] = buf[si];
    }
    return [NSData dataWithBytes:disp length:kDisplaySamples * sizeof(float)];
}

- (BOOL)normalizeFrame:(int)frameIndex oscillator:(int)oscIndex removeDC:(BOOL)removeDC {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    if (frameIndex < 0 || frameIndex >= wt->numFrames()) return NO;
    const float *buf = wt->getBuffer(frameIndex);
    if (!buf) return NO;

    float timeBuf[vital::WaveFrame::kWaveformSize];
    std::copy(buf, buf + vital::WaveFrame::kWaveformSize, timeBuf);
    vital::WaveFrame frame;
    frame.loadTimeDomain(timeBuf);
    if (removeDC)
        frame.removedDc();
    frame.normalize(true);
    frame.toFrequencyDomain();
    wt->loadWaveFrame(&frame, frameIndex);
    return YES;
}

- (NSData *)getLfoStateJSON:(int)lfoIndex {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src) return nil;
    try {
        json data = src->stateToJson();
        std::string s = data.dump();
        return [NSData dataWithBytes:s.data() length:s.size()];
    } catch (...) {
        return nil;
    }
}

- (BOOL)setLfoStateJSON:(int)lfoIndex data:(NSData *)data {
    LineGenerator *src = [self _lfoSource:lfoIndex];
    if (!src || !data || data.length == 0) return NO;
    try {
        std::string s((const char *)data.bytes, data.length);
        json parsed = json::parse(s);
        if (!LineGenerator::isValidJson(parsed)) return NO;
        src->jsonToState(parsed);
        return YES;
    } catch (...) {
        return NO;
    }
}

- (BOOL)interpolateFramesFrom:(int)fromFrame
                           to:(int)toFrame
                         mode:(int)mode
                  oscillator:(int)oscIndex {
    if (oscIndex < 0 || oscIndex >= vital::kNumOscillators) return NO;
    vital::Wavetable *wt = _engine->getWavetable(oscIndex);
    if (!wt) return NO;
    int n = wt->numFrames();
    int a = std::min(fromFrame, toFrame);
    int b = std::max(fromFrame, toFrame);
    if (a < 0 || b >= n || b - a < 2) return NO;

    const int kSize = vital::WaveFrame::kWaveformSize;
    const float *bufA = wt->getBuffer(a);
    const float *bufB = wt->getBuffer(b);
    if (!bufA || !bufB) return NO;

    float timeA[kSize], timeB[kSize];
    std::copy(bufA, bufA + kSize, timeA);
    std::copy(bufB, bufB + kSize, timeB);

    vital::WaveFrame frameA, frameB;
    frameA.loadTimeDomain(timeA);
    frameB.loadTimeDomain(timeB);

    for (int f = a + 1; f < b; ++f) {
        float t = (float)(f - a) / (float)(b - a);
        vital::WaveFrame out;
        if (mode == 1) {
            // Spectral amp/phase lerp (harmonics 0…kNumRealComplex-1)
            for (int h = 0; h < vital::WaveFrame::kNumRealComplex; ++h) {
                float ampA = std::abs(frameA.frequency_domain[h]);
                float ampB = std::abs(frameB.frequency_domain[h]);
                float phaseA = (ampA > 1.0e-8f) ? std::arg(frameA.frequency_domain[h]) : 0.0f;
                float phaseB = (ampB > 1.0e-8f) ? std::arg(frameB.frequency_domain[h]) : 0.0f;
                // Unwrap-ish: take shortest path for phase
                float dPhase = phaseB - phaseA;
                while (dPhase > vital::kPi) dPhase -= 2.0f * vital::kPi;
                while (dPhase < -vital::kPi) dPhase += 2.0f * vital::kPi;
                float amp = ampA + (ampB - ampA) * t;
                float phase = phaseA + dPhase * t;
                out.frequency_domain[h] = std::polar(amp, phase);
            }
            for (int h = vital::WaveFrame::kNumRealComplex; h < kSize; ++h)
                out.frequency_domain[h] = 0.0f;
            out.toTimeDomain();
            out.normalize(true);
            out.toFrequencyDomain();
        } else {
            float mixed[kSize];
            for (int s = 0; s < kSize; ++s)
                mixed[s] = timeA[s] * (1.0f - t) + timeB[s] * t;
            out.loadTimeDomain(mixed);
        }
        wt->loadWaveFrame(&out, f);
    }
    return YES;
}

@end
