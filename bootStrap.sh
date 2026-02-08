#!/bin/bash
# Universal Bootstrapper for Avidemux

TARGET=""
ARGS=()

# Parse arguments to find --target
for arg in "$@"; do
  if [[ "$arg" == --target=* ]]; then
    TARGET="${arg#*=}"
  elif [[ "$arg" == "--msvc" ]]; then
    TARGET="win_msvc"
  else
    ARGS+=("$arg")
  fi
done

if [ -z "$TARGET" ]; then
  OS=$(uname -s)
  case "$OS" in
    Linux*)     TARGET="linux" ;;
    Darwin*)    TARGET="macos" ;;
    Haiku*)     TARGET="haiku" ;;
    MINGW*)     TARGET="mingw" ;;
    MSYS*)      TARGET="mingw" ;;
    CYGWIN*)    TARGET="mingw" ;;
    *)          echo "Unknown OS: $OS. Please use --target=linux|macos|mingw|haiku|win_msvc"; exit 1 ;;
  esac
fi

SCRIPT_DIR="$(dirname "$0")/bootStrap"
SCRIPT=""

case "$TARGET" in
  linux)    SCRIPT="$SCRIPT_DIR/linux.sh" ;;
  macos)    SCRIPT="$SCRIPT_DIR/macos.sh" ;;
  mingw)    SCRIPT="$SCRIPT_DIR/mingw.sh" ;;
  haiku)    SCRIPT="$SCRIPT_DIR/haiku.sh" ;;
  win_msvc) SCRIPT="$SCRIPT_DIR/win_msvc.sh" ;;
  *)        echo "Unknown target: $TARGET"; exit 1 ;;
esac

if [ ! -f "$SCRIPT" ]; then
  echo "Script not found: $SCRIPT"
  exit 1
fi

# Make sure the script is executable
if [ ! -x "$SCRIPT" ]; then
  chmod +x "$SCRIPT"
fi

echo "Redirecting to $SCRIPT with args: ${ARGS[@]}"
exec "$SCRIPT" "${ARGS[@]}"
