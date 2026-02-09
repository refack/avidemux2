#!/bin/bash
# Bootstrapper for Windows MSVC (run in Git Bash or similar, after vcvarsall.bat)

source "$(dirname "$0")/common.sh"

# Default configuration
do_ninja=1
do_core=1
do_qt=1
do_cli=1
do_plugins=1
rebuild=0
debug=0
qt_ext="Qt6"

# VCPKG support
if [ -n "$VCPKG_ROOT" ]; then
    echo "Using VCPKG from $VCPKG_ROOT"
    # Ensure forward slashes
    VCPKG_ROOT_FWD=$(echo "$VCPKG_ROOT" | sed 's/\\/\//g')
    TOOLCHAIN_FLAG="-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT_FWD/scripts/buildsystems/vcpkg.cmake"
else
    echo "Warning: VCPKG_ROOT is not set. Build might fail if dependencies are missing."
fi

usage() {
  echo "Bootstrap Avidemux (Windows MSVC):"
  echo "***********************"
  echo "  --help            : Print usage"
  echo "  --debug           : Switch debugging on"
  echo "  --rebuild         : Rebuild from scratch"
  echo "  --with-core       : Build core (default)"
  echo "  --without-core    : Dont build core"
  echo "  --with-cli        : Build cli (default)"
  echo "  --without-cli     : Dont build cli"
  echo "  --with-qt         : Build qt (default)"
  echo "  --without-qt      : Dont build qt"
  echo "  --with-plugins    : Build plugins (default)"
  echo "  --without-plugins : Dont build plugins"
}

while [ $# != 0 ]; do
  case "$1" in
    -h|--help)
        usage
        exit 1
        ;;
    --debug)
        debug=1
        ;;
    --rebuild)
        rebuild=1
        ;;
    --without-qt)
        do_qt=0
        ;;
    --with-qt)
        do_qt=1
        ;;
    --without-cli)
        do_cli=0
        ;;
    --with-cli)
        do_cli=1
        ;;
    --without-plugins)
        do_plugins=0
        ;;
    --with-plugins)
        do_plugins=1
        ;;
    --without-core)
        do_core=0
        ;;
    --with-core)
        do_core=1
        ;;
    *)
        echo "unknown parameter $1"
        usage
        exit 1
        ;;
  esac
  shift
done

echo "**BootStrapping avidemux (MSVC) **"
BUILDTOP=$PWD
SRCTOP=$(cd $(dirname "$0")/../.. && pwd)
install_prefix="${BUILDTOP}/install"

export CMAKE_EXTRA_FLAGS="-DENABLE_QT6=ON $TOOLCHAIN_FLAG -DAVIDEMUX_SOURCE_DIR=$SRCTOP"

# Process calls
if [ "x$do_core" = "x1" ]; then
    echo "** CORE **"
    Process buildMsvcCore "${SRCTOP}/avidemux_core"
fi

if [ "x$do_qt" = "x1" ]; then
    echo "** QT **"
    Process buildMsvcQt "${SRCTOP}/avidemux/qt4"
fi

if [ "x$do_cli" = "x1" ]; then
    echo "** CLI **"
    Process buildMsvcCli "${SRCTOP}/avidemux/cli"
fi

if [ "x$do_plugins" = "x1" ]; then
    echo "** Plugins (Common) **"
    Process buildMsvcPluginsCommon "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=COMMON"
fi

if [ "x$do_plugins" = "x1" -a "x$do_qt" = "x1" ]; then
    echo "** Plugins (Qt) **"
    Process buildMsvcPluginsQt "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=QT4"
fi

if [ "x$do_plugins" = "x1" -a "x$do_cli" = "x1" ]; then
    echo "** Plugins (CLI) **"
    Process buildMsvcPluginsCli "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=CLI"
fi

if [ "x$do_plugins" = "x1" ]; then
    echo "** Plugins (Settings) **"
    Process buildMsvcPluginsSettings "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=SETTINGS"
fi

echo "** ALL DONE **"
