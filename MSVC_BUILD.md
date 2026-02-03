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
    vcpkg install qt6-base:x64-windows ffmpeg:x64-windows libxml2:x64-windows ...
    ```
    (Note: The exact list of VCPKG packages required may vary. Check `avidemux/qt4/CMakeLists.txt` and other CMake files for dependencies.)

3.  **Configure with CMake:**
    Open a Developer Command Prompt for VS.
    Set the `VCPKG_ROOT` environment variable to your VCPKG installation directory.
    ```cmd
    set VCPKG_ROOT=C:\path\to\vcpkg
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
