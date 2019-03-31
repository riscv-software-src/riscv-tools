#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common

echo "Starting RISC-V Toolchain build process"

check_version() {
    $1 --version | awk "NR==1 {if (\$NF>$2) {exit 0} exit 1}" || (
        echo $3 requires at least version $2 of $1. Aborting.
        exit 1
    )
}

check_version automake 1.14 "OpenOCD build"
check_version autoconf 2.64 "OpenOCD build"
build_project riscv-openocd --prefix=$RISCV --enable-remote-bitbang --enable-jtag_vpi --disable-werror

build_project riscv-isa-sim --prefix=$RISCV
build_project riscv-gnu-toolchain --prefix=$RISCV
CC= CXX= build_project riscv-pk --prefix=$RISCV --host=riscv64-unknown-elf
build_project riscv-tests --prefix=$RISCV/riscv64-unknown-elf

echo -e "\\nRISC-V Toolchain installation completed!"
