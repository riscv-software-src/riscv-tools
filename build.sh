#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common

echo "Starting RISC-V Toolchain build process"

set -e
set -o pipefail

while [[ "$1" != "" ]]
do
    case $1 in
    --xlen)       xlen="$2"; shift;;
    --linux)      elin="--enable-linux"; platform="linux-gnu";;
    --elf)        elin="--disable-linux"; platform="elf";;
    --RVG)        isa="--enable-atomic --enable-float"; spike_isa="G";;
    --RVI)        isa="--disable-atomic --disable-float"; spike_isa="I";;
    *)            echo "Unrecongnized option:$1"; exit 1;;
    esac

    shift
done

build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
build_project riscv-gnu-toolchain --prefix=$RISCV $elin --with-xlen=$xlen --disable-multilib $isa
CC= CXX= build_project riscv-pk --prefix=$RISCV/riscv$xlen-unknown-$platform --host=riscv$xlen-unknown-$platform
RISCV_PREFIX="riscv$xlen-unknown-$platform-" RISCV_SIM="spike --isa=RV$xlen$spike_isa " XLEN=$xlen build_project riscv-tests --prefix=$RISCV/riscv$xlen-unknown-$platform --host=riscv$xlen-unknown-$platform

echo -e "\\nRISC-V Toolchain installation completed!"
