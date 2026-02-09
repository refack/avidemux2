#!/bin/bash
# AppImage builder for Bookworm (Minimal)
# Requires environment to be prepared via prepare_env_bookworm.sh

cd "$(dirname "$0")/../.."

usage()
{
    echo "Usage: $0 [Options]"
    echo "***********************"
    echo "  --help or -h      : Print usage"
    echo "  --rebuild         : Preserve existing build directories"
}

fail()
{
    echo "$@"
    exit 1
}

nobuild=""
rebuild=""

while [ $# != 0 ]; do
    config_option="$1"
    case "${config_option}" in
        -h|--help)
            usage
            exit 0
            ;;
        --rebuild)
            rebuild="${config_option}"
            ;;
        *)
            echo "unknown parameter ${config_option}"
            usage
            exit 1
            ;;
    esac
    shift
done

RUNTIME="runtime-x86_64"
RT_DIR="externalBinaries/AppImageKit"
SHA256SUM="24da8e0e149b7211cbfb00a545189a1101cb18d1f27d4cfc1895837d2c30bc30" # size: 188392 bytes
TO_CHECK=""
DO_DOWNLOAD=0
echo "Current directory: \"${PWD}\""
if [ ! -e "${RT_DIR}" ]; then
    mkdir -p "${RT_DIR}" || exit 1
fi
pushd "${RT_DIR}" > /dev/null || exit 1
if [ -f "${RUNTIME}" ]; then
    TO_CHECK=$(sha256sum "${RUNTIME}" | cut -d ' ' -f 1)
    if [ "${SHA256SUM}" != "${TO_CHECK}" ]; then
        echo "Checksum doesn't match, will try to re-download."
        rm -f "${RUNTIME}" > /dev/null 2>&1
        DO_DOWNLOAD=1
    else
        echo "${RUNTIME} has passed the check."
    fi
else
    echo "AppImageKit runtime is missing, will try to download."
    DO_DOWNLOAD=1
fi
if [ "x${DO_DOWNLOAD}" = "x1" ]; then
    URL="https://github.com/AppImage/AppImageKit/releases/download/12/runtime-x86_64"
    wget -O "${RUNTIME}" "${URL}" || exit 1
    TO_CHECK=$(sha256sum "${RUNTIME}" | cut -d ' ' -f 1)
fi
popd > /dev/null
if [ "${SHA256SUM}" != "${TO_CHECK}" ]; then
    echo "Checksum doesn't match, aborting."
    exit 1
fi

rm -rf install > /dev/null 2>&1

if [ -z "${QTDIR}" ]; then
    export QTDIR="/usr/lib/qt6"
fi

# Build
bash bootstrap/scripts/linux.sh --with-system-libmad ${rebuild} 2>&1 || fail "Build failed, please inspect /tmp/log* files."

# Package
bash bootstrap/appImage/deployBookwormMinimal.sh "${PWD}/${RT_DIR}/${RUNTIME}"
exit $?
