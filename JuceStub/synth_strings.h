#pragma once
// Shim: include operators.h so vital::StereoEncoder is defined before the real
// synth_strings.h (in interface/look_and_feel/) references it.
#include "operators.h"
#include_next "synth_strings.h"
