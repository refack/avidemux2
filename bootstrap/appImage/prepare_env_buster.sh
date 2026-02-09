#!/bin/bash
# Prepare environment for Buster AppImage build
# Extracted from makeAppImageBusterMinimal.sh

nodeps=""
nofail=""
missing_pkgs=()

# build dependencies
BUILD_DEPS="build-essential \
cmake \
pkg-config \
yasm \
libsqlite3-dev \
libxv-dev \
libvdpau-dev \
libva-dev \
libasound2-dev \
libpulse-dev \
qtbase5-dev \
qttools5-dev-tools \
libx264-dev \
libx265-dev \
libxvidcore-dev \
libvpx-dev \
libmad0-dev \
libmp3lame-dev \
libtwolame-dev \
libopus-dev \
libvorbis-dev \
libogg-dev \
libass-dev \
squashfs-tools \
wget"

NONFREE_PACKAGES="libfaac-dev \
libfdk-aac-dev"

usage()
{
    echo "Usage: $0 [Options]"
    echo "***********************"
    echo "  --help or -h      : Print usage"
    echo "  --no-install-deps : Do not install missing dependencies, fail instead"
    echo "  --no-fail-missing : Try to continue even if dependencies are missing"
}

fail()
{
    echo "$@"
    exit 1
}

check_nvenc()
{
    if (pkg-config --exists ffnvcodec); then
        return 0
    elif [ "x${nodeps}" = "x1" ]; then
        echo "NVENC headers not found and installation disabled on command line."
        return 1
    fi
    echo "nv-codec-headers are missinng, will try to install."
    rm -rf /tmp/nvenc > /dev/null 2>&1
    mkdir /tmp/nvenc || return 1
    cd /tmp/nvenc || return 1
    git clone https://github.com/FFmpeg/nv-codec-headers.git || return 1
    cd nv-codec-headers || return 1
    # Get the most recent version still compatible with NVIDIA drivers
    # from the non-free buster-backports repo.
    git checkout sdk/11.1 || return 1
    make || return 1
    sudo make install || return 1
}

check_aom()
{
    if (pkg-config --exists aom); then
        echo "aom is present, checking version..."
        AOM_VERSION=$(pkg-config --modversion aom)
        if [ $(echo "${AOM_VERSION}" | cut -d \. -f 1 - ) -ge "3" ]; then
            echo "aom version ${AOM_VERSION} is sufficient."
            return 0
        elif [ "x${nodeps}" = "x1" ]; then
            echo "aom version is too old and installation disabled on command line."
            return 1
        fi
    elif [ "x${nodeps}" = "x1" ]; then
        echo "aom not found and installation disabled on command line."
        return 1
    fi
    echo "Minimum required version of aom is missing, will try to install."
    CUR=$(pwd)
    if ! [ -d "${CUR}/aom" ]
    then
        echo "Will clone aom source to current directory"
        git clone https://aomedia.googlesource.com/aom || return 1
    else
        echo "Trying to re-use existing aom source directory"
        git fetch || fail "Cannot fetch changes"
    fi
    cd "${CUR}/aom" && git checkout tags/v3.6.1 || return 1
    cd ..
    if [ -d "build-aom" ]
    then
        rm -rf "build-aom" || return 1
    fi
    mkdir "build-aom" || return 1
    cd build-aom || return 1
    cmake ../aom/ \
    -DENABLE_DOCS=0 \
    -DENABLE_EXAMPLES=0 \
    -DENABLE_TOOLS=0 \
    -DBUILD_SHARED_LIBS=1 \
    -DCONFIG_ANALYZER=0 \
    -DFORCE_HIGHBITDEPTH_DECODING=0 \
    -DCMAKE_INSTALL_PREFIX="/usr/local" || return 1
    make -j $(nproc) || return 1
    sudo make install || return 1
    return 0
}

check_deps()
{
    for i in $@; do
        state=$(dpkg -l $i 2>/dev/null | tail -n 1 | cut -d ' ' -f 1)
        if [ "${state}" != "ii" ] && [ "${state}" != "hi" ]; then
            missing_pkgs+=($i)
        fi
    done
}

setup()
{
    check_deps ${BUILD_DEPS}
    missing_required=(${missing_pkgs[*]})
    missing_pkgs=()
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo "Missing required development packages:"
        echo ${missing_required[*]}
    fi
    check_deps ${NONFREE_PACKAGES}
    missing_nonfree=(${missing_pkgs[*]})
    missing_pkgs=()
    if [ ${#missing_nonfree[@]} -gt 0 ]; then
        echo "Missing non-free development packages:"
        echo ${missing_nonfree[*]}
        if [ "x${nodeps}" != "x1" ]; then
            echo "Warning, non-free repositories must be already enabled on this system to install them."
        fi
    fi
    nb_missing=$(( ${#missing_required[@]} + ${#missing_nonfree[@]} ))
    if [ ${nb_missing} -gt 0 ]; then
        if [ "x${nodeps}" = "x1" ]; then
            fail "Installation of build dependencies disabled on command line, aborting."
        elif [ "x${nofail}" = "x1" ]; then
            echo "Trying to continue nevertheless"
        else
            sudo /usr/bin/apt-get update || fail "Cannot sync repo metadata"
            sudo /usr/bin/apt-get install ${missing_required[*]} ${missing_nonfree[*]} || fail "Failed to install all build dependencies, aborting."
        fi
    fi
    if (check_nvenc); then
        echo "NVENC headers found."
    elif [ "x${nofail}" = "x1" ]; then
        echo "Cannot install NVENC headers, trying to continue nevertheless."
    else
        fail "Cannot install NVENC headers."
    fi
    if (check_aom); then
        echo "libaom >= 3.0.0 found"
    elif [ "x${nofail}" = "x1" ]; then
        echo "Cannot install required version of libaom, trying to continue nevertheless."
    else
        fail "Cannot install required version of libaom."
    fi
}

# Main execution
ID=$(id -u)
if [ "x${ID}" = "x0" ]; then
    fail "Won't run as root, aborting."
fi

while [ $# != 0 ]; do
    config_option="$1"
    case "${config_option}" in
        -h|--help)
            usage
            exit 0
            ;;
        --no-install-deps)
            nodeps="1"
            ;;
        --no-fail-missing)
            nofail="1"
            ;;
        *)
            echo "unknown parameter ${config_option}"
            usage
            exit 1
            ;;
    esac
    shift
done

setup
