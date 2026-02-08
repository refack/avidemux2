#!/bin/bash
# Bootstrapper for MinGW/MXE

source "$(dirname "$0")/common.sh"

# Defaults
default_mxerootdir="/opt/mxe"
if [ -d "$default_mxerootdir" ]; then
    mxerootdir="$default_mxerootdir"
    use_mxe=1
else
    mxerootdir=""
    use_mxe=0
fi

rebuild=0
do_ninja=1
debug=0
do_core=1
do_qt=1
do_cli=1
do_plugins=1
external_liba52=0
external_libmad=0
do_release_pkg=1
author_setup=0
qt_ver=6

usage() {
  echo "Bootstrap Avidemux (MinGW/MXE):"
  echo "***********************"
  echo "  --help                 : Print usage"
  echo "  --debug                : Switch debugging on"
  echo "  --mxe-root=DIR         : Use MXE installed in DIR (default: ${default_mxerootdir})"
  echo "  --rebuild              : Preserve existing build directories"
  echo "  --with-core            : Build core (default)"
  echo "  --without-core         : Don't build core"
  echo "  --with-cli             : Build cli (default)"
  echo "  --without-cli          : Don't build cli application and plugins"
  echo "  --with-ninja           : Build with ninja (default)"
  echo "  --with-make            : Build with make"
  echo "  --with-qt              : Build Qt (default)"
  echo "  --without-qt           : Don't build Qt application and plugins"
  echo "  --with-plugins         : Build plugins (default)"
  echo "  --without-plugins      : Don't build plugins"
  echo "  --with-system-liba52   : Use the system liba52 (a52dec) instead of the bundled one"
  echo "  --with-system-libmad   : Use the system libmad instead of the bundled one"
  echo "  --nopkg                : Don't create a ZIP archive with all required libraries"
  echo "  -a, --author           : Match the env setup used by the Author, implies --nopkg"
}

while [ $# != 0 ]; do
  config_option="$1"
  case "$config_option" in
  -h | --help)
    usage
    exit 1
    ;;
  -a | --author)
    export author_setup=1
    do_release_pkg=0
    ;;
  --mxe-root=*)
    mxerootdir=$(dir_check $(option_name "$config_option") $(option_value "$config_option")) || exit 1
    use_mxe=1
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
  --with-ninja)
    do_ninja=1
    ;;
  --with-make)
    do_ninja=0
    ;;
  --with-core)
    do_core=1
    ;;
  --with-system-liba52)
    export external_liba52=1
    ;;
  --with-system-libmad)
    export external_libmad=1
    ;;
  --nopkg)
    do_release_pkg=0
    ;;
  *)
    echo "unknown parameter $config_option"
    usage
    exit 1
    ;;
  esac
  shift
done

authorSetup() {
  export SDLDIR=/mingw
  export MINGW=/mingw
  export MINGWDEV=/mingw_dev
  export PATH=${MINGW}/bin:$PATH
  export INSTALL_DIR=${MINGW}/Release
  export QT_HOME=/mingw/Qt/current
  export O_PARAL="-j 2"
  export TOOLCHAIN_LOCATION=/mingw
  export CFLAGS="-I/mingw/include -L/mingw/lib"
}

setupEnv() {
  export BITS="64"
  export BUILDDATE=$(date +%y%m%d-%H%M%S)
  export EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_LIBASS=true $EXTRA_CMAKE_DEFS"
  if [ "x$external_liba52" = "x1" ]; then
    export EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_LIBA52=true $EXTRA_CMAKE_DEFS"
  fi
  if [ "x$external_libmad" = "x1" ]; then
    export EXTRA_CMAKE_DEFS="-DUSE_EXTERNAL_LIBMAD=true $EXTRA_CMAKE_DEFS"
  fi
  export BUILDTOP=$PWD
  if [[ $BUILDTOP = *" "* ]]; then
    echo "The build directory path \"${BUILDTOP}\" contains one or more spaces."
    echo "This is unsupported by FFmpeg configure."
    fail "build prerequisites"
  fi
  export SRCTOP=$(cd $(dirname "$0")/.. && pwd)
  export ARCH="x86_64"
  export QT_SELECT=6

  if [ "x$author_setup" = "x1" ]; then
    authorSetup
    use_mxe=0
  elif [ "x$use_mxe" = "x1" ]; then
    export MXE_ROOT="$mxerootdir"
    export MXE_TARGET=${ARCH}-w64-mingw32.shared
    export MINGW="${MXE_ROOT}/usr/${MXE_TARGET}"
    export QT_HOME="${MINGW}/qt6"
    export QTDIR=${QT_HOME}
    export PATH="$PATH":"${MXE_ROOT}/usr/bin":"${QT_HOME}/bin"
    export TOOLCHAIN_LOCATION="${MXE_ROOT}"/usr
    export SDL2DIR="$MINGW"

    export CROSS_PREFIX=$MXE_TARGET
    export PKG_CONFIG_PATH="${MINGW}"/lib/pkgconfig
    export PKG_CONFIG_LIBDIR="${MINGW}"/lib/pkgconfig
    export CROSS_C_COMPILER=gcc
    export CROSS_CXX_COMPILER=g++

    # Flags for common.sh Process
    export COMPILER="-DCROSS=$MINGW \
    -DCMAKE_SYSTEM_NAME:STRING=Windows \
    -DCMAKE_FIND_ROOT_PATH=$MINGW \
    -DTOOLCHAIN_LOCATION=$TOOLCHAIN_LOCATION \
    -DCMAKE_C_COMPILER=${CROSS_PREFIX}-${CROSS_C_COMPILER} \
    -DCMAKE_CXX_COMPILER=${CROSS_PREFIX}-${CROSS_CXX_COMPILER} \
    -DCMAKE_LINKER=${CROSS_PREFIX}-ld \
    -DCMAKE_AR=${CROSS_PREFIX}-ar \
    -DCMAKE_RC_COMPILER=${CROSS_PREFIX}-windres"

  else
    # Native MinGW64 (e.g. MSYS2)
    echo "Using Native MinGW64 mode"
    if [ -z "$MINGW_PREFIX" ]; then
        export MINGW="/mingw64"
        if [ ! -d "$MINGW" ] && [ -d "/ucrt64" ]; then
             export MINGW="/ucrt64"
        fi
    else
        export MINGW="$MINGW_PREFIX"
    fi

    export QT_HOME="${MINGW}"
    export QTDIR=${QT_HOME}
    export PATH="${MINGW}/bin:$PATH"
    export SDL2DIR="$MINGW"
    export CROSS_PREFIX=""
    export PKG_CONFIG_PATH="${MINGW}"/lib/pkgconfig

    # We need to define CROSS so that avidemux picks up MinGW cmake files instead of VS
    export COMPILER="-DCROSS=$MINGW -DCMAKE_CROSS_PREFIX="
  fi

  echo "Using <${PATH}> as path"
  which lrelease 2>/dev/null

  if [ "x$debug" != "x1" ]; then
      export INSTALL_DIR="${MINGW}"/out/avidemux
  else
      export INSTALL_DIR="${MINGW}"/out_debug/avidemux
  fi
  # We use install_prefix variable for common.sh
  export install_prefix="$INSTALL_DIR"

  export CXXFLAGS="-std=c++17"

  # common.sh Process uses EXTRA_CMAKE_FLAGS
  export CMAKE_EXTRA_FLAGS="-DAVIDEMUX_TOP_SOURCE_DIR=$SRCTOP"
}

create_release_package() {
  if [ ! -e "${INSTALL_DIR}"/avidemux.exe ]; then
    echo "No avidemux.exe (${BITS} bit) found in ${INSTALL_DIR}, aborting"
    exit 1
  fi
  echo "Preparing package..."
  pushd "$BUILDTOP" >/dev/null
  PACKAGE_DIR="packaged_mingw_build_${BUILDDATE}"
  if [ "x$debug" = "x1" ]; then
    PACKAGE_DIR="packaged_mingw_debug_build_${BUILDDATE}"
  fi
  PACKAGE_DIR="${BUILDTOP}/${PACKAGE_DIR}"
  if [ ! -e "$PACKAGE_DIR" ]; then
    mkdir "$PACKAGE_DIR" || fail "creating package directory"
  fi
  cp -a "$INSTALL_DIR" "$PACKAGE_DIR"
  cd "$PACKAGE_DIR"
  mv -v avidemux avidemux_$BITS
  TARGETDIR="${PACKAGE_DIR}/avidemux_$BITS"
  if [ ! -e "${TARGETDIR}"/platforms ]; then
    mkdir "${TARGETDIR}"/platforms || fail "creating platforms directory"
  fi
  if [ ! -e "${TARGETDIR}"/styles ]; then
    mkdir "${TARGETDIR}"/styles || fail "creating styles directory"
  fi

  if [ "x$use_mxe" = "x1" ]; then
      BIN_DIR="${MINGW}/bin"
  else
      BIN_DIR="${MINGW}/bin"
  fi

  cd "$BIN_DIR"
  if [ "x${external_liba52}" = "x1" ]; then
    cp -v liba52-*.dll "$TARGETDIR"
  fi
  if [ "x${external_libmad}" = "x1" ]; then
    cp -v libmad-*.dll "$TARGETDIR"
  fi

  cp -v \
    libaom.dll \
    libass-*.dll \
    libbrotlicommon.dll \
    libbrotlidec.dll \
    libbz2.dll \
    libcrypto-*.dll \
    libexpat-*.dll \
    libfaad-*.dll \
    libfdk-aac-*.dll \
    libffi-*.dll \
    libfontconfig-*.dll \
    libfreetype-*.dll \
    libfribidi-*.dll \
    libgcc_*.dll \
    libglib-*.dll \
    libgobject-*.dll \
    libharfbuzz-0.dll \
    libiconv-*.dll \
    icudt*.dll \
    icuin*.dll \
    icuuc*.dll \
    libintl-*.dll \
    libmp3lame-*.dll \
    libogg-*.dll \
    libopus-*.dll \
    libpcre2-16-*.dll \
    libpcre2-8-*.dll \
    libpng16-*.dll \
    libsamplerate-*.dll \
    libssl-*.dll \
    libssp-*.dll \
    libstdc++-*.dll \
    libvorbis-*.dll \
    libvorbisenc-*.dll \
    libvorbisfile-*.dll \
    libwinpthread-*.dll \
    libx264-*.dll \
    libx265.dll \
    libopencore*.dll \
    libzstd.dll \
    SDL2.dll \
    xvidcore.dll \
    zlib1.dll \
    "$TARGETDIR"

  if [ -f libsqlite3-*.dll ]; then
    cp -v libsqlite3-*.dll "$TARGETDIR"
  else
    echo "Warning: no libsqlite3 DLL in default location, trying alternate."
    if [ -d "${MINGW}/lib" ]; then
        cd "${MINGW}"/lib
        cp -v libsqlite3*.dll "$TARGETDIR"
    fi
  fi

  if [ "x$use_mxe" = "x1" ]; then
      cd "$QT_HOME"
      cp -v \
        bin/Qt6Core.dll \
        bin/Qt6Gui.dll \
        bin/Qt6Network.dll \
        bin/Qt6OpenGL.dll \
        bin/Qt6OpenGLWidgets.dll \
        bin/Qt6Widgets.dll \
        "$TARGETDIR"
  else
      # Native Qt6
      cd "${MINGW}/bin"
      cp -v \
        Qt6Core.dll \
        Qt6Gui.dll \
        Qt6Network.dll \
        Qt6OpenGL.dll \
        Qt6OpenGLWidgets.dll \
        Qt6Widgets.dll \
        "$TARGETDIR"
  fi

  if [ "x$use_mxe" = "x1" ]; then
      cd "$QT_HOME"
      cp -v \
        plugins/platforms/qminimal.dll \
        plugins/platforms/qwindows.dll \
        "${TARGETDIR}"/platforms/
      cp -v \
        plugins/styles/qmodernwindowsstyle.dll \
        "${TARGETDIR}"/styles/
  else
      PLUGINS_DIR="${MINGW}/share/qt6/plugins"
      if [ ! -d "$PLUGINS_DIR" ]; then
           PLUGINS_DIR="${MINGW}/plugins"
      fi

      if [ -d "$PLUGINS_DIR" ]; then
        cd "$PLUGINS_DIR"
        cp -v \
            platforms/qminimal.dll \
            platforms/qwindows.dll \
            "${TARGETDIR}"/platforms/
        cp -v \
            styles/qmodernwindowsstyle.dll \
            "${TARGETDIR}"/styles/
      fi
  fi

  mkdir "${TARGETDIR}"/etc || fail "creating etc directory"
  cp -rvL "${MINGW}"/etc/fonts "${TARGETDIR}"/etc
  cd "$TARGETDIR"
  if [ ! "x$debug" = "x1" ]; then
    find . -name "*.dll.a" -exec rm -v '{}' \;
    rm -Rf include
  fi
  cd "$PACKAGE_DIR"
  zip -r avidemux_r${BUILDDATE}_win${BITS}Qt6.zip avidemux_$BITS
  rm -Rf avidemux_$BITS
  popd >/dev/null
  echo "Avidemux Windows package generated as \"${PACKAGE_DIR}/avidemux_r${BUILDDATE}_win${BITS}Qt6.zip\""
}

setupEnv

echo "** Bootstrapping Avidemux (MinGW) **"
if [ "x$author_setup" = "x1" ]; then
  rm -Rf "${MINGWDEV}"/*
fi
if [ -e "$INSTALL_DIR" -a "x$do_core" = "x1" -a "x$do_qt" = "x1" ]; then
  rm -Rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
echo "Build top dir : $BUILDTOP"

# Process calls
if [ "x$do_core" = "x1" ]; then
  echo "** CORE **"
  Process buildMingwCore-${ARCH} "${SRCTOP}"/avidemux_core "-DCMAKE_CROSS_PREFIX=${CROSS_PREFIX}"
fi

if [ "x$do_qt" = "x1" ]; then
  echo "** QT **"
  Process buildMingwQt6-${ARCH} "${SRCTOP}"/avidemux/qt4 "-DQT_HOME:STRING=${QT_HOME} -DENABLE_QT6=true"
fi

if [ "x$do_cli" = "x1" ]; then
  echo "** CLI **"
  Process buildMingwCli-${ARCH} "${SRCTOP}"/avidemux/cli
fi

if [ "x$do_plugins" = "x1" ]; then
  echo "** Plugins **"
  Process buildMingwPluginsCommon-${ARCH} "${SRCTOP}"/avidemux_plugins "-DPLUGIN_UI=COMMON $EXTRA_CMAKE_DEFS"
fi

if [ "x$do_plugins" = "x1" -a "x$do_qt" = "x1" ]; then
  echo "** Plugins Qt **"
  Process buildMingwPluginsQt6-${ARCH} "${SRCTOP}"/avidemux_plugins "-DPLUGIN_UI=QT4 -DQT_HOME:STRING=$QT_HOME -DENABLE_QT6=true $EXTRA_CMAKE_DEFS"
fi

if [ "x$do_plugins" = "x1" -a "x$do_cli" = "x1" ]; then
  echo "** Plugins CLI **"
  Process buildMingwPluginsCli-${ARCH} "${SRCTOP}"/avidemux_plugins "-DPLUGIN_UI=CLI $EXTRA_CMAKE_DEFS"
fi

if [ "x$do_plugins" = "x1" ]; then
  echo "** Plugins Settings **"
  Process buildMingwPluginsSettings-${ARCH} "${SRCTOP}"/avidemux_plugins "-DPLUGIN_UI=SETTINGS $EXTRA_CMAKE_DEFS"
fi

if [ "x$do_release_pkg" = "x1" ]; then
  create_release_package
fi

echo "** All done **"
