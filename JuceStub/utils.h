#pragma once
// Shim: include the real utils.h first (which brings in common.h → poly_values.h
// so poly_float is defined), then include futils.h so that futils::exp2 etc.
// are visible in translation units that include utils.h but not futils.h directly
// (e.g. synth_lfo.cpp).
#include_next "utils.h"
#include "futils.h"
