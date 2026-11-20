# Platform Adapter Architecture

This document describes the future architecture for a shared C++ Calculation Core targeting Android (FFI) and Web (WASM). **This is a design proposal only — no implementation exists yet.**

---

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App (Dart)                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Domain Use Cases (Current — Pure Dart)                 │   │
│  │  - CalculateSqi                                         │   │
│  │  - GenerateRecommendations                              │   │
│  │  - CalculatePlannerBedtimes                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼ (Future: Adapter Interface)      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Engine Adapters (Dart ↔ Native Boundary)               │   │
│  │  - SqiEngineAdapter                                     │   │
│  │  - RecommendationEngineAdapter                          │   │
│  │  - PlannerEngineAdapter                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          ▼                                       ▼
┌─────────────────────────────┐       ┌─────────────────────────────┐
│        Android              │       │           Web               │
│  ┌───────────────────────┐  │       │  ┌───────────────────────┐  │
│  │ libsleepcore.so       │  │       │  │ sleepcore.wasm        │  │
│  │ (ARM64, ARM32, x86_64)│  │       │  │ (WASM + JS glue)      │  │
│  │ Built with CMake/NDK  │  │       │  │ Built with Emscripten │  │
│  └───────────────────────┘  │       │  └───────────────────────┘  │
└─────────────────────────────┘       └─────────────────────────────┘
```

**Key Principle:** Android and Web require **separate build artifacts and adapters** even if they share the same C++ source.

---

## Android: C++ Shared Core via FFI

### 1. Build System

**File structure:**
```
android/
├── CMakeLists.txt
├── src/main/cpp/
│   ├── sleep_core.cpp
│   ├── sleep_core.h
│   ├── sqi.cpp
│   ├── planner.cpp
│   └── json.cpp (or use simdjson/cJSON)
└── build.gradle.kts (configure NDK, CMake)
```

**CMakeLists.txt essentials:**
```cmake
cmake_minimum_required(VERSION 3.18)
project(sleepcore LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(sleepcore SHARED
    src/main/cpp/sleep_core.cpp
    src/main/cpp/sqi.cpp
    src/main/cpp/planner.cpp
)

target_include_directories(sleepcore PRIVATE src/main/cpp)

# Android NDK
if(ANDROID)
    target_link_libraries(sleepcore log)
endif()
```

**build.gradle.kts:**
```kotlin
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                cppFlags.add("-std=c++17")
                arguments.add("-DANDROID_STL=c++_shared")
            }
        }
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64"))
        }
    }
    externalNativeBuild {
        cmake {
            path = "CMakeLists.txt"
            version = "3.22.1"
        }
    }
}
```

### 2. Supported ABIs

| ABI | Status | Notes |
|-----|--------|-------|
| `arm64-v8a` | Required | 64-bit ARM (most devices) |
| `armeabi-v7a` | Optional | 32-bit ARM (legacy) |
| `x86_64` | Optional | Emulators, Chrome OS |
| `x86` | Not supported | Deprecated |

**Recommendation:** Ship `arm64-v8a` + `armeabi-v7a` minimum. `x86_64` for emulator testing.

### 3. Dart FFI Adapter

```dart
// lib/core/native/sleep_core_ffi.dart
import 'dart:ffi';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SleepCoreFFI {
  static final DynamicLibrary _lib = _loadLibrary();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libsleepcore.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  // calculateSqi
  static int calculateSqi(String inputJson, Pointer<Utf8> outputJson) {
    final func = _lib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>)>>(
            'calculate_sqi');
    return func.asFunction<int Function(Pointer<Utf8>, Pointer<Utf8>)>()(
        inputJson.toNativeUtf8(), outputJson);
  }

  // calculatePlannerBedtimes
  static int calculatePlannerBedtimes(String inputJson, Pointer<Utf8> outputJson) {
    final func = _lib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>)>>(
            'calculate_planner_bedtimes');
    return func.asFunction<int Function(Pointer<Utf8>, Pointer<Utf8>)>()(
        inputJson.toNativeUtf8(), outputJson);
  }

  static void freeString(Pointer<Utf8> ptr) {
    final func = _lib
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('free_string');
    func.asFunction<void Function(Pointer<Utf8>)>()(ptr);
  }
}
```

### 4. C++ API (Header)

```cpp
// sleep_core.h
#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// Error codes
enum SleepCoreError {
    SLEEP_CORE_OK = 0,
    SLEEP_CORE_INVALID_INPUT = 1,
    SLEEP_CORE_COMPUTATION_ERROR = 2,
    SLEEP_CORE_OOM = 3,
};

// calculateSqi
// inputJson: {"responses": {"Sleep duration": 3, ...}}
// outputJson: allocated by callee, must be freed with free_string
int32_t calculate_sqi(const char* input_json, char** output_json);

// calculatePlannerBedtimes
// inputJson: {"wakeUpTime": "2024-01-15T07:00:00", "latencyMinutes": 15}
// outputJson: allocated by callee, must be freed with free_string
int32_t calculate_planner_bedtimes(const char* input_json, char** output_json);

// Memory management
void free_string(char* ptr);

#ifdef __cplusplus
}
#endif
```

---

## Web: C++ Compiled to WASM via Emscripten

### 1. Build System

**emscripten.cmake:**
```cmake
cmake_minimum_required(VERSION 3.18)
project(sleepcore_wasm LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Emscripten toolchain
set(CMAKE_TOOLCHAIN_FILE $ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake)

add_library(sleepcore_wasm SHARED
    src/sleep_core.cpp
    src/sqi.cpp
    src/planner.cpp
    src/wasm_bindings.cpp
)

target_include_directories(sleepcore_wasm PRIVATE src)
target_link_libraries(sleepcore_wasm PUBLIC embind)
```

**wasm_bindings.cpp (embind):**
```cpp
#include <emscripten/bind.h>
#include "sleep_core.h"

using namespace emscripten;

std::string calculateSqiWrapper(const std::string& inputJson) {
    char* outputJson = nullptr;
    int32_t result = calculate_sqi(inputJson.c_str(), &outputJson);
    if (result != SLEEP_CORE_OK) {
        throw std::runtime_error("SQI calculation failed");
    }
    std::string output(outputJson);
    free_string(outputJson);
    return output;
}

std::string calculatePlannerBedtimesWrapper(const std::string& inputJson) {
    char* outputJson = nullptr;
    int32_t result = calculate_planner_bedtimes(inputJson.c_str(), &outputJson);
    if (result != SLEEP_CORE_OK) {
        throw std::runtime_error("Planner calculation failed");
    }
    std::string output(outputJson);
    free_string(outputJson);
    return output;
}

EMSCRIPTEN_BINDINGS(sleepcore) {
    function("calculateSqi", &calculateSqiWrapper);
    function("calculatePlannerBedtimes", &calculatePlannerBedtimesWrapper);
}
```

### 2. Build Command

```bash
emcmake cmake -B build_wasm -DCMAKE_BUILD_TYPE=Release
cmake --build build_wasm --config Release
# Outputs: sleepcore_wasm.wasm, sleepcore_wasm.js
```

### 3. Flutter Web Integration

```dart
// lib/core/native/sleep_core_wasm.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSPromise calculateSqi(JSString inputJson);

@JS()
external JSPromise calculatePlannerBedtimes(JSString inputJson);

class SleepCoreWASM {
  static Future<String> load() async {
    // Load the generated .js file
    await _loadScript('assets/sleepcore_wasm.js');
  }

  static Future<Map<String, dynamic>> calculateSqi(Map<String, dynamic> input) async {
    final inputJson = jsonEncode(input);
    final result = await calculateSqi(inputJson.toJS).toDart;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> calculatePlannerBedtimes(Map<String, dynamic> input) async {
    final inputJson = jsonEncode(input);
    final result = await calculatePlannerBedtimes(inputJson.toJS).toDart;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }
}
```

### 4. Asset Loading and Deployment

| Aspect | Android | Web |
|--------|---------|-----|
| Artifact | `libsleepcore.so` (per ABI) | `sleepcore.wasm` + `.js` glue |
| Packaging | `jniLibs/` in AAR/APK | `assets/` in Flutter web build |
| Loading | `System.loadLibrary` / `DynamicLibrary.open` | `js_interop` + dynamic import |
| Updates | App update required | Can cache-bust via versioned URL |

**Web deployment considerations:**
- WASM file must be served with correct MIME type (`application/wasm`)
- Enable gzip/brotli compression
- Use `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` for SharedArrayBuffer (if threading needed)
- Flutter web renderer (CanvasKit/Skia) compatibility: WASM runs in same isolate

---

## Shared: Common Calculation Contract

### 1. Golden Reference Parity Tests

Both Android and Web implementations **must** pass the same golden reference tests:

```dart
// test/native_parity_test.dart (runs on both platforms)
group('Native Parity — SQI', () {
  for (final case in goldenCases) {
    test('case ${case.id}', () async {
      final nativeResult = await adapter.calculateSqi(case.input);
      expect(nativeResult, case.expectedOutput);
    });
  }
});
```

**CI Pipeline:**
```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Dart Unit  │   │ Android FFI │   │  Web WASM   │
│  Tests      │   │  Tests      │   │  Tests      │
│  (current)  │   │  (emulator) │   │  (headless) │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         ▼
              ┌─────────────────────┐
              │  Golden Reference   │
              │  Parity Gate        │
              └─────────────────────┘
```

### 2. Error Handling

| Platform | Error Mechanism |
|----------|-----------------|
| Dart (current) | Exceptions / Result types |
| Android FFI | Return code + optional error message in output JSON |
| Web WASM | JS exceptions (caught by `try/catch` in Dart) |

### 3. Algorithm Versioning

Every native response includes `algorithmVersion`. Dart adapter validates:

```dart
class EngineAdapter {
  static const _expectedSqiVersion = '1.0.0';

  Future<SqiResult> calculateSqi(Responses input) async {
    final result = await _native.calculateSqi(input);
    if (result.algorithmVersion != _expectedSqiVersion) {
      _logger.w('Algorithm version mismatch: expected $_expectedSqiVersion, got ${result.algorithmVersion}');
      // Fall back to Dart implementation
      return CalculateSqi().call(responses: input.toMap());
    }
    return result;
  }
}
```

---

## What This Architecture Does NOT Assume

- ❌ Binary ABI stability across versions (using JSON)
- ❌ Zero-copy / shared memory (data sizes are tiny)
- ❌ Real-time / audio-thread constraints
- ❌ Background isolate execution (Dart handles this)
- ❌ Single artifact for Android + Web (separate builds required)

---

## Readiness Checklist

Before claiming platform readiness, verify:

- [ ] C++ core compiles cleanly for `arm64-v8a`, `armeabi-v7a`, `x86_64`
- [ ] C++ core compiles to WASM with Emscripten 3.1+
- [ ] FFI adapter loads `.so` and calls functions without crashes
- [ ] WASM module loads in Chrome/Firefox/Safari (Flutter web)
- [ ] All golden reference tests pass on Dart, Android emulator, Web headless
- [ ] Error handling tested: invalid input, OOM, malformed JSON
- [ ] Performance benchmarked: < 1ms per call on low-end device
- [ ] Binary size acceptable: < 200KB `.so`, < 100KB `.wasm.gz`
- [ ] No undefined behavior (sanitizers clean)
- [ ] Thread safety verified (if multi-threaded access possible)

---

## Current Status

| Component | Status |
|-----------|--------|
| Dart domain use cases | ✅ Implemented & tested |
| Golden reference dataset | ✅ 28 cases, all passing |
| Calculation contract | ✅ Documented |
| Migration decision | ✅ KEEP IN DART |
| Android FFI adapter | 📝 Designed only |
| Web WASM adapter | 📝 Designed only |
| C++ core implementation | ❌ Not started |
| CI parity pipeline | ❌ Not configured |

**Do not claim platform readiness until all checklist items are verified.**