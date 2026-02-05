Building Avidemux with MSVC (Microsoft Visual Studio)
=====================================================

The recommended way to build Avidemux with MSVC is using CMake directly, with dependencies managed by VCPKG.

Prerequisites:
--------------
1.  Visual Studio 2019 or later with C++ desktop development workload.
2.  CMake (3.20 or later).
3.  VCPKG (https://github.com/microsoft/vcpkg).
4.  Git.

Legacy Scripts:
---------------
The scripts located in `foreignBuilds/mswin/` are considered legacy and may not work with recent versions of Avidemux or MSVC.

Building with VCPKG:
--------------------

### Option 1: Classic Mode

1.  **Install VCPKG:**
    Clone and bootstrap VCPKG if you haven't already.
    ```cmd
    git clone https://github.com/microsoft/vcpkg.git
    cd vcpkg
    bootstrap-vcpkg.bat
    ```

2.  **Install Dependencies:**
    Install required libraries. For Qt6 and other deps:
    ```cmd
    vcpkg install qtbase:x64-windows ffmpeg:x64-windows libxml2:x64-windows ...
    ```
    (Note: The exact list of VCPKG packages required may vary. Check `avidemux/qt4/CMakeLists.txt` and other CMake files for dependencies.)

### Option 2: Manifest Mode (vcpkg.json)

1.  **Install VCPKG:**
    Clone and bootstrap VCPKG if you haven't already.
    ```cmd
    git clone https://github.com/microsoft/vcpkg.git
    cd vcpkg
    bootstrap-vcpkg.bat
    ```

2.  **Dependencies:**
    Dependencies are defined in `vcpkg.json` in the source tree. They will be installed automatically during the CMake configuration step.

### Build Steps (Common)

3.  **Configure with CMake:**
    Open a Developer Command Prompt for VS.
    Set the `VCPKG_ROOT` environment variable to your VCPKG installation directory.
    
    **CMD:**
    ```cmd
    set VCPKG_ROOT=C:\path\to\vcpkg
    ```
    **PowerShell:**
    ```powershell
    $env:VCPKG_ROOT="C:\path\to\vcpkg"
    ```

    Create a build directory:
    ```cmd
    mkdir build_msvc
    cd build_msvc
    ```

    Run CMake. You need to specify the toolchain file provided by VCPKG.
    ```cmd
    cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
    ```
    (In PowerShell, use `$env:VCPKG_ROOT` instead of `%VCPKG_ROOT%`)

4.  **Build:**
    ```cmd
    cmake --build . --config Release
    ```

5.  **Run/Install:**
    The binaries will be in the `Release` folder (or similar depending on configuration).
    You can install using:
    ```cmd
    cmake --install . --prefix C:\avidemux_install
    ```

Speeding up builds with sccache:
--------------------------------
You can use `sccache` to cache compilation results and speed up rebuilds of dependencies.

1.  Install `sccache` (e.g., via `scoop install sccache` or `cargo install sccache`) and ensure it is in your PATH.
2.  Set the environment variables to instruct CMake to use `sccache`. Since `vcpkg` sanitizes the build environment, you must also use `VCPKG_KEEP_ENV_VARS`.

    **CMD:**
    ```cmd
    set CMAKE_C_COMPILER_LAUNCHER=sccache
    set CMAKE_CXX_COMPILER_LAUNCHER=sccache
    set VCPKG_KEEP_ENV_VARS=CMAKE_C_COMPILER_LAUNCHER;CMAKE_CXX_COMPILER_LAUNCHER
    ```

    **PowerShell:**
    ```powershell
    $env:CMAKE_C_COMPILER_LAUNCHER="sccache"
    $env:CMAKE_CXX_COMPILER_LAUNCHER="sccache"
    $env:VCPKG_KEEP_ENV_VARS="CMAKE_C_COMPILER_LAUNCHER;CMAKE_CXX_COMPILER_LAUNCHER"
    ```

    **Important:** You must delete your build directory (e.g., `build_msvc`) or clear the CMake cache after setting these variables for them to take effect.

Troubleshooting:
----------------

### QtWebEngine "Buildtree path is too long"
If you encounter an error about the buildtree path being too long when building `qtwebengine` (common on Windows), you need to instruct vcpkg to use a shorter path for the build tree.

**For Manifest Mode (CMake):**
Add `-DVCPKG_INSTALL_OPTIONS="--x-buildtrees-root=C:/bt"` to your CMake configure command.
```cmd
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake -DVCPKG_INSTALL_OPTIONS="--x-buildtrees-root=C:/bt"
```

**For Classic Mode (Manual vcpkg install):**
Add `--x-buildtrees-root=C:\bt` to your vcpkg install command.
```cmd
vcpkg install qtwebengine ... --x-buildtrees-root=C:\bt
```
(Ensure the directory `C:\bt` exists or can be created).

### Common VCPKG Package Names
All of the following Qt6 components are included in the single `qtbase` package in vcpkg:
- `Qt6::Core`
- `Qt6::Gui`
- `Qt6::Widgets`
- `Qt6::OpenGLWidgets`
- `Qt6::Network`

So you only need to install `qtbase`.

### Debugging CMake Files
To debug a `.cmake` file (like `admCheckQt6.cmake`), you can use `MESSAGE` commands to print variable values and execution flow.

**Example:**
```cmake
MESSAGE(STATUS "DEBUG: Variable X is ${X}")
```

You can also use the `--trace` or `--trace-expand` options with CMake to see every command being executed.
```cmd
cmake .. --trace-expand > trace.log 2>&1
```
(Redirecting to a file is recommended as the output can be huge).
