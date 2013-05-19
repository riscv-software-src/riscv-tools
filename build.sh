#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common

echo "Starting RISC-V Toolchain build process"

build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
build_project riscv-gcc --prefix=$RISCV
build_project riscv-pk --prefix=$RISCV/target --host=riscv
build_tests

echo -e "\\nRISC-V Toolchain installation completed!"
