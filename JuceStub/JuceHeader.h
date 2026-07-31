// JuceHeader.h — Minimal JUCE stubs for Vital DSP engine iOS compilation.
// Replaces the JUCE 5 framework with lightweight equivalents so the synthesis
// and common layers compile without the JUCE monolith.

#pragma once

#include <algorithm>
#include <cassert>
#include <complex>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

// ─────────────────────────────────────────────────────────────────────────────
// JUCE leak-detector / non-copyable macros — stripped to bare C++ equivalents
// ─────────────────────────────────────────────────────────────────────────────
#define JUCE_DECLARE_NON_COPYABLE(ClassName) \
    ClassName(const ClassName&) = delete; \
    ClassName& operator=(const ClassName&) = delete;

#define JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(ClassName) \
    JUCE_DECLARE_NON_COPYABLE(ClassName)

#define JUCE_LEAK_DETECTOR(ClassName)
#define JUCE_HEAVYWEIGHT_LEAK_DETECTOR(ClassName)

#define jassert(cond)    ((void)0)
#define jassertfalse
#define DBG(text)
#define JUCE_MODULE_AVAILABLE_juce_dsp 0

// ─────────────────────────────────────────────────────────────────────────────
// String
// ─────────────────────────────────────────────────────────────────────────────
class String {
public:
    String() {}
    String(const char* s) : s_(s ? s : "") {}
    String(const std::string& s) : s_(s) {}
    String(int n) : s_(std::to_string(n)) {}
    String(float n) : s_(std::to_string(n)) {}
    String(double n) : s_(std::to_string(n)) {}

    operator std::string() const { return s_; }
    const char* toRawUTF8() const { return s_.c_str(); }
    operator const char*() const { return s_.c_str(); }

    bool isEmpty() const { return s_.empty(); }
    bool isNotEmpty() const { return !s_.empty(); }
    int length() const { return (int)s_.size(); }

    String operator+(const String& o) const { return String(s_ + o.s_); }
    String operator+(const char* o) const { return String(s_ + o); }
    bool operator==(const String& o) const { return s_ == o.s_; }
    bool operator!=(const String& o) const { return s_ != o.s_; }
    bool operator< (const String& o) const { return s_ <  o.s_; }

    bool contains(const String& s) const { return s_.find(s.s_) != std::string::npos; }
    bool startsWith(const String& s) const { return s_.find(s.s_) == 0; }
    bool endsWith(const String& s) const {
        return s_.size() >= s.s_.size() &&
               s_.rfind(s.s_) == s_.size() - s.s_.size();
    }
    String toLowerCase() const {
        std::string c = s_;
        std::transform(c.begin(), c.end(), c.begin(), ::tolower);
        return c;
    }
    String trimmed() const {
        auto a = s_.find_first_not_of(" \t\n\r");
        if (a == std::string::npos) return {};
        auto b = s_.find_last_not_of(" \t\n\r");
        return s_.substr(a, b - a + 1);
    }
    double getDoubleValue() const { try { return std::stod(s_); } catch (...) { return 0; } }
    int    getIntValue()    const { try { return std::stoi(s_); } catch (...) { return 0; } }

    static String fromUTF8(const char* s, int n = -1) {
        return n < 0 ? String(s) : String(std::string(s, n));
    }

    std::string toStdString() const { return s_; }

private:
    std::string s_;
};

inline String operator+(const char* l, const String& r) { return String(std::string(l) + r.toStdString()); }

// ─────────────────────────────────────────────────────────────────────────────
// StringRef
// ─────────────────────────────────────────────────────────────────────────────
class StringRef {
public:
    StringRef(const char* s) : s_(s ? s : "") {}
    StringRef(const String& s) : s_(s.toRawUTF8()) {}
    const char* getCharPointer() const { return s_.c_str(); }
    operator String() const { return String(s_); }
private:
    std::string s_;
};

// ─────────────────────────────────────────────────────────────────────────────
// StringArray
// ─────────────────────────────────────────────────────────────────────────────
class StringArray {
public:
    StringArray() {}
    void add(const String& s) { v_.push_back(s); }
    int size() const { return (int)v_.size(); }
    bool isEmpty() const { return v_.empty(); }
    const String& operator[](int i) const { return v_[i]; }
    String&       operator[](int i)       { return v_[i]; }
    void addTokens(const String& str, const String& breaks, const String& /*quotes*/) {
        std::string s = str.toStdString(), b = breaks.toStdString(), tok;
        for (char c : s) {
            if (b.find(c) != std::string::npos) {
                if (!tok.empty()) { v_.push_back(String(tok)); tok.clear(); }
            } else { tok += c; }
        }
        if (!tok.empty()) v_.push_back(String(tok));
    }
private:
    std::vector<String> v_;
};

// ─────────────────────────────────────────────────────────────────────────────
// File
// ─────────────────────────────────────────────────────────────────────────────
class File {
public:
    File() {}
    File(const String& p) : p_(p.toStdString()) {}
    File(const std::string& p) : p_(p) {}
    File(const char* p) : p_(p ? p : "") {}

    bool exists() const { return false; }
    bool isDirectory() const { return false; }
    String getFullPathName() const { return p_; }
    String getFileName() const {
        auto i = p_.rfind('/');
        return i != std::string::npos ? p_.substr(i + 1) : p_;
    }
    String getFileNameWithoutExtension() const {
        auto n = getFileName().toStdString();
        auto i = n.rfind('.');
        return i != std::string::npos ? n.substr(0, i) : n;
    }
    String getFileExtension() const {
        auto n = getFileName().toStdString();
        auto i = n.rfind('.');
        return i != std::string::npos ? n.substr(i) : "";
    }
    File getParentDirectory() const {
        auto i = p_.rfind('/');
        return i != std::string::npos ? File(p_.substr(0, i)) : File("");
    }
    File getChildFile(const String& s) const { return File(p_ + "/" + s.toStdString()); }

    bool operator==(const File& o) const { return p_ == o.p_; }
    bool operator!=(const File& o) const { return p_ != o.p_; }
    bool operator< (const File& o) const { return p_ <  o.p_; }

    std::vector<File> findChildFiles(int, bool, const String&) const { return {}; }

private:
    std::string p_;
};

// ─────────────────────────────────────────────────────────────────────────────
// CriticalSection / ScopedLock / ScopedTryLock
// ─────────────────────────────────────────────────────────────────────────────
class CriticalSection {
public:
    void enter()    const noexcept { m_.lock(); }
    void exit()     const noexcept { m_.unlock(); }
    bool tryEnter() const noexcept { return m_.try_lock(); }
    mutable std::mutex m_;
};

class ScopedLock {
public:
    explicit ScopedLock(const CriticalSection& cs) noexcept : cs_(cs) { cs_.enter(); }
    ~ScopedLock() noexcept { cs_.exit(); }
    JUCE_DECLARE_NON_COPYABLE(ScopedLock)
private:
    const CriticalSection& cs_;
};

class ScopedTryLock {
public:
    explicit ScopedTryLock(const CriticalSection& cs) noexcept : cs_(cs), locked_(cs.tryEnter()) {}
    ~ScopedTryLock() noexcept { if (locked_) cs_.exit(); }
    bool isLocked() const noexcept { return locked_; }
    JUCE_DECLARE_NON_COPYABLE(ScopedTryLock)
private:
    const CriticalSection& cs_;
    bool locked_;
};

// ─────────────────────────────────────────────────────────────────────────────
// AudioSampleBuffer (minimal)
// ─────────────────────────────────────────────────────────────────────────────
class AudioSampleBuffer {
public:
    AudioSampleBuffer() : ch_(0), n_(0) {}
    AudioSampleBuffer(int channels, int samples) { setSize(channels, samples); }

    void setSize(int ch, int n, bool keep = false, bool /*clearExtra*/ = false, bool /*avoidRealloc*/ = false) {
        data_.resize(ch * n, 0.0f);
        ptrs_.resize(ch);
        for (int i = 0; i < ch; ++i) ptrs_[i] = data_.data() + i * n;
        ch_ = ch; n_ = n;
    }
    float*       getWritePointer(int ch)       { return ch < ch_ ? ptrs_[ch] : nullptr; }
    const float* getReadPointer(int ch)  const { return ch < ch_ ? ptrs_[ch] : nullptr; }
    int getNumChannels() const { return ch_; }
    int getNumSamples()  const { return n_;  }
    void clear() { std::fill(data_.begin(), data_.end(), 0.0f); }

private:
    int ch_, n_;
    std::vector<float>  data_;
    std::vector<float*> ptrs_;
};

// ─────────────────────────────────────────────────────────────────────────────
// MidiMessage (minimal)
// ─────────────────────────────────────────────────────────────────────────────
class MidiMessage {
public:
    MidiMessage() : n_(0) { memset(d_, 0, sizeof(d_)); }

    static MidiMessage noteOn(int ch, int note, float vel) {
        MidiMessage m; m.d_[0] = 0x90|(ch-1); m.d_[1] = note; m.d_[2] = (uint8_t)(vel*127); m.n_=3; return m;
    }
    static MidiMessage noteOff(int ch, int note) {
        MidiMessage m; m.d_[0] = 0x80|(ch-1); m.d_[1] = note; m.d_[2] = 0; m.n_=3; return m;
    }
    static MidiMessage pitchWheel(int ch, int value) {
        MidiMessage m; m.d_[0] = 0xE0|(ch-1); m.d_[1] = value&0x7F; m.d_[2] = (value>>7)&0x7F; m.n_=3; return m;
    }
    static MidiMessage controllerEvent(int ch, int cc, int val) {
        MidiMessage m; m.d_[0] = 0xB0|(ch-1); m.d_[1] = cc; m.d_[2] = val; m.n_=3; return m;
    }

    bool isNoteOn(bool vel0 = false)  const { return (d_[0]&0xF0)==0x90 && (vel0||d_[2]>0); }
    bool isNoteOff(bool vel0 = true)  const { return (d_[0]&0xF0)==0x80 || ((d_[0]&0xF0)==0x90&&d_[2]==0&&vel0); }
    bool isPitchWheel()               const { return (d_[0]&0xF0)==0xE0; }
    bool isController()               const { return (d_[0]&0xF0)==0xB0; }
    bool isControllerOfType(int t)    const { return isController() && d_[1]==t; }
    bool isAftertouch()               const { return (d_[0]&0xF0)==0xA0; }
    bool isChannelPressure()          const { return (d_[0]&0xF0)==0xD0; }
    bool isAllNotesOff()              const { return isController() && d_[1]==123; }
    bool isAllSoundOff()              const { return isController() && d_[1]==120; }

    int   getNoteNumber()           const { return d_[1]; }
    float getVelocity()             const { return d_[2]/127.0f; }
    float getFloatVelocity()        const { return d_[2]/127.0f; }
    int   getChannel()              const { return (d_[0]&0x0F)+1; }
    int   getPitchWheelValue()      const { return d_[1]|(d_[2]<<7); }
    int   getControllerNumber()     const { return d_[1]; }
    int   getControllerValue()      const { return d_[2]; }
    float getAfterTouchValue()      const { return d_[2]/127.0f; }
    float getChannelPressureValue() const { return d_[1]/127.0f; }

private:
    uint8_t d_[4]; int n_;
};

// ─────────────────────────────────────────────────────────────────────────────
// MidiBuffer (minimal iterable buffer)
// ─────────────────────────────────────────────────────────────────────────────
class MidiBuffer {
public:
    struct Iterator {
        Iterator(const MidiBuffer& b) : b_(b), i_(0) {}
        bool getNextEvent(MidiMessage& msg, int& sample) {
            if (i_ >= (int)b_.events_.size()) return false;
            msg = b_.events_[i_].first; sample = b_.events_[i_].second; ++i_;
            return true;
        }
        const MidiBuffer& b_; int i_;
    };

    void addEvent(const MidiMessage& m, int sample) { events_.push_back({m, sample}); }
    void clear() { events_.clear(); }
    bool isEmpty() const { return events_.empty(); }
    int  getNumEvents() const { return (int)events_.size(); }

    std::vector<std::pair<MidiMessage,int>> events_;
};

// ─────────────────────────────────────────────────────────────────────────────
// MidiKeyboardState (stub — MIDI is driven by our own wrapper)
// ─────────────────────────────────────────────────────────────────────────────
class MidiKeyboardState {
public:
    void processNextMidiBuffer(MidiBuffer&, int, int, bool) {}
    void allNotesOff(int) {}
};

// ─────────────────────────────────────────────────────────────────────────────
// Random
// ─────────────────────────────────────────────────────────────────────────────
class Random {
public:
    static Random& getSystemRandom() { static Random r; return r; }
    float nextFloat() { return (float)rand() / (float)RAND_MAX; }
    int   nextInt(int max) { return max > 0 ? rand() % max : 0; }
};

// ─────────────────────────────────────────────────────────────────────────────
// FloatVectorOperations — flush denormals to zero on ARM64 (iOS)
// ─────────────────────────────────────────────────────────────────────────────
struct FloatVectorOperations {
    static void disableDenormalisedNumberSupport(bool /*shouldDisable*/ = true) {
#if defined(__aarch64__)
        uint64_t fpcr;
        __asm__ __volatile__("mrs %0, fpcr" : "=r"(fpcr));
        fpcr |= (1ULL << 24); // FZ — Flush-to-Zero
        __asm__ __volatile__("msr fpcr, %0" :: "r"(fpcr));
#elif defined(__SSE__)
        int mask = _mm_getcsr();
        _mm_setcsr(mask | 0x8040); // DAZ + FTZ
#endif
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// MemoryOutputStream — minimal stub (used in sample_source.cpp for base64 decode)
// ─────────────────────────────────────────────────────────────────────────────
class MemoryOutputStream {
public:
    explicit MemoryOutputStream(size_t /*initialCapacity*/ = 0) {}
    void write(const void* data, size_t n) {
        const uint8_t* p = static_cast<const uint8_t*>(data);
        buf_.insert(buf_.end(), p, p + n);
    }
    const void* getData() const { return buf_.data(); }
    size_t getDataSize()  const { return buf_.size();  }
    void reset() { buf_.clear(); }
private:
    std::vector<uint8_t> buf_;
};

// ─────────────────────────────────────────────────────────────────────────────
// Base64 — minimal stub (encode/decode, used in sample_source.cpp)
// ─────────────────────────────────────────────────────────────────────────────
struct Base64 {
    static String toBase64(const void* data, size_t numBytes) {
        // Standard base64 alphabet
        static const char kAlpha[] =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        const uint8_t* in = static_cast<const uint8_t*>(data);
        std::string out;
        out.reserve(((numBytes + 2) / 3) * 4);
        for (size_t i = 0; i < numBytes; i += 3) {
            uint32_t v = ((uint32_t)in[i] << 16)
                       | (i+1 < numBytes ? (uint32_t)in[i+1] <<  8 : 0)
                       | (i+2 < numBytes ? (uint32_t)in[i+2]       : 0);
            out += kAlpha[(v >> 18) & 63];
            out += kAlpha[(v >> 12) & 63];
            out += (i+1 < numBytes) ? kAlpha[(v >>  6) & 63] : '=';
            out += (i+2 < numBytes) ? kAlpha[ v        & 63] : '=';
        }
        return String(out);
    }

    static bool convertFromBase64(MemoryOutputStream& out, const String& encoded) {
        static const int8_t kDecode[128] = {
            -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
            -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
            -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
            52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,
            -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
            15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
            -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
            41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1
        };
        const char* s = encoded.toRawUTF8();
        size_t len = encoded.length();
        for (size_t i = 0; i + 3 < len; i += 4) {
            int8_t a = (s[i]<128)?kDecode[(int)s[i]]:-1;
            int8_t b = (s[i+1]<128)?kDecode[(int)s[i+1]]:-1;
            int8_t c = (s[i+2]!='='&&s[i+2]<128)?kDecode[(int)s[i+2]]:-1;
            int8_t d = (s[i+3]!='='&&s[i+3]<128)?kDecode[(int)s[i+3]]:-1;
            if (a<0||b<0) return false;
            uint8_t bytes[3];
            bytes[0] = (uint8_t)((a<<2)|(b>>4));
            if (c >= 0) bytes[1] = (uint8_t)((b<<4)|(c>>2));
            if (d >= 0) bytes[2] = (uint8_t)((c<<6)| d);
            out.write(bytes, (c<0)?1:(d<0)?2:3);
        }
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Misc stubs referenced in tuning / load_save
// ─────────────────────────────────────────────────────────────────────────────
class URL { public: URL(const String&) {} };
class XmlElement { public: XmlElement(const String&) {} };

