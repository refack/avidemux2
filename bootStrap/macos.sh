#!/bin/bash
# Bootstrapper for macOS

source "$(dirname "$0")/common.sh"

# Default configuration
arch="x86_64"
do_core=1
do_cli=1
do_qt=1
do_plugins=1
rebuild=0
debug=0
create_app_bundle=1
create_dmg=1
external_liba52=1
external_libmad=0
external_libmp4v2=1
qt_ext="Qt6"
qt_flavor="-DENABLE_QT6=True"
do_ninja=1 # Default to Ninja on macOS

# Default SDK and deployment target (can be overridden)
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null)
export MACOSX_DEPLOYMENT_TARGET=$(xcrun --sdk macosx --show-sdk-version 2>/dev/null)

usage() {
  echo "Bootstrap Avidemux (macOS):"
  echo "***********************"
  echo "  --help                  : Print usage"
  echo "  --arch=ARCH             : Target architecture (x86_64, arm64). Default: x86_64"
  echo "  --no-bundle             : Don't create macOS app bundle structure"
  echo "  --nopkg                 : Don't make macOS app bundle self-contained and package it as DMG"
  echo "  --debug                 : Switch debugging on"
  echo "  --rebuild               : Preserve existing build directories"
  echo "  --output=NAME           : Specify a custom basename for dmg"
  echo "  --version=STRING        : Specify a custom Avidemux version string"
  echo "  --with-core             : Build core (default)"
  echo "  --without-core          : Don't build core"
  echo "  --with-cli              : Build cli (default)"
  echo "  --without-cli           : Don't build cli"
  echo "  --with-qt               : Build qt (default)"
  echo "  --without-qt            : Don't build qt"
  echo "  --with-plugins          : Build plugins (default)"
  echo "  --without-plugins       : Don't build plugins"
  echo "  --with-internal-liba52  : Use bundled liba52 (a52dec) instead of the system one"
  echo "  --with-external-libmad  : Use system libmad instead of the bundled one"
  echo "  --with-internal-libmp4v2: Use bundled libmp4v2 instead of the system one"
}

validate() {
  opt="$1"
  str="$2"
  if [ "$opt" = "adm_version" ]; then
    reg="[^a-zA-Z0-9_.-]"
    msg="Only alphanumeric characters, hyphen, underscore and period are allowed for Avidemux version, aborting."
  elif [ "$opt" = "output" ]; then
    reg="[^a-zA-Z0-9\ _.-]"
    msg="Only alphanumeric characters, space, hyphen, underscore and period are allowed for .dmg basename, aborting."
  else
    >&2 echo "incorrect usage of validate(), aborting."
    exit 1
  fi
  if [[ "$str" =~ $reg ]]; then
    >&2 echo $msg
    exit 1
  fi
}

while [ $# != 0 ]; do
  config_option="$1"
  case "$config_option" in
  -h | --help)
    usage
    exit 1
    ;;
  --arch=*)
    arch=$(option_value "$config_option")
    ;;
  --debug)
    debug=1
    ;;
  --rebuild)
    rebuild=1
    ;;
  --no-bundle)
    create_app_bundle=0
    ;;
  --nopkg)
    create_dmg=0
    ;;
  --output=*)
    dmg_base=$(option_value "$config_option")
    ;;
  --version=*)
    adm_version=$(option_value "$config_option")
    ;;
  --without-qt)
    do_qt=0
    ;;
  --without-cli)
    do_cli=0
    ;;
  --without-plugins)
    do_plugins=0
    ;;
  --without-core)
    do_core=0
    ;;
  --with-qt)
    do_qt=1
    ;;
  --with-cli)
    do_cli=1
    ;;
  --with-plugins)
    do_plugins=1
    ;;
  --with-core)
    do_core=1
    ;;
  --with-internal-liba52)
    external_liba52=0
    ;;
  --with-external-libmad)
    external_libmad=1
    ;;
  --with-internal-libmp4v2)
    external_libmp4v2=0
    ;;
  *)
    echo "unknown parameter $config_option"
    usage
    exit 1
    ;;
  esac
  shift
done

echo "** BootStrapping avidemux (macOS) **"

BUILDTOP=$PWD
if [[ $BUILDTOP = *" "* ]]; then
  echo "The build directory path \"${BUILDTOP}\" contains one or more spaces."
  echo "This is unsupported by FFmpeg configure."
  fail "bootstrap"
fi

SRCTOP=$(cd $(dirname "$0")/.. && pwd)

# Check case sensitivity
# Assuming checkCaseSensitivity.sh is moved to bootStrap/
source "$(dirname "$0")/checkCaseSensitivity.sh"
isCaseSensitive || { echo "Error: build directory file system is not case-sensitive." && exit 1; }

if [ -n "$adm_version" ]; then
    validate adm_version "$adm_version" || exit 1
fi
if [ -n "$dmg_base" ]; then
    validate output "$dmg_base" || exit 1
fi

pushd "${SRCTOP}" >/dev/null
export MAJOR=$(cat avidemux_core/cmake/avidemuxVersion.cmake | grep "VERSION_MAJOR " | sed 's/..$//g' | sed 's/^.*"//g')
export MINOR=$(cat avidemux_core/cmake/avidemuxVersion.cmake | grep "VERSION_MINOR " | sed 's/..$//g' | sed 's/^.*"//g')
export PATCH=$(cat avidemux_core/cmake/avidemuxVersion.cmake | grep "VERSION_P " | sed 's/..$//g' | sed 's/^.*"//g')
export API_VERSION="${MAJOR}.${MINOR}"

DAT=$(date +"%y%m%d-%Hh%Mm")
gt=$(git log --format=oneline -1 | head -c 11)
REV="${DAT}_$gt"
popd >/dev/null

if [ "x$adm_version" = "x" ]; then
  export ADM_VERSION="${MAJOR}.${MINOR}.${PATCH}"
else
  export ADM_VERSION=$adm_version
fi
echo "Avidemux version : $ADM_VERSION"


# Qt Detection Logic
qmake_location=$(which qmake 2>/dev/null)

if [ -n "$MYQT" ] && [ -f "/usr/local/homebrew/bin/qmake" ]; then
  echo "Warning: Qt installation conflict with Homebrew. Unlink homebrew qt first."
  exit 1
fi

# Try to detect QTDIR via qmake if not set
if [ -z "$QTDIR" ]; then
  if [ -n "$MYQT" ] && [ -f "${MYQT}/bin/qmake" ]; then
     export QTDIR="$MYQT"
  elif [ -f "/usr/local/homebrew/opt/qt@6/bin/qmake" ]; then
     export QTDIR="/usr/local/homebrew/opt/qt@6"
  elif [ -f "/opt/homebrew/opt/qt@6/bin/qmake" ]; then # Apple Silicon Homebrew
     export QTDIR="/opt/homebrew/opt/qt@6"
  elif [ -n "$qmake_location" ]; then
     # Try to infer from qmake location
     # qmake usually in bin/
     export QTDIR=$(dirname $(dirname "$qmake_location"))
  fi
fi

if [ -z "$QTDIR" ] || [ ! -f "${QTDIR}/bin/qmake" ]; then
  echo "Error: No matching qmake executable found. Set QTDIR or MYQT, or ensure qmake is in PATH."
  exit 1
fi

echo "Using $QTDIR as Qt install path"
export PATH="$PATH":"${QTDIR}/bin"

# Setup Paths
if [ "x$create_app_bundle" = "x1" ]; then
  export BASE_APP="${BUILDTOP}/Avidemux${API_VERSION}.app"
  export PREFIX="${BASE_APP}/Contents/Resources"
  mkdir -p "${PREFIX}"
  export DO_BUNDLE="-DCREATE_BUNDLE=true"
else
  export BASE_APP="${BUILDTOP}/out"
  export PREFIX="${BASE_APP}"
  export DO_BUNDLE="-UCREATE_BUNDLE"
fi

install_prefix="$PREFIX"

# Common CMake flags for macOS
export CMAKE_EXTRA_FLAGS="-DCMAKE_OSX_ARCHITECTURES=$arch -DAVIDEMUX_VERSION=$ADM_VERSION -DAVIDEMUX_SOURCE_DIR=$SRCTOP"

# External libs flags
if [ "x$external_liba52" = "x1" ]; then
  EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_LIBA52=true $EXTRA_CMAKE_DEFS"
fi
if [ "x$external_libmad" = "x1" ]; then
  EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_LIBMAD=true $EXTRA_CMAKE_DEFS"
fi
if [ "x$external_libmp4v2" = "x1" ]; then
  EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_MP4V2=true $EXTRA_CMAKE_DEFS"
fi

if [ "x$do_core" = "x1" ]; then
  echo "** CORE **"
  Process buildCore "${SRCTOP}/avidemux_core" "$DO_BUNDLE"
fi
if [ "x$do_qt" = "x1" ]; then
  echo "** QT **"
  Process build${qt_ext} "${SRCTOP}/avidemux/qt4" "$DO_BUNDLE $qt_flavor"
fi
if [ "x$do_cli" = "x1" ]; then
  echo "** CLI **"
  Process buildCli "${SRCTOP}/avidemux/cli"
fi
if [ "x$do_plugins" = "x1" ]; then
  echo "** Plugins **"
  Process buildPluginsCommon "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=COMMON $EXTRA_CMAKE_DEFS"
fi
if [ "x$do_plugins" = "x1" -a "x$do_qt" = "x1" ]; then
  echo "** Plugins Qt **"
  Process buildPlugins${qt_ext} "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=QT4 $EXTRA_CMAKE_DEFS $qt_flavor"
fi
if [ "x$do_plugins" = "x1" -a "x$do_cli" = "x1" ]; then
  echo "** Plugins CLI **"
  Process buildPluginsCLI "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=CLI $EXTRA_CMAKE_DEFS"
fi
if [ "x$do_plugins" = "x1" ]; then
  echo "** Plugins Settings **"
  Process buildPluginsSettings "${SRCTOP}/avidemux_plugins" "-DPLUGIN_UI=SETTINGS $EXTRA_CMAKE_DEFS"
fi

# Bundle Finalization
cd "$BUILDTOP"
if [ "x$create_app_bundle" = "x1" ]; then
  mkdir -p "${PREFIX}/fonts"
  cp "${SRCTOP}/avidemux/qt4/cmake/osx/fonts.conf" "${PREFIX}/fonts"
  echo "Copying icons"
  cp "${SRCTOP}"/avidemux/qt4/cmake/osx/*.icns "$PREFIX"
  mkdir -p "${PREFIX}"/../MacOS
  if [ -d "${PREFIX}"/../PlugIns ]; then
    rm -Rf "${PREFIX}"/../PlugIns
  fi
  mkdir -p "${PREFIX}"/../PlugIns
  # Symlink lib directory
  if [ -e "${PREFIX}"/../lib ]; then
    rm "${PREFIX}"/../lib
  fi
  ln -s "${PREFIX}/lib" "${PREFIX}"/../
  # Symlink Qt plugins
  # Verify where plugins are in the Qt install
  QT_PLUGINS="${QTDIR}/share/qt/plugins"
  if [ ! -d "$QT_PLUGINS" ]; then
     QT_PLUGINS="${QTDIR}/plugins"
  fi

  if [ -d "${QT_PLUGINS}/platforms" ]; then
    ln -s "${QT_PLUGINS}/platforms" "${PREFIX}"/../PlugIns/
  fi
  if [ -d "${QT_PLUGINS}/styles" ]; then
    ln -s "${QT_PLUGINS}/styles" "${PREFIX}"/../PlugIns/
  fi

  # Create qt.conf
  echo "[Paths]" >"${PREFIX}"/../Resources/qt.conf
  echo "Plugins = PlugIns" >>"${PREFIX}"/../Resources/qt.conf

  if [ "x$create_dmg" = "x1" ]; then
    if [ -e installer ]; then
      chmod -R +w installer 2>/dev/null
      rm -Rf installer
    fi
    mkdir installer
    cd installer

    # Need to run cmake to configure packaging
    # Using dummy source dir? No, avidemux/osxInstaller

    echo "** Preparing packaging **"
    cmake \
      -DAVIDEMUX_VERSION="$ADM_VERSION" \
      -DAVIDEMUX_MAJOR_MINOR="${MAJOR}.${MINOR}" \
      -DDMG_BASENAME="$dmg_base" \
      -DBUILD_REV="$REV" \
      $qt_flavor \
      "${SRCTOP}/avidemux/osxInstaller" || fail "cmake installer"

    make package || fail "make package"
  fi
fi
echo "** ALL DONE **"
