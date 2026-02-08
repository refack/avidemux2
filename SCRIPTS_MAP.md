# Script Map

This document lists the shell scripts found in the repository, categorized by their location and purpose.

## Root Directory (Build & Packaging)

*   `bootStrap.sh`: Main entry point for building Avidemux. Redirects to platform-specific scripts in `bootStrap/`.
*   `bootStrapMSVC.bat`: Legacy batch file for building with MSVC (CMD).
*   `createDebFromSourceUbuntu.bash`: Script to create Debian packages.
*   `createRpmFromSourceFedora.bash`: Script to create RPM packages.

## bootStrap/ (Refactored Build Scripts)

*   `common.sh`: Shared functions for bootstrap scripts.
*   `linux.sh`: Linux build script (refactored from `bootStrap.bash`).
*   `macos.sh`: macOS build script (refactored from `bootStrapMacOS_*.sh`).
*   `mingw.sh`: MinGW/MXE build script (refactored from `bootStrapCrossMingw*.sh`).
*   `haiku.sh`: Haiku build script (refactored from `bootStrapHaikuOS.bash`).
*   `win_msvc.sh`: Windows MSVC (Ninja) build script.
*   `checkCaseSensitivity.sh`: Utility to check file system case sensitivity.

## appImage/

*   `check.sh`, `deploy.sh`, `deploy*.sh`: Scripts related to AppImage deployment and verification.
*   `makeAppImage.sh`, `makeAppImage*.sh`: Scripts for creating AppImages (moved from root).

## scripts/

*   `automkv.py`: Auto MKV script.
*   `update_license.sh`: Utility to update license headers (moved from root).
*   `run_templates/`: Directory containing runtime template scripts (`run_avidemux_template_qt*.sh`, `run_jobs_template_qt*.sh`).

## addons/

*   `ts_to_mkv.bash`: Helper script for TS to MKV conversion.

## autononreg/

*   `js/run_non_reg.sh`, `js/dialogFactory/unit/run_non_reg.sh`: Scripts for running non-regression tests (JavaScript).

## avidemux/

*   `gtk/ADM_userInterfaces/ADM_gui2/patch.bash`: Patch utility for GTK GUI.
*   `osxInstaller/macos-adhoc-sign-installed-app.sh`: Helper for ad-hoc signing on macOS.
*   `qt4/ADM_userInterfaces/ADM_gui/pics/svg/generate_png.sh`: SVG to PNG generation for icons.
*   `qt4/i18n/qt_update_pro.sh`: Script to update Qt translation project files.
*   `winInstaller/createCrossNsisQt*.sh`, `createNativeNsisQt*.sh`, `genlog.sh`, `qtifw/split.bash`: Scripts for creating Windows installers (NSIS/QtIFW).

## avidemux_core/

*   `ADM_coreUtils/src/update_prefs.sh`: Updates preferences code.
*   `cmake/sql/update.sh`: SQL update helper.
*   `ffmpeg_package/patches/createPatches.sh`: Helper to create FFmpeg patches.

## avidemux_plugins/

*   `ADM_scriptEngines/spiderMonkey/src/updateIdl.sh`: Updates IDL for SpiderMonkey script engine.

## mxe/

*   `mxe-setup.sh`, `install-libaom.bash`, `x264-snapshot.sh`: Scripts for setting up MXE environment and building dependencies.

## myOwnPlugins/

*   `muxer/libmkv/bootstrap.sh`: Bootstrap script for libmkv in myOwnPlugins.
