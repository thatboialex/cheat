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
- Legacy release binaries and historical “old versions” archives.
- Non-build technical writeup/doc folders unrelated to the cheat toolbox build.
- Stale duplicated README/build docs that described broad AIO etaHEN behavior.

The active CMake graph already excludes several former top-level modules (`bootstrapper`, `fps_elf`, `unpacker`, `util`, `libNidResolver`) and keeps only cheat-related runtime targets.

## Repository structure
- `Source Code/CMakeLists.txt` — root CMake graph for this repo’s active build targets.
- `Source Code/CMakePresets.json` — preset-based configure/build definitions (Windows and non-Windows host variants).
- `Source Code/daemon/` — daemon ELF target and runtime-side IPC/cheat operations.
- `Source Code/shellui/` — cheat toolbox UI hooks, menu generation, and controller shortcut handling.
- `Source Code/libhijacker/` — process/runtime helper library used by active targets.
- `Source Code/libNineS/` — support library retained by active build graph.
- `Source Code/libelfldr/` — ELF loader support library used by daemon path.
- `Source Code/libSelfDecryptor/` — decryptor support library linked by active targets.
- `Source Code/include/` and module-local `include/` folders — headers used by retained components.
- `Source Code/lib/` — SDK/system/static library inputs expected by this project.
- `LICENSE` — project license.

## Prerequisites
You need a PS5 payload SDK environment compatible with this project’s toolchain file usage.

Required:
- `cmake` (3.20+).
- `ninja` generator.
- `clang` / `clang++` (or `clang.exe` / `clang++.exe` on Windows).
- A valid `PS5SDK` environment variable pointing to an SDK root that provides:
  - `cmake/toolchain-ps5.cmake`
- A valid `PS5_PAYLOAD_SDK` environment variable used by this project’s includes.

Notes:
- `Source Code/CMakePresets.json` references `${env:PS5SDK}/cmake/toolchain-ps5.cmake`.
- `Source Code/CMakeLists.txt` includes `${PS5_PAYLOAD_SDK}` and `${PS5_PAYLOAD_SDK}/include`.

## Step-by-step ELF build guide
From a fresh clone:

1. Clone and enter the repo
   ```bash
   git clone <your-fork-or-repo-url>
   cd cheat
   cd "Source Code"
   ```

2. Export required environment variables (example names/paths)
   ```bash
   export PS5SDK=/path/to/ps5sdk
   export PS5_PAYLOAD_SDK=/path/to/ps5-payload-sdk
   ```

3. Configure (non-Windows host)
   ```bash
   cmake --preset nix-base
   ```
   On Windows, use:
   ```powershell
   cmake --preset ps5-base
   ```

4. Clean build directory (recommended for reproducibility)
   ```bash
   cmake --build --preset default-build-nix --target clean
   ```
   On Windows:
   ```powershell
   cmake --build --preset default-build-windows --target clean
   ```

5. Build
   ```bash
   cmake --build --preset default-build-nix
   ```
   On Windows:
   ```powershell
   cmake --build --preset default-build-windows
   ```

6. Expected ELF output
   - Primary payload output:
     - `Source Code/bin/daemon.elf`

7. Verify ELF exists
   ```bash
   test -f bin/daemon.elf && echo "daemon.elf built"
   ```

### Troubleshooting
- **Preset configure fails with missing toolchain file**: verify `PS5SDK` points to a valid SDK root containing `cmake/toolchain-ps5.cmake`.
- **Missing SDK headers/libraries at compile/link time**: verify `PS5_PAYLOAD_SDK` and local SDK library layout expected by `Source Code/lib/`.
- **Preset mismatch on host OS**: use `nix-base/default-build-nix` on Linux/macOS and `ps5-base/default-build-windows` on Windows.

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
The repository includes a CI workflow at `.github/workflows/build-elf.yml` that builds the cheat-toolbox payload ELF on GitHub Actions.

### Triggers
- Push to `main` or `master`
- Pull requests targeting `main` or `master`
- Manual run via `workflow_dispatch`

### What the workflow does
1. Checks out the repo (with submodules).
2. Installs minimal Linux build dependencies (`cmake`, `ninja-build`, `clang`, `llvm`, `file`, `build-essential`, `git`).
3. Clones the open SDK from `https://github.com/ps5-payload-dev/sdk` into `$RUNNER_TEMP/ps5sdk`.
4. Exports both `PS5SDK` and `PS5_PAYLOAD_SDK` to that cloned path for this build.
5. Validates SDK/toolchain files exist.
6. Configures CMake with Ninja using the PS5 toolchain file.
7. Runs clean + build.
8. Verifies ELF output exists and prints `ls -lh`, `file`, and `sha256sum` output.
9. Uploads ELF artifacts as `cheat-toolbox-elf`.

### SDK variables in CI
No repository secret/variable is required for SDK paths in default CI mode: the workflow fetches the SDK directly each run and sets:
- `PS5SDK=$RUNNER_TEMP/ps5sdk`
- `PS5_PAYLOAD_SDK=$RUNNER_TEMP/ps5sdk`

If you later switch to self-hosted runners and preinstalled SDK paths, update those values accordingly.

### Artifact output
- Uploaded artifact name: `cheat-toolbox-elf`
- Expected path in build workspace: `Source Code/bin/*.elf`
- Primary expected file: `Source Code/bin/daemon.elf`

### Reproduce CI locally (Linux)
From repository root:
```bash
cd "Source Code"
SDK_DIR="$(mktemp -d)/ps5sdk"
git clone --depth=1 https://github.com/ps5-payload-dev/sdk.git "$SDK_DIR"
export PS5SDK="$SDK_DIR"
export PS5_PAYLOAD_SDK="$SDK_DIR"
cmake -S . -B build/ci -G Ninja   -DCMAKE_TOOLCHAIN_FILE="$PS5SDK/cmake/toolchain-ps5.cmake"   -DCMAKE_C_COMPILER=clang   -DCMAKE_CXX_COMPILER=clang++
cmake --build build/ci --target clean
cmake --build build/ci --verbose
ls -lh bin
file bin/*.elf
sha256sum bin/*.elf
```

### Troubleshooting
- **SDK clone fails**: check GitHub network access/rate limits and retry.
- **Missing toolchain file**: ensure SDK clone succeeded and contains `cmake/toolchain-ps5.cmake`.
- **Missing compiler**: ensure `clang` and `clang++` are installed and on `PATH`.
- **ELF not found**: check build logs for link failures and verify output under `Source Code/bin/`.
- **Permission denied on scripts**: if custom scripts are introduced later, ensure executable permissions are committed (`chmod +x`).
