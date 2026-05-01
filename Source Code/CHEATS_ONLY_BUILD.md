# etaHEN Cheats-Only Build

This refactor keeps the cheat toolbox path and removes non-essential top-level build targets from the default CMake graph.

## Included
- `shellui` (toolbox UI and controller shortcut handling)
- `daemon` (toolbox activation and IPC used by cheat menu)
- Required libs: `libhijacker`, `libNineS`, `libelfldr`, `libSelfDecryptor`

## Build
```bash
cd "Source Code"
cmake --preset default
cmake --build --preset default
```

Expected payload:
- `bin/daemon.elf`

Use your existing payload chain to load `daemon.elf`; with `toolbox_auto_start=1`, it boots directly into the cheats toolbox.
