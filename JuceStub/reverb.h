#pragma once
// Shim: include memory.h so StereoMemory is a complete type before reverb.h
// uses it in std::unique_ptr<StereoMemory> (requires complete type for destructor).
#include "memory.h"
#include_next "reverb.h"
