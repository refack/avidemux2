#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

fail() {
  echo -e "${RED}** Failed at $1 **${ENDCOLOR}"
  exit 1
}

option_value() {
  echo $(echo $* | cut -d '=' -f 2-)
}

option_name() {
  echo $(echo $* | cut -d '=' -f 1 | cut -b 3-)
}

dir_check() {
  op_name="$1"
  dir_path="$2"
  if [ "x$dir_path" != "x" ]; then
    if [[ "$dir_path" != /* ]]; then
      >&2 echo "Expected an absolute path for --$op_name=$dir_path, aborting."
      exit 1
    fi
  else
    >&2 echo "Empty path provided for --$op_name, aborting."
    exit 1
  fi
  case "$dir_path" in
  */)
    echo $(expr "x$dir_path" : 'x\(.*[^/]\)') # strip trailing slashes
    ;;
  *)
    echo "$dir_path"
    ;;
  esac
}

printModule() {
  value=$1
  name=$2
  if [ "x$value" = "x1" ]; then
    echo -e "${GREEN}    $name will be built${ENDCOLOR}"
  else
    echo "     $name will be skipped"
  fi
}

# Generic Process function
# Variables expected to be set by the caller or environment:
# - do_ninja: 1 to use Ninja, 0 for Make (default)
# - debug: 1 for Debug build
# - rebuild: 1 to keep build dir
# - install_prefix: CMake install prefix
# - FAKEROOT_DIR: Fakeroot directory
# - FAKEROOT_COMMAND: Command to run fakeroot (optional)
# - PKG: CMake package flags (optional)
# - COMPILER: CMake compiler flags (optional)
# - BUILD_QUIRKS: Any build quirks (optional)
# - ASAN: ASAN flags (optional)
# - EXTRA_CMAKE_ARGS: Any extra cmake args passed to Process
# - CMAKE_EXTRA_FLAGS: Any extra cmake flags global
Process() {
  BASE=$1
  SOURCEDIR=$2
  EXTRA_ARGS=$3

  if [ "x$do_ninja" = "x1" ]; then
    BUILDER="Ninja"
    MAKER="ninja"
  else
    BUILDER="Unix Makefiles"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        NPROC=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 2)
    else
        NPROC=$(nproc 2>/dev/null || echo 2)
    fi
    MAKER="make -j $NPROC"
  fi

  DEBUG_FLAGS=""
  if [ "x$debug" = "x1" ]; then
    DEBUG_FLAGS="-DVERBOSE=1 -DCMAKE_BUILD_TYPE=Debug"
    BASE="${BASE}_debug"
    # Some scripts switch builder for debug, but Ninja handles debug fine.
    # We can stick to requested builder or default.
  fi

  ASAN_FLAGS=""
  if [ "x$do_asan" = "x1" ]; then
    BASE="${BASE}_asan"
    ASAN_FLAGS="-DASAN=True"
  fi

  BUILDDIR="${PWD}/${BASE}"
  FAKEROOT_FLAG=""
  if [ -n "$FAKEROOT_DIR" ]; then
    FAKEROOT_FLAG="-DFAKEROOT=$FAKEROOT_DIR"
  fi

  INSTALL_PREFIX_FLAG=""
  if [ -n "$install_prefix" ]; then
    INSTALL_PREFIX_FLAG="-DCMAKE_INSTALL_PREFIX=$install_prefix"
  fi

  echo -e "${GREEN}${BASE}: Building in \"${BUILDDIR}\" from \"${SOURCEDIR}\" with EXTRA=<${EXTRA_ARGS}>, DEBUG=<${DEBUG_FLAGS}>, MAKER=<${MAKER}> ${ENDCOLOR}"

  if [ "x$rebuild" != "x1" ]; then
    rm -Rf "${BUILDDIR}"
  fi

  if [ ! -e "$BUILDDIR" ]; then
    mkdir -p "${BUILDDIR}" || fail "creating build directory $BUILDDIR"
  fi

  pushd "${BUILDDIR}" >/dev/null || fail "entering build directory $BUILDDIR"

  echo "   $BASE: CMake started..."

  cmake \
    $COMPILER \
    $PKG \
    $FAKEROOT_FLAG \
    $INSTALL_PREFIX_FLAG \
    $EXTRA_ARGS \
    $BUILD_QUIRKS \
    $ASAN_FLAGS \
    $DEBUG_FLAGS \
    $CMAKE_EXTRA_FLAGS \
    -G "$BUILDER" \
    "$SOURCEDIR" >&/tmp/logCmake$BASE || fail "cmake, result in /tmp/logCmake$BASE"

  echo "   $BASE: Build started..."
  ${MAKER} >&/tmp/log$BASE || fail "${MAKER}, result in /tmp/log$BASE"

  if [ "x$PKG" != "x" ] && [ -n "$FAKEROOT_COMMAND" ]; then
     # For packaging
     DESTDIR="${FAKEROOT_DIR}/tmp" $FAKEROOT_COMMAND ${MAKER} package || fail "packaging"
  fi

  echo "   $BASE: Install started..."
  # If DESTDIR is set in environment it will affect make install
  # Some scripts set DESTDIR explicitly.
  # In bootStrap.bash: DESTDIR="${FAKEROOT_DIR}" ${MAKER} install
  # So we should probably do that if FAKEROOT_DIR is set.

  INSTALL_CMD="${MAKER} install"
  if [ -n "$FAKEROOT_DIR" ]; then
      export DESTDIR="${FAKEROOT_DIR}"
  fi

  ${INSTALL_CMD} >&/tmp/logInstall$BASE || fail "install failed, see /tmp/logInstall$BASE"

  if [ -n "$FAKEROOT_DIR" ]; then
      unset DESTDIR
  fi

  popd >/dev/null
  echo "   Done $BASE"
}
