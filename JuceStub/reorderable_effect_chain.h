#pragma once
// Shim: inject chorus_module.h so that ChorusModule and StereoMemory are fully
// defined before sound_engine.cpp uses ChorusModule::kMaxDelayPairs.
#include "chorus_module.h"
#include_next "reorderable_effect_chain.h"
