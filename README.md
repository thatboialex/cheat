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

6. Build (also adds `${PS5_PAYLOAD_SDK}/bin` to `PATH` so clang can call `prospero-lld` for the `x86_64-sie-ps5` target)
   ```bash
   export PATH="$PS5_PAYLOAD_SDK/bin:$PATH"
   cmake --build "$BUILD_DIR" --target daemon --config Release --verbose
   ```

7. PS5-loadable output
   - **The PS5-loadable payload is `ci-src/bin/daemon.elf`.** This is the file you send to your PS5 payload loader (e.g. `ps5-payload-elfldr`).
   - It is a real PIE executable for `x86_64-sie-ps5` with a valid `_start` (provided by the SDK's `crt1.o`); ELF program loaders will boot it directly into the cheat toolbox flow, which then injects the embedded `shellui.elf` into `SceShellUI`.
   - `ci-src/daemon/assets/shellui.elf` is **not** a standalone payload. It has no `_start` and is consumed only as an `.incbin` payload baked into `daemon.elf` for the in-process `libNineS` injector. Do **not** send it to a PS5 payload loader directly.

8. Verify the payload ELF
   ```bash
   test -f ci-src/bin/daemon.elf && echo "daemon.elf built"
   file ci-src/bin/daemon.elf                           # expect "ELF 64-bit LSB pie executable, x86-64"
   llvm-readelf -h ci-src/bin/daemon.elf | grep "Entry" # expect a non-zero entry point
   sha256sum ci-src/bin/daemon.elf
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

### Which file do I send to the PS5?

Send **`cheat-toolbox.elf`** (a copy of `daemon.elf`) to your PS5 payload loader. That is the only file you need.

If you build via GitHub Actions, download the `cheat-toolbox-ps5-elf` artifact (always delivered as a `.zip` by GitHub) and unzip it. The zip contains:

```
cheat-toolbox.elf            <- send this
cheat-toolbox.elf.sha256     <- integrity hash, do not send
cheat-toolbox.elf.file.txt   <- `file` output, do not send
cheat-toolbox.elf.readelf.txt <- ELF header dump, do not send
```

Do **not** send any of the following to the PS5:

- the `.zip` file itself,
- `cheat-toolbox.elf.sha256`, `cheat-toolbox.elf.file.txt`, or `cheat-toolbox.elf.readelf.txt`,
- `shellui.elf` (this is a payload embedded *inside* `cheat-toolbox.elf`; sending it standalone will not work because it has no `_start` entry),
- any `.elf` from `build/ps5-release/CMakeFiles/`,
- the empty placeholder ELFs under `daemon/assets/` (`ps5debug.elf`, `fps_elf.elf`, `ps5-app-dumper.elf`).

`cheat-toolbox.elf` is a real `x86_64-sie-ps5` PIE executable with `_start` provided by the SDK's `crt1.o`. When loaded it opens the cheat toolbox IPC services and injects the embedded `shellui.elf` into `SceShellUI` to drive the menu.

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
2. Installs host build dependencies (`cmake`, `ninja-build`, `clang-18`, `lld-18`, `llvm-18`, `libc++-18-dev`, `libc++abi-18-dev`, `libunwind-18-dev`, `file`, `build-essential`, `wget`, `rsync`, `python3`).
3. Clones the public PS5 payload SDK from `https://github.com/ps5-payload-dev/sdk` into `external/ps5-payload-sdk`.
4. Restores or builds and installs the SDK target tree (`make -C "$PS5_PAYLOAD_SDK" DESTDIR="$PS5_PAYLOAD_SDK" install`) and `libcxx.sh`. The `target/`, `bin/`, `ldscripts/`, and `toolchain/` directories are cached across runs to avoid the ~10 minute libcxx rebuild.
5. Verifies that `string.h`, `stdlib.h`, `elf.h`, and `c++/v1/cstdint` are present under the SDK sysroot before configuring.
6. Copies `Source Code/` into a no-space CI worktree at `ci-src/` before configuring to avoid linker-script path splitting on `-T.../linker.x`.
7. Configures with the in-tree toolchain file and explicit `-DPS5_PAYLOAD_SDK="$GITHUB_WORKSPACE/external/ps5-payload-sdk"`.
8. Builds the cheat toolbox target with `cmake --build "$BUILD_DIR" --target daemon --config Release --verbose`.
9. Stages the produced `daemon.elf` as `artifacts/cheat-toolbox.elf`, validates that:
   - the file is an `ELF 64-bit LSB pie executable`,
   - its size is at least 64 KiB,
   - and its `e_entry` is non-zero (the previous broken artifact had `e_entry=0` because `crt1.o` was not linked),
   then writes companion `cheat-toolbox.elf.sha256`, `cheat-toolbox.elf.file.txt`, and `cheat-toolbox.elf.readelf.txt` next to the ELF.
10. Uploads the staged `artifacts/` directory as the `cheat-toolbox-ps5-elf` artifact.

### Required repository variables
No repository variables are required for GitHub-hosted runners.

CI always clones the SDK into `external/ps5-payload-sdk` and sets:
- `PS5_PAYLOAD_SDK=$GITHUB_WORKSPACE/external/ps5-payload-sdk`

For self-hosted runners, ensure outbound Git access to `https://github.com/ps5-payload-dev/sdk` and the LLVM source tarball download referenced by `libcxx.sh`.

### Artifact output
- Uploaded artifact name: **`cheat-toolbox-ps5-elf`**.
- GitHub Actions always serves artifacts as `.zip` (this is normal).
- After downloading and unzipping, you get:
  - `cheat-toolbox.elf` — the PS5-loadable payload. **This is the file you send to your PS5 payload loader.**
  - `cheat-toolbox.elf.sha256`, `cheat-toolbox.elf.file.txt`, `cheat-toolbox.elf.readelf.txt` — metadata only.
- Source path inside the build tree: `ci-src/bin/daemon.elf`. The CI step copies it to `artifacts/cheat-toolbox.elf` and uploads only that staged directory; intermediate / library / placeholder ELFs are not included in the artifact.

#### Artifact troubleshooting
- **"The artifact downloads as a `.zip`"** — This is normal. GitHub always packages workflow artifacts as zip. Unzip and use `cheat-toolbox.elf`.
- **"There is no `.elf` inside the artifact"** — The CI staging step failed; check the workflow run for the "Stage and validate cheat-toolbox.elf artifact" step.
- **"The ELF does not load on my PS5"** — Verify it is the unzipped `cheat-toolbox.elf` (not the zip, not `shellui.elf`, not a placeholder). Run `file cheat-toolbox.elf` (expect `ELF 64-bit LSB pie executable, x86-64`) and `llvm-readelf -h cheat-toolbox.elf | grep Entry` (expect a non-zero entry point).
- **"Multiple `.elf` files were produced"** — Use the staged `cheat-toolbox.elf`. The repo also produces an etaHEN-format `shellui.elf` that is *only* a payload baked into `cheat-toolbox.elf`; it is not standalone-loadable.

### Reproduce CI locally (Linux)
From repository root:
```bash
set -euo pipefail
REPO_ROOT="$PWD"
SOURCE_DIR="$REPO_ROOT/ci-src"
BUILD_DIR="$REPO_ROOT/build/ps5-release"
SDK_DIR="$REPO_ROOT/external/ps5-payload-sdk"

mkdir -p "$REPO_ROOT/external"
if [ ! -d "$SDK_DIR/.git" ]; then
  git clone --depth 1 --recurse-submodules \
    https://github.com/ps5-payload-dev/sdk "$SDK_DIR"
fi
export PS5_PAYLOAD_SDK="$SDK_DIR"

make -C "$SDK_DIR" DESTDIR="$SDK_DIR" install || true
"$SDK_DIR/libcxx.sh"

rm -rf "$SOURCE_DIR" "$BUILD_DIR"
rsync -a --delete "$REPO_ROOT/Source Code/" "$SOURCE_DIR/"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="$SOURCE_DIR/stubber/toolchain.cmake" \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DPS5_PAYLOAD_SDK="$PS5_PAYLOAD_SDK"

cmake --build "$BUILD_DIR" --target daemon --config Release --verbose

find "$BUILD_DIR" "$SOURCE_DIR" -type f \
  \( -name "*.elf" -o -name "*.ELF" \) -print
```

### Troubleshooting
- **Missing SDK**: ensure `PS5_PAYLOAD_SDK` points to the SDK root cloned from `https://github.com/ps5-payload-dev/sdk` and that `make install` has been run inside it.
- **Missing compiler**: ensure `clang-18` (or compatible) and matching `lld-18`, `llvm-config-18`, and `libc++-18-dev` are installed and on `PATH`.
- **`fatal error: 'string.h' / 'stdlib.h' / 'elf.h' file not found`**: see the build-section troubleshooting note above; the SDK install step has not been completed.
- **`fatal error: 'cstdint' file not found`**: `libcxx.sh` has not been run; re-run it.
- **ELF not found**: check build logs for link failures and verify output under `ci-src/bin/` or `build/ps5-release`.
