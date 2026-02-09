# Script Map

This document lists the shell scripts found in the repository, categorized by their location and purpose.

## Root Directory (Build Entry Point)

*   `bootStrap.sh`: Main entry point for building Avidemux. Redirects to platform-specific scripts in `bootstrap/scripts/`.

## bootstrap/scripts/ (Refactored Build Scripts)

*   `common.sh`: Shared functions for bootstrap scripts.
*   `linux.sh`: Linux build script.
*   `macos.sh`: macOS build script.
*   `mingw.sh`: MinGW/MXE build script.
*   `haiku.sh`: Haiku build script.
*   `win_msvc.sh`: Windows MSVC (Ninja) build script.
*   `checkCaseSensitivity.sh`: Utility to check file system case sensitivity.

## bootstrap/appImage/ (AppImage Creation)

*   `makeAppImage.sh`, `makeAppImage*.sh`: Scripts for building and packaging AppImages (execute build scripts).
*   `prepare_env_bookworm.sh`, `prepare_env_buster.sh`: Scripts to install build dependencies (bootstrapping).
*   `deploy.sh`, `deploy*.sh`: Scripts to deploy artifacts into the AppImage structure.
*   `check.sh`: Verification script.

## bootstrap/mxe/ (Cross-Compilation Environment)

*   `mxe-setup.sh`: Script for setting up the MXE cross-compilation environment.
*   `install-libaom.bash`, `x264-snapshot.sh`: Dependency build scripts.

## bootstrap/addons/

*   `ts_to_mkv.bash`: Helper script for TS to MKV conversion.

## bootstrap/autononreg/

*   `js/run_non_reg.sh`, `js/dialogFactory/unit/run_non_reg.sh`: Scripts for running non-regression tests (JavaScript).

## bootstrap/man/

*   (Man pages directory)

## scripts/ (Utilities)

*   `automkv.py`: Auto MKV script.
*   `update_license.sh`: Utility to update license headers.
*   `run_templates/`: Directory containing runtime template scripts (`run_avidemux_template_qt*.sh`, `run_jobs_template_qt*.sh`).

## Other Locations

*   `avidemux/gtk/ADM_userInterfaces/ADM_gui2/patch.bash`: Patch utility for GTK GUI.
*   `avidemux/osxInstaller/macos-adhoc-sign-installed-app.sh`: Helper for ad-hoc signing on macOS.
*   `avidemux/qt4/ADM_userInterfaces/ADM_gui/pics/svg/generate_png.sh`: SVG to PNG generation for icons.
*   `avidemux/qt4/i18n/qt_update_pro.sh`: Script to update Qt translation project files.
*   `avidemux/winInstaller/createCrossNsisQt*.sh`, `createNativeNsisQt*.sh`, `genlog.sh`, `qtifw/split.bash`: Scripts for creating Windows installers (NSIS/QtIFW).
*   `avidemux_core/ADM_coreUtils/src/update_prefs.sh`: Updates preferences code.
*   `avidemux_core/cmake/sql/update.sh`: SQL update helper.
*   `avidemux_core/ffmpeg_package/patches/createPatches.sh`: Helper to create FFmpeg patches.
*   `avidemux_plugins/ADM_scriptEngines/spiderMonkey/src/updateIdl.sh`: Updates IDL for SpiderMonkey script engine.
*   `myOwnPlugins/muxer/libmkv/bootstrap.sh`: Bootstrap script for libmkv in myOwnPlugins.
