#!/usr/bin/env bash
################################################################################
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
################################################################################
#
# This script will install the llvm toolchain on the different
# Debian and Ubuntu versions

set -eux

# read optional command line argument
LLVM_VERSION=11
if [ "$#" -eq 1 ]; then
  LLVM_VERSION=$1
fi

DISTRO=$(lsb_release -is)
VERSION=$(lsb_release -sr)
DIST_VERSION="${DISTRO}_${VERSION}"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!"
  exit 1
fi

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9"
LLVM_VERSION_PATTERNS[10]="-10"
LLVM_VERSION_PATTERNS[11]=""

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
  echo "This script does not support LLVM version $LLVM_VERSION"
  exit 3
fi

LLVM_VERSION_STRING=${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}

# find the right repository name for the distro and version
case "$DIST_VERSION" in
  Debian_9*) REPO_NAME="deb http://apt.llvm.org/stretch/  llvm-toolchain-stretch$LLVM_VERSION_STRING main" ;;
  Debian_10*) REPO_NAME="deb http://apt.llvm.org/buster/   llvm-toolchain-buster$LLVM_VERSION_STRING  main" ;;
  Debian_unstable) REPO_NAME="deb http://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;
  Debian_testing) REPO_NAME="deb http://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;
  Ubuntu_16.04) REPO_NAME="deb http://apt.llvm.org/xenial/   llvm-toolchain-xenial$LLVM_VERSION_STRING  main" ;;
  Ubuntu_18.04 | LinuxMint_19.2 | LinuxMint_19.3) REPO_NAME="deb http://apt.llvm.org/bionic/   llvm-toolchain-bionic$LLVM_VERSION_STRING  main" ;;
  Ubuntu_18.10) REPO_NAME="deb http://apt.llvm.org/cosmic/   llvm-toolchain-cosmic$LLVM_VERSION_STRING  main" ;;
  Ubuntu_19.04) REPO_NAME="deb http://apt.llvm.org/disco/    llvm-toolchain-disco$LLVM_VERSION_STRING   main" ;;
  Ubuntu_19.10) REPO_NAME="deb http://apt.llvm.org/eoan/      llvm-toolchain-eoan$LLVM_VERSION_STRING    main" ;;
  Linuxmint_20 | Ubuntu_20.04) REPO_NAME="deb http://apt.llvm.org/focal/     llvm-toolchain-focal$LLVM_VERSION_STRING    main" ;;
  *)
    echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
    exit 2
    ;;
esac

# install everything
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
add-apt-repository "${REPO_NAME}"
apt update
apt install -y clang-"$LLVM_VERSION" clang-tools-"$LLVM_VERSION" clang-"$LLVM_VERSION"-doc libclang-common-"$LLVM_VERSION"-dev libclang-"$LLVM_VERSION"-dev libclang1-"$LLVM_VERSION" clang-format-"$LLVM_VERSION" clangd-"$LLVM_VERSION" libc++-"$LLVM_VERSION"-dev lld-"$LLVM_VERSION" llvm llvm-"$LLVM_VERSION"-dev
if [ "$LLVM_VERSION" -lt 11 ]; then
  apt install -y python-clang-"$LLVM_VERSION"
fi
update-alternatives --remove-all "cc"
update-alternatives --remove-all "c++"
update-alternatives --remove-all "clang"
update-alternatives --remove-all "clang++"
update-alternatives --remove-all "lld"
update-alternatives --remove-all "ld.lld"
update-alternatives --remove-all "clangd"
update-alternatives --install "/usr/bin/cc" "cc" "$(command -v clang-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/c++" "c++" "$(command -v clang++-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/clang" "clang" "$(command -v clang-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/clang++" "clang++" "$(command -v clang++-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/lld" "lld" "$(command -v lld-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/ld.lld" "ld.lld" "$(command -v ld.lld-"$LLVM_VERSION")" 1
update-alternatives --install "/usr/bin/clangd" "clangd" "$(command -v clangd-"$LLVM_VERSION")" 1
