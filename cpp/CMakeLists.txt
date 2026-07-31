cmake_minimum_required(VERSION 3.18)
project(VitalEngine CXX C)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# ─── Source discovery ──────────────────────────────────────────────────────────
set(VIAL_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../vial/src")

# All synthesis C++ files (JUCE-free except for the macros we stub)
# Note: effects_engine/sound_engine.cpp references methods that don't exist in
# the vial fork (setPitchWheelControl, setModWheelControl on EffectsModulationHandler).
# We use synth_engine/sound_engine.cpp instead which builds cleanly.
file(GLOB_RECURSE SYNTHESIS_SOURCES
    "${VIAL_SRC}/synthesis/framework/*.cpp"
    "${VIAL_SRC}/synthesis/synth_engine/*.cpp"
    "${VIAL_SRC}/synthesis/producers/*.cpp"
    "${VIAL_SRC}/synthesis/modulators/*.cpp"
    "${VIAL_SRC}/synthesis/filters/*.cpp"
    "${VIAL_SRC}/synthesis/effects/*.cpp"
    "${VIAL_SRC}/synthesis/lookups/*.cpp"
    "${VIAL_SRC}/synthesis/modules/*.cpp"
    "${VIAL_SRC}/synthesis/utilities/*.cpp"
)
# effects_engine/ has a duplicate SoundEngine that conflicts with synth_engine's.
# Include only the non-SoundEngine files from effects_engine/.
file(GLOB EFFECTS_ENGINE_SOURCES "${VIAL_SRC}/synthesis/effects_engine/*.cpp")
list(FILTER EFFECTS_ENGINE_SOURCES EXCLUDE REGEX ".*sound_engine.*\\.cpp$")
list(APPEND SYNTHESIS_SOURCES ${EFFECTS_ENGINE_SOURCES})

# Selected common files (only those with minimal JUCE surface that our stub covers)
# tuning.cpp is replaced by tuning_ios_stub.cpp (avoids heavy String/File parsing)
set(COMMON_SOURCES
    "${VIAL_SRC}/common/synth_types.cpp"
    "${VIAL_SRC}/common/synth_parameters.cpp"
    "${VIAL_SRC}/common/line_generator.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/tuning_ios_stub.cpp"
)

add_library(VitalEngine STATIC
    ${SYNTHESIS_SOURCES}
    ${COMMON_SOURCES}
)

# ─── Include paths ─────────────────────────────────────────────────────────────
target_include_directories(VitalEngine PUBLIC
    # Our JUCE stub (must come first so it shadows any real JUCE headers)
    "${CMAKE_CURRENT_SOURCE_DIR}/../JuceStub"

    # Synthesis framework headers
    "${VIAL_SRC}/synthesis/framework"
    "${VIAL_SRC}/synthesis/synth_engine"
    "${VIAL_SRC}/synthesis/producers"
    "${VIAL_SRC}/synthesis/modulators"
    "${VIAL_SRC}/synthesis/filters"
    "${VIAL_SRC}/synthesis/effects"
    "${VIAL_SRC}/synthesis/effects_engine"
    "${VIAL_SRC}/synthesis/lookups"
    "${VIAL_SRC}/synthesis/modules"
    "${VIAL_SRC}/synthesis/utilities"

    # Common headers (synth_types, synth_parameters, tuning, line_generator)
    "${VIAL_SRC}/common"

    # synth_strings.h is in interface/look_and_feel/ but has no JUCE deps
    "${VIAL_SRC}/interface/look_and_feel"

    # Third-party (header-only)
    # json.h is at third_party/json/json.h → included as "json/json.h" → parent dir needed
    "${CMAKE_CURRENT_SOURCE_DIR}/../vial/third_party"
    "${CMAKE_CURRENT_SOURCE_DIR}/../vial/third_party/concurrentqueue"
)

# ─── Compile options ───────────────────────────────────────────────────────────
target_compile_options(VitalEngine PRIVATE
    -ffast-math
    -O2
    -Wall
    -Wno-unused-variable
    -Wno-unused-parameter
    -Wno-sign-compare
    -Wno-reorder
    # Tell wavetable code to use Apple Accelerate FFT (defined in fourier_transform.h)
    # __APPLE__ is already set by the toolchain on iOS
)

# Accelerate framework provides vDSP FFT used in fourier_transform.h on Apple
target_link_libraries(VitalEngine PUBLIC "-framework Accelerate")
