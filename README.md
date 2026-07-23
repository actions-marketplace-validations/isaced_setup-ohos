# setup-ohos

A GitHub Action to download and set up the OpenHarmony NDK cross-compilation environment, with optional [lycium](https://gitcode.com/openharmony-sig/tpc_c_cplusplus) framework support.

It handles SDK download/extraction, environment variable setup, PATH configuration, and optional installation of the lycium cross-compilation framework — so your workflow can go straight to `cmake` or `./build.sh <package>`.

## Features

- Downloads and caches the OpenHarmony SDK (native toolchain)
- Sets up `OHOS_SDK`, `OHOS_NDK_HOME`, `OHOS_CMAKE_TOOLCHAIN`, and `PATH` environment variables
- Detects and exports the CMake toolchain file path (`ohos.toolchain.cmake`)
- Optionally clones and sets up the [lycium](https://gitcode.com/openharmony-sig/tpc_c_cplusplus) cross-compilation framework
- Optionally installs build tools (`minimal`, `full`, or `none`)
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

### Pin a specific SDK version

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
    with:
      sdk-version: '5.0-Release'
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

Place `actions/cache` **before** `setup-ohos` so the action can skip re-downloading on cache hit.

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

### Cross-compile a bundled third-party library

lycium ships 348 third-party libraries with pre-written `HPKBUILD` recipes under `$LYCIUM_HOME/thirdparty/`. Pass the directory name to `build.sh`:

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
    with:
      sdk-version: '6.0-Release'
      lycium: true
      tools: minimal
  - run: |
      cd $LYCIUM_HOME/lycium
      ./build.sh cJSON
  - run: |
      find $LYCIUM_HOME/lycium/usr/cJSON -type f
      test -f "$LYCIUM_HOME/lycium/usr/cJSON/arm64-v8a/lib/libcjson.a"
      test -f "$LYCIUM_HOME/lycium/usr/cJSON/arm64-v8a/include/cjson/cJSON.h"
```

### Cross-compile a custom package

To build a package that is **not** in lycium's `thirdparty/`, write a `HPKBUILD` recipe and place it under `$LYCIUM_HOME/thirdparty/<your-pkg>/`. See lycium's [HPKBUILD template](https://gitcode.com/openharmony-sig/tpc_c_cplusplus/blob/master/lycium/template/HPKBUILD) for the format. Once the recipe is in place, `./build.sh <your-pkg>` works the same as for bundled packages.

### Use step outputs instead of env vars

```yaml
steps:
  - uses: actions/checkout@v4
  - id: ohos
    uses: isaced/setup-ohos@v1
  - run: |
      echo "SDK: ${{ steps.ohos.outputs.ohos-sdk }}"
      echo "Native: ${{ steps.ohos.outputs.ohos-native }}"
      echo "Toolchain: ${{ steps.ohos.outputs.ohos-cmake-toolchain }}"
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `sdk-version` | OpenHarmony SDK version (e.g. `5.0-Release`, `6.0-Release`) | `6.0-Release` |
| `sdk-url` | Custom SDK download URL (overrides default Huawei Cloud mirror) | `''` |
| `lycium` | Clone and set up lycium framework | `false` |
| `lycium-repo` | lycium git repository URL | `https://gitcode.com/openharmony-sig/tpc_c_cplusplus.git` |
| `lycium-ref` | lycium git ref (branch/tag/commit) | `''` (default branch) |
| `tools` | Tool installation level: `none`, `minimal`, `full` | `minimal` |

## Outputs

| Output | Description |
|--------|-------------|
| `ohos-sdk` | Path to OHOS SDK (parent of `native/`, i.e. the `linux/` directory) |
| `ohos-native` | Path to OHOS SDK native directory |
| `ohos-cmake-toolchain` | Path to `ohos.toolchain.cmake` for CMake cross-compilation |
| `lycium-home` | Path to lycium framework root (empty if `lycium=false`) |

## Environment Variables

After this action runs, the following variables are available in subsequent steps:

| Variable | Description |
|----------|-------------|
| `OHOS_SDK` | SDK path (parent of `native/`, lycium convention) |
| `OHOS_NDK_HOME` | Path to `native/` directory |
| `OHOS_CMAKE_TOOLCHAIN` | Path to CMake toolchain file |
| `LYCIUM_BUILD_CHECK` | Set to `false` (skip device tests in CI) |
| `LYCIUM_HOME` | lycium root directory (only if `lycium=true`) |

The toolchain binaries (`llvm/bin`) and the SDK's bundled CMake (`build-tools/cmake/bin`) are also prepended to `PATH`.

## Tool Levels

- **`minimal`** — Tools required by lycium's `checkbuildenv()`: gcc, g++, cmake, make, ninja, pkg-config, autoconf, automake, patch, unzip, curl, wget, git
- **`full`** — Docker-equivalent environment covering all 348 lycium thirdparty libraries: adds libtool, gperf, flex, bison, yasm, nasm, python3, meson, gettext, texinfo, and more
- **`none`** — Skip tool installation entirely (use when you only need the SDK and have your own toolchain)

## How It Works

The action runs as a composite action with the following steps:

1. **Install build tools** (if `tools != 'none'`) — `apt-get install` the selected tool set
2. **Cache OHOS SDK** — `actions/cache@v4` on `${{ runner.temp }}/ohos-sdk`, keyed by SDK version
3. **Download and extract SDK** — `wget` + `tar` from Huawei Cloud (or `sdk-url`), extracts the `linux/native/` toolchain
4. **Set up environment** — exports `OHOS_SDK`, `OHOS_NDK_HOME`, `OHOS_CMAKE_TOOLCHAIN`, updates `PATH`
5. **Set up lycium** (if `lycium == 'true'`) — clones the [`tpc_c_cplusplus`](https://gitcode.com/openharmony-sig/tpc_c_cplusplus) repository into `$LYCIUM_HOME`. The repo includes both the lycium framework (`lycium/build.sh`) and 348 third-party package recipes (`thirdparty/<pkg>/HPKBUILD`).

After setup, the directory layout is:

```
$LYCIUM_HOME/
├── lycium/          # lycium framework (build.sh, script/, template/)
│   ├── build.sh
│   └── usr/         # build output (automatically created)
└── thirdparty/      # 348 third-party library recipes
    ├── curl/HPKBUILD
    ├── cJSON/HPKBUILD
    └── ...
```

All scripts live under [`scripts/`](./scripts) and are plain bash — no Node.js runtime, no hidden dependencies.

## Supported SDK Versions

Tested against the following OpenHarmony SDK releases:

| Version | Status |
|---------|--------|
| `6.0-Release` | ✅ Tested |
| `5.0-Release` | ✅ Tested |

Other versions available on the [Huawei Cloud mirror](https://repo.huaweicloud.com/openharmony/os/) should work as long as the SDK archive layout matches (`linux/native/` with `llvm/bin/` and a `ohos.toolchain.cmake`).

## Limitations

- **Linux runners only.** The action removes the Windows SDK portion and relies on `apt-get` for tool installation. Use `runs-on: ubuntu-latest`.
- **No automatic device testing.** `LYCIUM_BUILD_CHECK` is set to `false` by default since CI runners are not OpenHarmony devices. Override this variable in a later step if you have a connected device.
- **SDK layout assumptions.** The action expects `$SDK_PATH/native/llvm/bin/` and a `ohos.toolchain.cmake` under `native/build/cmake/` or `native/build-tools/cmake/share/`. Non-standard SDK layouts will fail the verification step.

## License

MIT
