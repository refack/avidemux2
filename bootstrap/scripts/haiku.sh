#!/bin/bash
# Bootstrapper for Haiku

source "$(dirname "$0")/common.sh"

# Default configuration
install_prefix="/boot/apps/Avidemux"
do_core=1
do_cli=0
do_gtk=0
do_qt=1
do_plugins=1
rebuild=0
debug=0
packages_ext=""

usage() {
  echo "Bootstrap Avidemux (Haiku):"
  echo "***********************"
  echo "  --help            : Print usage"
  echo "  --tgz             : Build tgz packages"
  echo "  --debug           : Switch debugging on"
  echo "  --with-core       : Build core"
  echo "  --without-core    : Dont build core"
  echo "  --with-cli        : Build cli"
  echo "  --without-cli     : Dont build cli"
  echo "  --with-gtk        : Build gtk"
  echo "  --without-gtk     : Dont build gtk"
  echo "  --with-qt         : Build qt (default)"
  echo "  --without-qt      : Dont build qt"
  echo "  --with-plugins    : Build plugins"
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
    --tgz)
        packages_ext=tar.gz
        PKG="$PKG -DAVIDEMUX_PACKAGER=tgz"
        ;;
    --without-qt|--without-qt4)
        do_qt=0
        ;;
    --with-qt|--with-qt4)
        do_qt=1
        ;;
    --without-cli)
        do_cli=0
        ;;
    --with-cli)
        do_cli=1
        ;;
    --without-gtk)
        do_gtk=0
        ;;
    --with-gtk)
        do_gtk=1
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

echo "**BootStrapping avidemux (Haiku) **"
BUILDTOP=$PWD
SRCTOP=$(cd $(dirname "$0")/../.. && pwd)

# Haiku specific flags
export CMAKE_EXTRA_FLAGS="-D__STDC_CONSTANT_MACROS -DPTHREAD_INCLUDE_DIR=/boot/develop/headers/posix -DAVIDEMUX_SOURCE_DIR=$SRCTOP"

if [ "x$do_core" = "x1" ]; then
    echo "** CORE **"
    Process buildCore "${SRCTOP}/avidemux_core"
fi

if [ "x$do_qt" = "x1" ]; then
    echo "** QT **"
    Process buildQt4 "${SRCTOP}/avidemux/qt4"
fi

if [ "x$do_cli" = "x1" ]; then
    echo "** CLI **"
    Process buildCli "${SRCTOP}/avidemux/cli"
fi

if [ "x$do_gtk" = "x1" ]; then
    echo "** GTK **"
    Process buildGtk "${SRCTOP}/avidemux/gtk"
fi

if [ "x$do_plugins" = "x1" ]; then
    echo "** Plugins **"
    Process buildPluginsCommon "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=COMMON"
fi

if [ "x$do_plugins" = "x1" -a "x$do_qt" = "x1" ]; then
    echo "** Plugins Qt4 **"
    Process buildPluginsQt4 "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=QT4"
fi

if [ "x$do_plugins" = "x1" -a "x$do_gtk" = "x1" ]; then
    echo "** Plugins Gtk **"
    Process buildPluginsGtk "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=GTK"
fi

if [ "x$do_plugins" = "x1" -a "x$do_cli" = "x1" ]; then
    echo "** Plugins CLI **"
    Process buildPluginsCLI "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=CLI"
fi

echo "** Preparing debs **"
cd "$BUILDTOP"
if [ "x$packages_ext" = "x" ]; then
    echo "No packaging"
else
    echo "Preparing packages"
    rm -Rf debs
    mkdir debs
    find . -name "*.$packages_ext" | grep -vi cpa | xargs cp -t debs
    echo "** debs directory ready **"
    ls -l debs
fi
echo "** ALL DONE **"
