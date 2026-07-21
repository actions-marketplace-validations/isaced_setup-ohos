# setup-ohos

A GitHub Action to download and set up the OpenHarmony NDK cross-compilation environment, with optional [lycium](https://gitcode.com/OpenHarmonyPCDeveloper/lycium_plusplus) framework support.

## Features

- Downloads and caches the OpenHarmony SDK (native toolchain)
- Sets up `OHOS_SDK`, `OHOS_NDK_HOME`, and `PATH` environment variables
- Detects and exports the CMake toolchain file path (`ohos.toolchain.cmake`)
- Optionally installs the [lycium](https://gitcode.com/OpenHarmonyPCDeveloper/lycium_plusplus) cross-compilation framework
- Optionally installs build tools (minimal or full set)
- Pure shell implementation — zero dependencies, fully transparent

## Usage

### Minimal (SDK + environment only)

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
  - run: |
      cmake -B build \
        -DCMAKE_TOOLCHAIN_FILE=$OHOS_CMAKE_TOOLCHAIN \
        -DOHOS_ARCH=arm64-v8a
      cmake --build build
```

### With lycium framework

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
    with:
      lycium: true
      tools: full
  - run: |
      cd $LYCIUM_HOME/lycium
      ./build.sh curl
```

### With SDK caching (recommended for frequent builds)

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: actions/cache@v4
    with:
      path: ${{ runner.temp }}/ohos-sdk
      key: ohos-sdk-6.0-Release
  - uses: isaced/setup-ohos@v1
    with:
      sdk-version: '6.0-Release'
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `sdk-version` | OpenHarmony SDK version | `6.0-Release` |
| `sdk-url` | Custom SDK download URL (overrides default mirror) | `''` |
| `lycium` | Clone and set up lycium framework | `false` |
| `lycium-repo` | lycium git repository URL | `https://gitcode.com/OpenHarmonyPCDeveloper/lycium_plusplus.git` |
| `lycium-ref` | lycium git ref (branch/tag/commit) | `''` (default branch) |
| `tools` | Tool installation level: `none`, `minimal`, `full` | `minimal` |

## Outputs

| Output | Description |
|--------|-------------|
| `ohos-sdk` | Path to OHOS SDK (parent of `native/`) |
| `ohos-native` | Path to OHOS SDK native directory |
| `ohos-cmake-toolchain` | Path to `ohos.toolchain.cmake` |
| `lycium-home` | Path to lycium framework root (empty if `lycium=false`) |

## Environment Variables

After this action runs, the following environment variables are available in subsequent steps:

| Variable | Description |
|----------|-------------|
| `OHOS_SDK` | SDK path (parent of `native/`, lycium convention) |
| `OHOS_NDK_HOME` | Path to `native/` directory |
| `OHOS_CMAKE_TOOLCHAIN` | Path to CMake toolchain file |
| `LYCIUM_BUILD_CHECK` | Set to `false` (skip device tests in CI) |
| `LYCIUM_HOME` | lycium root directory (only if `lycium=true`) |

## Tool Levels

- **`minimal`** — Tools required by lycium's `checkbuildenv()`: gcc, g++, cmake, make, ninja, pkg-config, autoconf, automake, patch, unzip, curl, wget, git
- **`full`** — Docker-equivalent environment covering 349+ thirdparty libraries: adds libtool, gperf, flex, bison, yasm, nasm, python3, meson, gettext, texinfo, and more
- **`none`** — Skip tool installation entirely

## License

MIT
