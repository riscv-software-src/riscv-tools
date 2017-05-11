#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common "$@"

echo "Starting RISC-V Toolchain build process, XLEN=$XLEN"

build_project riscv-openocd --prefix=$RISCV --enable-remote-bitbang
build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
build_project riscv-gnu-toolchain --prefix=$RISCV --with-xlen=${XLEN}
CC= CXX= build_project riscv-pk --prefix=$RISCV --host=riscv${XLEN}-unknown-elf
build_project riscv-tests --prefix=$RISCV/riscv${XLEN}-unknown-elf

echo -e "\\nRISC-V Toolchain installation completed!"
