//
//  VitalEngineWrapper.h
//  Vital Synth
//
//  ObjC++ bridge exposing the Vital C++ DSP engine to Swift.
//

#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VitalEngineWrapper : NSObject

/// Initialise the engine at the given sample rate.
- (instancetype)initWithSampleRate:(double)sampleRate;

/// MIDI note on (note 0-127, velocity 0-1, channel 1-16).
- (void)noteOn:(int)note velocity:(float)velocity channel:(int)channel;

/// MIDI note off.
- (void)noteOff:(int)note lift:(float)lift channel:(int)channel;

/// Silence all notes and reset effect chain.
- (void)allNotesOff;

/// Pitch wheel value in [-1, 1].
- (void)setPitchWheel:(float)value channel:(int)channel;

/// Mod wheel value in [0, 1].
- (void)setModWheel:(float)value channel:(int)channel;

/// Render `numFrames` stereo samples into the provided buffers.
/// `left` and `right` must each have at least `numFrames` elements.
- (void)renderIntoLeft:(float *)left right:(float *)right numFrames:(int)numFrames;

/// Set any named Vital parameter (e.g. "filter_1_cutoff").
/// The value is the raw internal float value (matching Vital's parameter range).
- (void)setParameter:(NSString *)name value:(float)value;

/// Re-read the "oversampling" control (0=1x, 1=2x, 2=4x, 3=8x) and reconfigure the
/// engine if it changed. setParameter:"oversampling" already calls this.
- (void)checkOversampling;

/// Return the current value of a named parameter.
- (float)getParameter:(NSString *)name;

/// TUNE of oscillator 0…2 (`osc_1_tune`, `osc_2_tune`, `osc_3_tune`).
/// Raw Vital value; writes are clamped to the parameter's own range.
/// Equivalent to get/setParameter with the matching name, but index-validated.
- (float)tuneForOscillator:(int)oscIndex;
- (void)setTune:(float)tune forOscillator:(int)oscIndex;

/// Load a default sinusoidal wavetable into all oscillators.
- (void)loadDefaultWavetables;

/// Connect an LFO/envelope modulation source to a parameter destination.
/// source: e.g. "lfo_1", "env_2". destination: e.g. "filter_1_cutoff".
/// amount: typically -1…1. Returns YES on success.
- (BOOL)connectModulation:(NSString *)source to:(NSString *)destination amount:(float)amount;

/// Update the amount of an existing modulation connection.
- (void)setModulationAmount:(float)amount source:(NSString *)source destination:(NSString *)destination;

- (void)setModulationBipolar:(BOOL)bipolar source:(NSString *)source destination:(NSString *)destination;
- (void)setModulationStereo:(BOOL)stereo source:(NSString *)source destination:(NSString *)destination;
- (void)setModulationBypass:(BOOL)bypass source:(NSString *)source destination:(NSString *)destination;
/// Morph/power curve for the connection, typically -1…1 (mapped to Vital ±10).
- (void)setModulationPower:(float)power source:(NSString *)source destination:(NSString *)destination;

/// Remove a modulation connection.
- (void)disconnectModulation:(NSString *)source from:(NSString *)destination;

/// All modulation source names from the engine.
- (NSArray<NSString *> *)modulationSourceNames;

/// All mono modulation destination names from the engine.
- (NSArray<NSString *> *)modulationDestinationNames;

/// Load a wavetable from a JSON blob (.vitaltable or the wavetable object
/// extracted from a .vital preset).  Returns YES on success.
- (BOOL)loadWavetableFromJSON:(NSData *)jsonData oscillatorIndex:(int)oscIndex;

/// Load a wavetable by analysing raw mono float32 samples (e.g. decoded from
/// a WAV/AIF file).  Returns YES on success.
- (BOOL)loadWavetableFromSamples:(const float *)samples
                     sampleCount:(int)sampleCount
                      sampleRate:(int)sampleRate
                  oscillatorIndex:(int)oscIndex;

/// Wavetable display name (desktop OSC filename label). Empty if unset.
- (NSString *)wavetableNameForOscillator:(int)oscIndex;

/// Set the wavetable display name (e.g. from a dropped file's basename).
- (void)setWavetableName:(NSString *)name oscillatorIndex:(int)oscIndex;

/// Returns the display frames captured during the last wavetable load for the
/// given oscillator.  Each NSData element contains 256 float32 samples
/// normalised to [-1, 1] representing one wavetable frame.
- (NSArray<NSData *> *)getDisplayFrames:(int)oscIndex;

/// Active modulation connections as dictionaries with keys:
/// source, destination, amount, bipolar, stereo, bypass, power, index.
- (NSArray<NSDictionary<NSString *, id> *> *)listModulations;

/// Returns a downsampled preview of the loaded sample (256 float32 samples in [-1, 1]).
/// Empty if no sample is loaded.
- (NSData *)getSampleDisplayBuffer;

// MARK: - Wavetable editing

/// Samples per wavetable frame (Vital WaveFrame::kWaveformSize = 2048).
- (int)waveformSize;

/// Maximum frames per oscillator table (257).
- (int)maxWavetableFrames;

/// Current number of frames for an oscillator (1…257).
- (int)numFramesForOscillator:(int)oscIndex;

/// Resize the oscillator's wavetable (1…257). Returns YES on success.
- (BOOL)setNumFrames:(int)numFrames forOscillator:(int)oscIndex;

/// Full-resolution frame (2048 float32 samples in [-1, 1]). Nil if invalid.
- (nullable NSData *)getFrameSamples:(int)oscIndex frame:(int)frameIndex;

/// Write a full-resolution frame (must be 2048 float32 samples). Does not publish;
/// call commitWavetable: after a batch of edits.
- (BOOL)setFrameSamples:(NSData *)samples oscillator:(int)oscIndex frame:(int)frameIndex;

/// Fill one frame with a predefined shape:
/// 0=Sin, 1=SaturatedSin, 2=Triangle, 3=Square, 4=Pulse, 5=Saw
- (BOOL)fillFrameWithShape:(int)shape oscillator:(int)oscIndex frame:(int)frameIndex;

/// Fill every frame with the same predefined shape.
- (BOOL)fillAllFramesWithShape:(int)shape oscillator:(int)oscIndex;

/// Copy one frame onto another within the same oscillator.
- (BOOL)copyFrame:(int)fromFrame toFrame:(int)toFrame oscillator:(int)oscIndex;

/// postProcess + markUsed + refresh display-frame cache for the oscillator.
- (BOOL)commitWavetable:(int)oscIndex;

/// Expand to `numFrames` and linearly interpolate existing frames across the new span.
- (BOOL)expandWavetableToFrames:(int)numFrames oscillator:(int)oscIndex interpolate:(BOOL)interpolate;

/// Spectral amplitudes for harmonics 1…harmonicCount (normalized 0…1). Returns nil if invalid.
- (nullable NSData *)getFrameAmplitudes:(int)oscIndex frame:(int)frameIndex harmonicCount:(int)harmonicCount;

/// Spectral phases for harmonics 1…harmonicCount in [-1, 1] (= radians/π).
- (nullable NSData *)getFramePhases:(int)oscIndex frame:(int)frameIndex harmonicCount:(int)harmonicCount;

/// Write spectral amps (0…1) and optional phases ([-1,1]); nil phases keeps existing.
/// harmonicCount is the length of the arrays (harmonics 1…N).
- (BOOL)setFrameSpectrumAmplitudes:(NSData *)amps
                             phases:(NSData * _Nullable)phases
                        oscillator:(int)oscIndex
                             frame:(int)frameIndex;

// MARK: - LFO shape editing (LineGenerator control points)

/// Number of editable points for LFO 0…7.
- (int)lfoPointCount:(int)lfoIndex;

/// Interleaved float32 [x0,y0,x1,y1,…] in [0,1]. Nil if invalid.
- (nullable NSData *)getLfoPoints:(int)lfoIndex;

/// Replace all points from interleaved [x,y…] (at least 2 points). Calls render().
- (BOOL)setLfoPoints:(int)lfoIndex interleavedXY:(NSData *)data;

/// Move a single point and re-render. Endpoints stay pinned on x=0 / x=1.
- (BOOL)setLfoPoint:(int)lfoIndex index:(int)pointIndex x:(float)x y:(float)y;

/// Double-tap insert: add a point between index and index+1 (clamped).
- (BOOL)addLfoPoint:(int)lfoIndex afterIndex:(int)afterIndex x:(float)x y:(float)y;

/// Remove point (keeps ≥2). Endpoints cannot be removed.
- (BOOL)removeLfoPoint:(int)lfoIndex index:(int)pointIndex;

/// Init preset shape: 0=linear, 1=triangle, 2=square, 3=sine, 4=sawUp, 5=sawDown.
- (BOOL)initLfoShape:(int)lfoIndex shape:(int)shape;

/// Segment powers (one float per point, typically used for segments 0…n-2). Range ≈ [-20, 20].
- (nullable NSData *)getLfoPowers:(int)lfoIndex;

/// Set power for segment starting at pointIndex. Calls render().
- (BOOL)setLfoPower:(int)lfoIndex index:(int)pointIndex value:(float)value;

/// Smooth (half-sin) transitions between points.
- (BOOL)lfoSmooth:(int)lfoIndex;
- (BOOL)setLfoSmooth:(int)lfoIndex enabled:(BOOL)enabled;

- (BOOL)flipLfoHorizontal:(int)lfoIndex;
- (BOOL)flipLfoVertical:(int)lfoIndex;

/// Downsampled LFO buffer for drawing (256 float32 samples in [0,1]).
- (nullable NSData *)getLfoDisplayBuffer:(int)lfoIndex;

/// Normalize one wavetable frame to full scale; optionally remove DC.
- (BOOL)normalizeFrame:(int)frameIndex oscillator:(int)oscIndex removeDC:(BOOL)removeDC;

/// LFO shape as JSON (points, powers, smooth). Nil if invalid.
- (nullable NSData *)getLfoStateJSON:(int)lfoIndex;

/// Load LFO shape from JSON produced by getLfoStateJSON: / Vital LineGenerator state.
- (BOOL)setLfoStateJSON:(int)lfoIndex data:(NSData *)data;

/// Interpolate all frames strictly between fromFrame and toFrame.
/// mode: 0 = time-domain lerp, 1 = spectral amp/phase lerp.
- (BOOL)interpolateFramesFrom:(int)fromFrame
                           to:(int)toFrame
                         mode:(int)mode
                  oscillator:(int)oscIndex;

// MARK: - Preset modulations / LFOs (.vital `settings`)

/// Replace the modulation matrix with `settings.modulations` of a .vital preset.
/// `jsonData` may be the whole .vital file or just its `settings` object.
/// Existing connections are removed first (only if the preset has a
/// "modulations" array). Per-slot amount / bipolar / stereo / bypass / power
/// are read from `modulation_N_*` in `settings`.
/// Returns the number of connections created, or -1 if the JSON is invalid.
- (NSInteger)loadModulationsFromPresetJSON:(NSData *)jsonData;

/// Load `settings.lfos` (LineGenerator state of LFO 1…8) from a .vital preset.
/// Returns the number of LFOs loaded, or -1 if the JSON is invalid.
- (NSInteger)loadLFOsFromPresetJSON:(NSData *)jsonData;

/// Convenience: parse once, then load LFOs followed by modulations.
/// Call after the preset's plain parameters have been applied.
/// Returns YES if the JSON was valid.
- (BOOL)loadModulationsAndLFOsFromPresetJSON:(NSData *)jsonData;

// MARK: - Sampler (SMP)

/// Load a mono float32 buffer (e.g. decoded from WAV/AIF, [-1, 1]) into the
/// sampler. `sampleRate` is the buffer's own rate. Returns YES on success.
- (BOOL)loadSampleFromSamples:(const float *)samples
                  sampleCount:(int)sampleCount
                   sampleRate:(int)sampleRate;

/// Same as above, taking tightly-packed mono float32 bytes.
- (BOOL)loadSampleFromData:(NSData *)floatData sampleRate:(int)sampleRate;

@end

NS_ASSUME_NONNULL_END
