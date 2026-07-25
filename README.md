# setup-ohos

A GitHub Action to download and set up the OpenHarmony NDK cross-compilation environment, with optional [lycium](https://gitcode.com/CPF-ApplicationTPC/tpc_c_cplusplus) support.

It handles SDK download/extraction, environment variable setup, PATH configuration, and optional setup of lycium, so your workflow can go straight to `cmake` or `./build.sh <package>`.

> **What does `lycium: true` include?** The action shallow-clones the complete upstream
> `tpc_c_cplusplus` repository into `$LYCIUM_HOME`. This provides both the lycium build
> framework and its existing `thirdparty/<package>/HPKBUILD` recipe catalog. You do not
> need to vendor or download a recipe that is already in that catalog. The action does
> **not** prebuild those libraries; run `./build.sh <package>` to produce the binaries.

## Features

- Downloads and caches the OpenHarmony SDK (native toolchain)
- Sets up `OHOS_SDK`, `OHOS_NDK_HOME`, `OHOS_CMAKE_TOOLCHAIN`, and `PATH` environment variables
- Detects and exports the CMake toolchain file path (`ohos.toolchain.cmake`)
- With `lycium: true`, clones the complete [`tpc_c_cplusplus`](https://gitcode.com/CPF-ApplicationTPC/tpc_c_cplusplus) repository, including the build framework and hundreds of existing third-party package recipes
- Lets lycium resolve and build dependencies declared by an existing package recipe
- Optionally installs build tools (`minimal`, `full`, or `none`)
- Pure shell implementation — zero dependencies, fully transparent

See the official [Huawei guide](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/toolchain-lycium-build-project) for background on using lycium to cross-compile third-party libraries.

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

### Build a package from the cloned recipe catalog

Setting `lycium: true` makes the cloned recipe catalog available under
`$LYCIUM_HOME/thirdparty`. If the package recipe exists there, build it directly:

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
    with:
      lycium: true
      tools: minimal
  - run: |
      test -f "$LYCIUM_HOME/thirdparty/cJSON/HPKBUILD"
      cd $LYCIUM_HOME/lycium
      ./build.sh cJSON
  - run: |
      find $LYCIUM_HOME/lycium/usr/cJSON -type f
      test -f "$LYCIUM_HOME/lycium/usr/cJSON/arm64-v8a/lib/libcjson.a"
```

Lycium reads `depends=(...)` from the selected `HPKBUILD` and builds available dependency
recipes first. Build output is written to `$LYCIUM_HOME/lycium/usr/<package>/<ABI>/`.

### With SDK caching (recommended for frequent builds)

Place `actions/cache` **before** `setup-ohos` so the action can skip re-downloading on cache hit.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: actions/cache@v4
    with:
      path: ${{ runner.temp }}/ohos-sdk
      key: ohos-sdk-6.1-Release
  - uses: isaced/setup-ohos@v1
    with:
      sdk-version: '6.1-Release'
```

### Check whether a package recipe is included

The catalog comes from the repository selected by `lycium-repo` and `lycium-ref`. Check
the cloned tree instead of copying recipes into your application repository:

```yaml
- name: Check libsmbclient recipe
  run: |
    test -f "$LYCIUM_HOME/thirdparty/libsmbclient/HPKBUILD"
    sed -n '1,40p' "$LYCIUM_HOME/thirdparty/libsmbclient/HPKBUILD"
```

Common packages such as `cJSON`, `curl`, `zlib`, and `libsmbclient` can be built this way
when they are present in the selected upstream revision.

### Add a package that is not in the catalog

Only add a recipe yourself when it is absent from `$LYCIUM_HOME/thirdparty`. Keep the
custom recipe in your own repository, copy it into the cloned catalog, then run
`build.sh` normally:

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: isaced/setup-ohos@v1
    with:
      sdk-version: '6.1-Release'
      lycium: true
      tools: full

  # This directory belongs to your repository, not setup-ohos.
  - run: |
      test ! -e "$LYCIUM_HOME/thirdparty/my-library"
      cp -R "$GITHUB_WORKSPACE/lycium-packages/my-library" \
        "$LYCIUM_HOME/thirdparty/my-library"

  - run: |
      cd $LYCIUM_HOME/lycium
      ./build.sh my-library

  - run: |
      find "$LYCIUM_HOME/lycium/usr/my-library" -type f
```

If the custom recipe declares dependencies that are also absent from the cloned catalog,
add those recipes as well. See lycium's [HPKBUILD template](https://gitcode.com/CPF-ApplicationTPC/tpc_c_cplusplus/blob/master/lycium/template/HPKBUILD) for the recipe format.

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
| `sdk-version` | OpenHarmony SDK version (e.g. `5.0-Release`, `6.1-Release`) | `6.1-Release` |
| `sdk-url` | Custom SDK download URL (overrides default Huawei Cloud mirror) | `''` |
| `lycium` | Clone the complete lycium repository, including its `thirdparty` recipe catalog | `false` |
| `lycium-repo` | lycium git repository URL | `https://gitcode.com/CPF-ApplicationTPC/tpc_c_cplusplus.git` |
| `lycium-ref` | lycium git ref (branch/tag/commit) | `''` (default branch) |
| `tools` | Tool installation level: `none`, `minimal`, `full` | `minimal` |

## Outputs

| Output | Description |
|--------|-------------|
| `ohos-sdk` | Path to OHOS SDK (parent of `native/`, i.e. the `linux/` directory) |
| `ohos-native` | Path to OHOS SDK native directory |
| `ohos-cmake-toolchain` | Path to `ohos.toolchain.cmake` for CMake cross-compilation |
| `lycium-home` | Path to the cloned `tpc_c_cplusplus` repository root (empty if `lycium=false`) |

## Environment Variables

After this action runs, the following variables are available in subsequent steps:

| Variable | Description |
|----------|-------------|
| `OHOS_SDK` | SDK path (parent of `native/`, lycium convention) |
| `OHOS_NDK_HOME` | Path to `native/` directory |
| `OHOS_CMAKE_TOOLCHAIN` | Path to CMake toolchain file |
| `LYCIUM_BUILD_CHECK` | Set to `false` (skip device tests in CI) |
| `LYCIUM_HOME` | Cloned `tpc_c_cplusplus` repository root (only if `lycium=true`) |

The toolchain binaries (`llvm/bin`) and the SDK's bundled CMake (`build-tools/cmake/bin`) are also prepended to `PATH`.

## Tool Levels

- **`minimal`** — Tools required by lycium's `checkbuildenv()`: gcc, g++, cmake, make, ninja, pkg-config, autoconf, automake, patch, unzip, curl, wget, git
- **`full`** — Broad tool set for packages in the lycium catalog: adds libtool, gperf, flex, bison, yasm, nasm, python3, meson, gettext, texinfo, and more
- **`none`** — Skip tool installation entirely (use when you only need the SDK and have your own toolchain)

## How It Works

The action runs as a composite action with the following steps:

1. **Install build tools** (if `tools != 'none'`) — `apt-get install` the selected tool set
2. **Cache OHOS SDK** — `actions/cache@v4` on `${{ runner.temp }}/ohos-sdk`, keyed by SDK version
3. **Download and extract SDK** — `curl` + `tar` from Huawei Cloud (or `sdk-url`), extracts the `linux/native/` toolchain
4. **Set up environment** — exports `OHOS_SDK`, `OHOS_NDK_HOME`, `OHOS_CMAKE_TOOLCHAIN`, updates `PATH`
5. **Set up lycium** (if `lycium == 'true'`) — shallow-clones the complete [`tpc_c_cplusplus`](https://gitcode.com/CPF-ApplicationTPC/tpc_c_cplusplus) repository into `$LYCIUM_HOME`. The clone includes both the lycium framework (`lycium/build.sh`) and the current upstream recipe catalog (`thirdparty/<package>/HPKBUILD`). No third-party package is compiled until your workflow runs `build.sh`.

After setup, the directory layout is:

```
$LYCIUM_HOME/
├── lycium/          # lycium framework (build.sh, script/, template/)
│   ├── build.sh
│   └── usr/         # build output (automatically created)
└── thirdparty/      # upstream third-party library recipe catalog
    ├── curl/HPKBUILD
    ├── cJSON/HPKBUILD
    └── ...
```

All scripts live under [`scripts/`](./scripts) and are plain bash — no Node.js runtime, no hidden dependencies.

## Supported SDK Versions

Tested against the following OpenHarmony SDK releases:

| Version | Status |
|---------|--------|
| `6.1-Release` | ✅ Tested (default) |
| `6.0-Release` | ✅ Tested |
| `5.0-Release` | ✅ Tested |

Other versions available on the [Huawei Cloud mirror](https://repo.huaweicloud.com/openharmony/os/) should work as long as the SDK archive layout matches (`linux/native/` with `llvm/bin/` and a `ohos.toolchain.cmake`).

## Limitations

- **Linux runners only.** The action removes the Windows SDK portion and relies on `apt-get` for tool installation. Use `runs-on: ubuntu-latest`.
- **No automatic device testing.** `LYCIUM_BUILD_CHECK` is set to `false` by default since CI runners are not OpenHarmony devices. Override this variable in a later step if you have a connected device.
- **SDK layout assumptions.** The action expects `$SDK_PATH/native/llvm/bin/` and a `ohos.toolchain.cmake` under `native/build/cmake/` or `native/build-tools/cmake/share/`. Non-standard SDK layouts will fail the verification step.

## Reference projects

- [libsmb2-ohos](https://github.com/isaced/libsmb2-ohos) — SMB2/SMB3 client library for HarmonyOS/OpenHarmony, using `setup-ohos` for CI cross-compilation of the native libsmb2 library and its HAR packaging.

## License

MIT
