// tuning_ios_stub.cpp — Minimal Tuning implementation for iOS.
// Replaces the full tuning.cpp which has heavy JUCE String/File API usage
// for loading .scl, .kbm, and .tun microtuning files.
// On iOS we only need the default 12-TET tuning.

#include "tuning.h"
#include <cmath>
#include <string>

Tuning::Tuning()
    : scale_start_midi_note_(0),
      reference_midi_note_(60.0f),
      default_(true)
{
    setDefaultTuning();
}

Tuning::Tuning(File /*file*/) : Tuning() {}

Tuning Tuning::getTuningForFile(File /*file*/) { return Tuning(); }

String Tuning::allFileExtensions() { return ".scl .kbm .tun"; }

int Tuning::noteToMidiKey(const String& /*note*/) { return 60; }

void Tuning::setDefaultTuning() {
    default_ = true;
    // Build standard 12-TET lookup table.
    // The table covers 2 * kMidiSize = 256 notes centred at kMidiSize = 128.
    const int kSize   = kTuningSize;   // 256
    const int kCenter = kTuningCenter; // 128 (MIDI note 0 maps to index kCenter)
    for (int i = 0; i < kSize; ++i) {
        int midiNote = i - kCenter;
        tuning_[i] = vital::mono_float(midiNote);  // identity: midi note == pitch
    }
}

vital::mono_float Tuning::convertMidiNote(int note) const {
    int idx = note + kTuningCenter;
    if (idx < 0)      idx = 0;
    if (idx >= kTuningSize) idx = kTuningSize - 1;
    return tuning_[idx];
}

void Tuning::setConstantTuning(float note) {
    for (int i = 0; i < kTuningSize; ++i)
        tuning_[i] = note;
    default_ = false;
}

void Tuning::loadScale(std::vector<float> scale) {
    if (scale.empty()) { setDefaultTuning(); return; }
    int n = (int)scale.size();
    const int kCenter = kTuningCenter;
    for (int i = 0; i < kTuningSize; ++i) {
        int midiNote  = i - kCenter;
        int octave    = midiNote / n;
        int degree    = midiNote % n;
        if (degree < 0) { degree += n; octave -= 1; }
        tuning_[i] = vital::mono_float(octave * 12 + scale[degree]);
    }
    default_ = false;
}

void Tuning::setReferenceFrequency(float frequency) {
    // Adjust tuning so that the reference MIDI note plays at `frequency`.
    float cents = 1200.0f * std::log2f(frequency / 440.0f);
    float offset = cents / 100.0f - (reference_midi_note_ - 69.0f);
    for (int i = 0; i < kTuningSize; ++i)
        tuning_[i] += offset;
    default_ = false;
}

void Tuning::setReferenceNoteFrequency(int midi_note, float frequency) {
    reference_midi_note_ = float(midi_note);
    setReferenceFrequency(frequency);
}

void Tuning::loadFile(File /*file*/) {}

void Tuning::loadScalaFile(const StringArray& /*lines*/) {}

json Tuning::stateToJson() const {
    json j;
    j["tuning_name"]   = tuning_name_;
    j["mapping_name"]  = mapping_name_;
    j["default"]       = default_;
    return j;
}

void Tuning::jsonToState(const json& data) {
    if (data.count("tuning_name"))  tuning_name_  = data["tuning_name"].get<std::string>();
    if (data.count("mapping_name")) mapping_name_ = data["mapping_name"].get<std::string>();
    if (data.count("default") && data["default"].get<bool>()) setDefaultTuning();
}
