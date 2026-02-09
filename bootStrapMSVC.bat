setlocal enabledelayedexpansion

rem Check if VCPKG_ROOT is set
if "%VCPKG_ROOT%"=="" (
    echo Error: VCPKG_ROOT environment variable is not set.
    echo Please set it to your VCPKG installation directory.
    exit /b 1
)

set "TOP=%~dp0"
set "BUILD_ROOT=%TOP%build_msvc"
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
set "CMAKE_ARGS=-G Ninja  -DCMAKE_TOOLCHAIN_FILE="E:/.vcpkg-clion/scripts/buildsystems/vcpkg.cmake" -DCMAKE_INSTALL_PREFIX="E:/scoop/apps/avidemux/current" -DENABLE_QT6=ON -DCMAKE_C_COMPILER="cl.exe" -DCMAKE_CXX_COMPILER="cl.exe" -DCMAKE_BUILD_TYPE=Release -DVERBOSE=True -DVS_IMPORT=True -DIMPORT_FOLDER="E:/scoop/apps/ffmpeg-shared/current"  "

echo Building in %BUILD_ROOT%
echo Installing to %INSTALL_DIR%

rem 1. Core
echo ========================================
echo Building Avidemux Core...
echo ========================================
mkdir "%BUILD_ROOT%\core"
cd "%BUILD_ROOT%\core"
cmake "%TOP%avidemux_core" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 2. Qt
echo ========================================
echo Building Avidemux Qt GUI...
echo ========================================
mkdir "%BUILD_ROOT%\qt"
cd "%BUILD_ROOT%\qt"
cmake "%TOP%avidemux/qt4" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 3. CLI
echo ========================================
echo Building Avidemux CLI...
echo ========================================
mkdir "%BUILD_ROOT%\cli"
cd "%BUILD_ROOT%\cli"
cmake "%TOP%avidemux/cli" %CMAKE_ARGS%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

rem 4. Plugins
echo ========================================
echo Building Plugins (Common)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_common"
cd "%BUILD_ROOT%\plugins_common"
cmake "%TOP%avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=COMMON
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (Qt)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_qt"
cd "%BUILD_ROOT%\plugins_qt"
cmake "%TOP%avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=QT4
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (CLI)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_cli"
cd "%BUILD_ROOT%\plugins_cli"
cmake "%TOP%avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=CLI
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo ========================================
echo Building Plugins (Settings)...
echo ========================================
mkdir "%BUILD_ROOT%\plugins_settings"
cd "%BUILD_ROOT%\plugins_settings"
cmake "%TOP%avidemux_plugins" %CMAKE_ARGS% -DPLUGIN_UI=SETTINGS
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
@REM cmake --build . --config Release --target install
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo Build complete.
echo Files installed in: %INSTALL_DIR%
cd "%TOP%"
