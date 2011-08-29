#! /bin/bash
#
# script to build RISC-V ISA simulator, frontend server, proxy kernel and newlib based GNU toolchain
# NOTE: You must set INSTALL_PREFIX to the directory where you want things to be installed

INSTALL_PREFIX=UNCONFIGURED

if [ "$INSTALL_PREFIX" = "UNCONFIGURED" ]
then
  echo "ERROR: You must edit this script and define INSTALL_PREFIX!"
  exit 1
fi

INSTALL_BINDIR=${INSTALL_PREFIX}/bin
PATH=$INSTALL_BINDIR:$PATH
GCC_VERSION=`gcc -v 2>&1 | tail -1 | awk '{print $3}'`

set -e

function build_project {
  if [ -e "${PROJECT}/build" ]
  then
    echo "Removing existing ${PROJECT}/build directory"
    rm -rf ${PROJECT}/build
  fi
  echo "Building project ${PROJECT}"
  cd ${PROJECT}
  mkdir build
  cd build
  ../configure --prefix=${INSTALL_PREFIX} $1
  make -j 2>&1 | tee make.log
  echo "Installing project ${PROJECT}"
  make install 2>&1 | tee make-install.log
  cd ../..
}

echo "Starting RISC-V Toolchain build process"

# build ISA simulator
PROJECT=riscv-isa-sim
if [ "$GCC_VERSION" == "4.4.3" ]
then
  echo "Detected GCC version 4.4.3 - using GCC 4.1 instead"
  export CC=gcc-4.1
  export CPP=cpp-4.1
  export CXX=g++-4.1
fi
build_project
unset CC CPP CXX

# build frontend server
PROJECT=riscv-fesvr
build_project

# build GCC toolchain
PROJECT=riscv-gcc-newlib
build_project

# build proxy kernel
PROJECT=riscv-pk
build_project --host=riscv

# rebuild ISA simulator, now it should find libraries necessary for disassembly
PROJECT=riscv-isa-sim
rm -rf ${PROJECT}/build
if [ "$GCC_VERSION" == "4.4.3" ]
then
  echo "Detected GCC version 4.4.3 - using GCC 4.1 instead"
  export CC=gcc-4.1
  export CPP=cpp-4.1
  export CXX=g++-4.1
fi
build_project
unset CC CPP CXX

echo "RISC-V Toolchain installation completed!"
