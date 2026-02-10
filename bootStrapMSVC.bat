setlocal enabledelayedexpansion

rem Check if VCPKG_ROOT is set
if "%VCPKG_ROOT%"=="" (
    echo Error: VCPKG_ROOT environment variable is not set.
    echo Please set it to your VCPKG installation directory.
    exit /b 1
)

set "TOP=%~dp0"
set "AVIDEMUX_ROOT_DIR=%TOP:\=/%"
set "BUILD_ROOT=%AVIDEMUX_ROOT_DIR%\build_msvc"
set "INSTALL_DIR=%BUILD_ROOT%\install"

rem Clean
if exist "%BUILD_ROOT%" (
    echo Cleaning build directory...
    rd /s /q "%BUILD_ROOT%"
)
mkdir "%BUILD_ROOT%"
mkdir "%INSTALL_DIR%"

rem Common args
rem We default to Visual Studio 17 2022 as per MSVC_BUILD.md
rem If user wants another one, they can edit this script.
set "CMAKE_TOOLCHAIN_FILE=E:/.vcpkg-clion/scripts/buildsystems/vcpkg.cmake"
set "CMAKE_INSTALL_PREFIX=E:/scoop/apps/avidemux/current"
set CMAKE_C_COMPILER=cl.exe
set CMAKE_CXX_COMPILER=cl.exe
set "IMPORT_FOLDER=E:/scoop/apps/ffmpeg-shared/current"
set "CMAKE_ARGS=-G Ninja -DENABLE_QT6=ON -DCMAKE_BUILD_TYPE=Release -DVERBOSE=True -DVS_IMPORT=True -DAVIDEMUX_ROOT_DIR=%AVIDEMUX_ROOT_DIR%"

echo Building in %BUILD_ROOT%
echo Installing to %INSTALL_DIR%

rem 1. Core
echo ========================================
echo Building Avidemux Core...
echo ========================================
mkdir "%BUILD_ROOT%\core"
cd "%BUILD_ROOT%\core"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux_core" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 2. Qt
echo ========================================
echo Building Avidemux Qt GUI...
echo ========================================
mkdir "%BUILD_ROOT%\qt"
cd "%BUILD_ROOT%\qt"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux\qt4" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 3. CLI
echo ========================================
echo Building Avidemux CLI...
echo ========================================
mkdir "%BUILD_ROOT%\cli"
cd "%BUILD_ROOT%\cli"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux\cli" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 4. Plugins
echo ========================================
echo Building Plugins (Common)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_common"
cd "%BUILD_ROOT%\plugins_common"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=COMMON
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (Qt)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_qt"
cd "%BUILD_ROOT%\plugins_qt"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=QT4
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (CLI)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_cli"
cd "%BUILD_ROOT%\plugins_cli"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=CLI
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (Settings)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_settings"
cd "%BUILD_ROOT%\plugins_settings"
cmake "%AVIDEMUX_ROOT_DIR%\avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=SETTINGS
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo Build complete.
echo Files installed in: %INSTALL_DIR%
cd "%AVIDEMUX_ROOT_DIR%"
