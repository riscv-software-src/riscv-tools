#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

with_xlen=64
while [[ "$1" != "" ]]
do
   case "$1" in
   --with-xlen=*) with_xlen="$(echo "$1" | cut -d= -f2-)" ;;
   *) echo "Unknown argument $1" >2; exit 1;;
   esac
   shift
done

. build.common

echo "Starting RISC-V Toolchain build process"

build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
build_project riscv-gnu-toolchain --prefix=$RISCV --with-xlen="$with_xlen"
CC= CXX= build_project riscv-pk --prefix=$RISCV/riscv"$with_xlen"-unknown-elf --host=riscv"$with_xlen"-unknown-elf
build_project riscv-tests --prefix=$RISCV/riscv"$with_xlen"-unknown-elf --with-xlen="$with_xlen"

echo -e "\\nRISC-V Toolchain installation completed!"
