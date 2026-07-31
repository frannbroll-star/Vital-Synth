#pragma once
// Shim: include types that module headers forward-declare but access inline,
// requiring a complete type at the point of use.
#include "memory.h"    // StereoMemory — used in reverb.h, reorderable_effect_chain.h, equalizer_module.h
#include "envelope.h"  // Envelope — accessed inline in envelope_module.h
#include_next "synth_module.h"
