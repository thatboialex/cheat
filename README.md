# etaHEN Cheats-Only Toolbox (ELF Build)

## Overview
This repository is a stripped-down **cheat-only** derivative of the original etaHEN project.

Only the components required to build and run the cheats toolbox flow are retained. Unrelated etaHEN functionality (game loaders, non-cheat utility payload features, and broad AIO menus) has been removed from the active build graph and top-level docs.

The produced payload ELF is intended to start the daemon/toolbox path used by the cheat workflow; with toolbox auto-start enabled in config, it enters the cheats toolbox experience directly.

## Features
- Cheat toolbox/menu UI integration.
- Cheat list retrieval, cheat toggling, and cheat state handling.
- Controller-driven toolbox navigation.
- Configurable controller shortcuts for opening cheats/toolbox actions.
- Minimal active CMake target graph focused on cheat runtime components.
- PS5 payload ELF output for jailbroken homebrew-capable systems.

## What was removed
This repo cleanup removes or de-emphasizes legacy ETAHEN artifacts that are not part of the current cheat-only build path, including:
- Legacy release binaries and historical "old versions" archives.
- Non-build technical writeup/doc folders unrelated to the cheat toolbox build.
- Stale duplicated README/build docs that described broad AIO etaHEN behavior.

The active CMake graph already excludes several former top-level modules (`bootstrapper`, `fps_elf`, `unpacker`, `util`) and keeps only cheat-related runtime targets.

## Repository structure
- `Source Code/CMakeLists.txt` — root CMake graph for this repo's active build targets.
- `Source Code/CMakePresets.json` — preset-based configure/build definitions (Windows and non-Windows host variants).
- `Source Code/daemon/` — daemon ELF target and runtime-side IPC/cheat operations.
- `Source Code/shellui/` — cheat toolbox UI hooks, menu generation, and controller shortcut handling.
- `Source Code/libhijacker/` — process/runtime helper library used by active targets.
- `Source Code/libNidResolver/` — NID resolver used by libhijacker.
- `Source Code/libNineS/` — support library retained by active build graph.
- `Source Code/libelfldr/` — ELF loader support library used by daemon path.
- `Source Code/libSelfDecryptor/` — decryptor support library linked by active targets.
- `Source Code/include/` and module-local `include/` folders — headers used by retained components.
- `Source Code/lib/` — SDK/system/static library inputs expected by this project.
- `Source Code/stubber/toolchain.cmake` — CMake cross toolchain that points the build at the installed PS5 payload SDK target tree.
- `Source Code/linker.x` — linker script used to lay out the PS5 payload ELF.
- `LICENSE` — project license.

## Prerequisites
You need a built/installed PS5 payload SDK target tree that this project's toolchain file can use as a sysroot.

Required:
- `cmake` (3.20+).
- `ninja` generator.
- `clang-18` / `clang++-18` (or equivalent clang ≥ 18) with matching `lld-18` and `llvm-config-18`.
- `libc++-18-dev`, `libc++abi-18-dev`, `libunwind-18-dev` (only the `wget`+`make` step that builds libcxx for the PS5 target needs them on the host).
- `wget`, `python3`, `make`, `git`, `rsync`.
- The [ps5-payload-dev/sdk](https://github.com/ps5-payload-dev/sdk) checkout, **built and installed**, exported as `PS5_PAYLOAD_SDK`.

After installing, the SDK target tree is laid out as:

```
${PS5_PAYLOAD_SDK}/
├── bin/                   # prospero-* host wrappers
├── ldscripts/             # PS5 link scripts
├── toolchain/             # prospero.cmake / prospero.mk / prospero.sh
└── target/
    ├── include/           # libc / FreeBSD / PS5 system headers
    │   └── c++/v1/        # libc++ headers (after running libcxx.sh)
    └── lib/               # libc.a, crt1.o, libSce*.so, libc++.a, libunwind.a
```

The toolchain file `Source Code/stubber/toolchain.cmake` sets:
- `CMAKE_SYSROOT  = ${PS5_PAYLOAD_SDK}/target`
- `CMAKE_<LANG>_STANDARD_INCLUDE_DIRECTORIES = ${PS5_PAYLOAD_SDK}/target/include[/c++/v1]`
- `CMAKE_<LANG>_COMPILER_TARGET = x86_64-sie-ps5`
- linker `-L ${PS5_PAYLOAD_SDK}/target/lib` and the project's `linker.x`.

## Step-by-step ELF build guide
From a fresh clone:

1. Clone and enter the repo
   ```bash
   git clone <your-fork-or-repo-url> cheat
   cd cheat
   ```

2. Install host prerequisites (Debian/Ubuntu)
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
     cmake ninja-build \
     clang-18 lld-18 llvm-18 llvm-18-dev \
     libc++-18-dev libc++abi-18-dev libunwind-18-dev \
     file build-essential git ca-certificates wget rsync python3
   ```

3. Clone and install the PS5 payload SDK
   ```bash
   mkdir -p external
   git clone --depth 1 --recurse-submodules \
     https://github.com/ps5-payload-dev/sdk external/ps5-payload-sdk
   export PS5_PAYLOAD_SDK="$PWD/external/ps5-payload-sdk"

   # Builds crt, sce_stubs, libc, libufs and installs target/include + target/lib.
   make -C "$PS5_PAYLOAD_SDK" DESTDIR="$PS5_PAYLOAD_SDK" install || true

   # Downloads llvm-project source and builds libc++/libc++abi/libunwind for
   # x86_64-sie-ps5. Required so <cstdint>, <string>, etc. are available.
   "$PS5_PAYLOAD_SDK/libcxx.sh"
   ```

4. Prepare a no-space source mirror (matches CI; avoids linker-script path splitting on `-T.../linker.x`)
   ```bash
   SOURCE_DIR="$PWD/ci-src"
   rsync -a --delete "$PWD/Source Code/" "$SOURCE_DIR/"
   ```

5. Configure
   ```bash
   BUILD_DIR="$PWD/build/ps5-release"
   cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_TOOLCHAIN_FILE="$SOURCE_DIR/stubber/toolchain.cmake" \
     -DCMAKE_C_COMPILER=clang \
     -DCMAKE_CXX_COMPILER=clang++ \
     -DPS5_PAYLOAD_SDK="$PS5_PAYLOAD_SDK"
   ```

6. Build
   ```bash
   cmake --build "$BUILD_DIR" --target daemon --config Release --verbose
   ```

7. Expected ELF output
   - Primary payload output: `ci-src/bin/daemon.elf`

8. Verify ELF exists
   ```bash
   test -f ci-src/bin/daemon.elf && echo "daemon.elf built"
   file ci-src/bin/daemon.elf
   ```

### Troubleshooting
- **`fatal error: 'string.h' file not found`**, **`'stdlib.h' file not found`**, or **`'elf.h' file not found`**: the SDK target tree was not installed. Run `make -C "$PS5_PAYLOAD_SDK" DESTDIR="$PS5_PAYLOAD_SDK" install` and confirm `${PS5_PAYLOAD_SDK}/target/include/string.h` exists. The toolchain file aborts early with this hint if the headers are missing.
- **`fatal error: 'cstdint' file not found`** (or any `<...>` C++ standard header): libcxx is not installed for the PS5 target. Run `"$PS5_PAYLOAD_SDK/libcxx.sh"` and verify `${PS5_PAYLOAD_SDK}/target/include/c++/v1/cstdint` exists.
- **Configure aborts with `PS5_PAYLOAD_SDK is required`**: export `PS5_PAYLOAD_SDK` or pass `-DPS5_PAYLOAD_SDK=...` on the cmake command line.
- **`PS5 SDK target headers not found at ...`**: same root cause as the missing-`string.h` case — the SDK Makefile install step has not been run.
- **`The dependency target "NidResolver" of target "hijacker" does not exist`**: ensure the top-level CMake graph includes `add_subdirectory(libNidResolver)` before `add_subdirectory(libhijacker)`.
- **Linker errors about missing `crt1.o` or `libSce*`**: the SDK install step is incomplete; re-run the SDK Makefile install.

## Controller mappings
Controller shortcut modes are configurable in the toolbox settings and persisted via config keys.

Current shortcut options exposed by the toolbox UI:
- **Open Cheats Menu**:
  - OFF
  - Hold `R3 + L3`
  - Hold `L2 + Triangle`
  - Long-hold `Options`
  - Long-hold `Share`
  - Single-tap `Share`
- **Open Cheats Toolbox**:
  - OFF
  - Hold `L2 + R3`
  - Long-hold `Share`
  - Single-tap `Share`

Implementation details are defined in:
- `Source Code/shellui/assets/etaHEN_toolbox.xml` (user-facing option lists).
- `Source Code/shellui/src/HookFunctions.cpp` (button-combination and long/single-press handling logic).
- `Source Code/shellui/include/HookedFuncs.hpp` (shortcut enum/state definitions).

## Usage
Build output is intended for homebrew payload loading on compatible jailbroken PlayStation systems where you are authorized to run homebrew software.

This repository does **not** provide exploit or jailbreak instructions. Use only on systems you own/control and where such execution is legally and contractually permitted.

## Development notes
- Keep the project cheat-toolbox focused.
- Do not reintroduce unrelated AIO ETAHEN features into the active build graph.
- Keep runtime and dependency footprint minimal.
- When build paths, presets, or output artifacts change, update this README in the same PR.

## License / credits
- License is preserved in `LICENSE`.
- Original etaHEN and upstream community contributions remain attributed in project history.

## GitHub Actions CI (ELF build)
The repository includes a CI workflow at `.github/workflows/build-elf.yml` that builds and publishes a validated PS5 payload ELF for the cheats toolbox.

### Triggers
- Push to `main` or `master`
- Pull requests targeting `main` or `master`
- Manual run via `workflow_dispatch`

### Final target and artifact contract
- Final CMake target built in CI: `daemon`
- Final PS5-loadable ELF source path: `ci-src/bin/daemon.elf`
- Staged artifact ELF name: `artifacts/cheat-toolbox.elf`
- Uploaded artifact name: `cheat-toolbox-ps5-elf`

> GitHub Actions artifacts always download as a `.zip`. This is normal.
> Extract the zip and use **`cheat-toolbox.elf`**.

### What the workflow does
1. Checks out the repo (with submodules).
2. Installs host build dependencies (`cmake`, `ninja-build`, `clang-18`, `lld-18`, `llvm-18`, `libc++-18-dev`, `libc++abi-18-dev`, `libunwind-18-dev`, `file`, `build-essential`, `wget`, `rsync`, `python3`).
3. Clones the public PS5 payload SDK from `https://github.com/ps5-payload-dev/sdk` into `external/ps5-payload-sdk`.
4. Restores or builds and installs the SDK target tree and libcxx (`libcxx.sh`) with cache reuse.
5. Verifies required headers (`string.h`, `stdlib.h`, `elf.h`, `cstdint`).
6. Copies `Source Code/` into `ci-src/` (no-space path safety for linker script handling).
7. Configures CMake/Ninja with `stubber/toolchain.cmake`.
8. Builds the explicit final target: `cmake --build "$BUILD_DIR" --target daemon --config Release --verbose`.
9. Stages **only** the final ELF as `artifacts/cheat-toolbox.elf`.
10. Validates the staged ELF with:
   - `test -s`
   - `file` (must identify ELF)
   - size threshold check (must be >= 4096 bytes)
   - `sha256sum`
   - `llvm-readelf -h` (or `readelf -h` fallback)
11. Uploads only `artifacts/` as `cheat-toolbox-ps5-elf`.

### Artifact output
After downloading and extracting the GitHub artifact zip, expected files are:
- `cheat-toolbox.elf` (**this is the file to load via your existing payload/homebrew loader**)
- `cheat-toolbox.elf.sha256`
- `cheat-toolbox.elf.file.txt`
- `cheat-toolbox.elf.readelf.txt`
- `cheat-toolbox.elf.strings.txt` (informational)

Do **not** send/load:
- the zip itself,
- `.sha256` / `.txt` metadata,
- intermediate files from `build/`,
- static libraries (`.a`) or object files (`.o`).

### Reproduce CI locally (Linux)
From repository root:
```bash
set -euo pipefail
REPO_ROOT="$PWD"
SOURCE_DIR="$REPO_ROOT/ci-src"
BUILD_DIR="$REPO_ROOT/build/ps5-release"
SDK_DIR="$REPO_ROOT/external/ps5-payload-sdk"
ARTIFACT_DIR="$REPO_ROOT/artifacts"

mkdir -p "$REPO_ROOT/external"
if [ ! -d "$SDK_DIR/.git" ]; then
  git clone --depth 1 --recurse-submodules     https://github.com/ps5-payload-dev/sdk "$SDK_DIR"
fi
export PS5_PAYLOAD_SDK="$SDK_DIR"

make -C "$SDK_DIR" DESTDIR="$SDK_DIR" install || true
"$SDK_DIR/libcxx.sh"

rm -rf "$SOURCE_DIR" "$BUILD_DIR" "$ARTIFACT_DIR"
rsync -a --delete "$REPO_ROOT/Source Code/" "$SOURCE_DIR/"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja   -DCMAKE_BUILD_TYPE=Release   -DCMAKE_TOOLCHAIN_FILE="$SOURCE_DIR/stubber/toolchain.cmake"   -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++   -DPS5_PAYLOAD_SDK="$PS5_PAYLOAD_SDK"

cmake --build "$BUILD_DIR" --target daemon --config Release --verbose

mkdir -p "$ARTIFACT_DIR"
cp "$SOURCE_DIR/bin/daemon.elf" "$ARTIFACT_DIR/cheat-toolbox.elf"
test -s "$ARTIFACT_DIR/cheat-toolbox.elf"
file "$ARTIFACT_DIR/cheat-toolbox.elf"
sha256sum "$ARTIFACT_DIR/cheat-toolbox.elf"
llvm-readelf -h "$ARTIFACT_DIR/cheat-toolbox.elf" || readelf -h "$ARTIFACT_DIR/cheat-toolbox.elf"
```

### Troubleshooting
- **`fatal error: 'string.h' file not found`**, **`'stdlib.h' file not found`**, or **`'elf.h' file not found`**: the SDK target tree was not installed. Run `make -C "$PS5_PAYLOAD_SDK" DESTDIR="$PS5_PAYLOAD_SDK" install` and confirm `${PS5_PAYLOAD_SDK}/target/include/string.h` exists. The toolchain file aborts early with this hint if the headers are missing.
- **`fatal error: 'cstdint' file not found`** (or any `<...>` C++ standard header): libcxx is not installed for the PS5 target. Run `"$PS5_PAYLOAD_SDK/libcxx.sh"` and verify `${PS5_PAYLOAD_SDK}/target/include/c++/v1/cstdint` exists.
- **Configure aborts with `PS5_PAYLOAD_SDK is required`**: export `PS5_PAYLOAD_SDK` or pass `-DPS5_PAYLOAD_SDK=...` on the cmake command line.
- **`PS5 SDK target headers not found at ...`**: same root cause as the missing-`string.h` case — the SDK Makefile install step has not been run.
- **`The dependency target "NidResolver" of target "hijacker" does not exist`**: ensure the top-level CMake graph includes `add_subdirectory(libNidResolver)` before `add_subdirectory(libhijacker)`.
- **Linker errors about missing `crt1.o` or `libSce*`**: the SDK install step is incomplete; re-run the SDK Makefile install.

## Controller mappings
Controller shortcut modes are configurable in the toolbox settings and persisted via config keys.

Current shortcut options exposed by the toolbox UI:
- **Open Cheats Menu**:
  - OFF
  - Hold `R3 + L3`
  - Hold `L2 + Triangle`
  - Long-hold `Options`
  - Long-hold `Share`
  - Single-tap `Share`
- **Open Cheats Toolbox**:
  - OFF
  - Hold `L2 + R3`
  - Long-hold `Share`
  - Single-tap `Share`

Implementation details are defined in:
- `Source Code/shellui/assets/etaHEN_toolbox.xml` (user-facing option lists).
- `Source Code/shellui/src/HookFunctions.cpp` (button-combination and long/single-press handling logic).
- `Source Code/shellui/include/HookedFuncs.hpp` (shortcut enum/state definitions).

## Usage
Build output is intended for homebrew payload loading on compatible jailbroken PlayStation systems where you are authorized to run homebrew software.

This repository does **not** provide exploit or jailbreak instructions. Use only on systems you own/control and where such execution is legally and contractually permitted.

## Development notes
- Keep the project cheat-toolbox focused.
- Do not reintroduce unrelated AIO ETAHEN features into the active build graph.
- Keep runtime and dependency footprint minimal.
- When build paths, presets, or output artifacts change, update this README in the same PR.

## License / credits
- License is preserved in `LICENSE`.
- Original etaHEN and upstream community contributions remain attributed in project history.
