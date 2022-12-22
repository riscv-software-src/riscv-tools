#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common

echo "Starting RISC-V Toolchain build process"

build_project riscv-isa-sim --prefix=$RISCV --with-isa=rv32ima
CC= CXX= build_project riscv-pk --prefix=$RISCV --host=riscv32-unknown-elf
(cd riscv-openocd && ./bootstrap)
build_project riscv-openocd --prefix=$RISCV --enable-remote-bitbang --enable-jtag_vpi --disable-werror --disable-jlink

echo -e "\\nRISC-V Toolchain installation completed!"
