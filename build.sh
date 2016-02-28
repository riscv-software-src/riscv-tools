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
    --linux)      tool_flags="--enable-linux"; platform="linux-gnu";;
    --elf)        tool_flags="--disable-linux"; platform="elf";;
    --RVG)        isa="G";;
    --RVI)        isa="I"; pk_flags="--disable-atomics";;
    *)            echo "Unrecongnized option:$1"; exit 1;;
    esac

    shift
done

build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
build_project riscv-gnu-toolchain --prefix=$RISCV $tool_flags --disable-multilib --with-xlen=$xlen --with-arch=$isa
CC= CXX= build_project riscv-pk --prefix=$RISCV/riscv$xlen-unknown-$platform --host=riscv$xlen-unknown-$platform $pk_flags
RISCV_PREFIX="riscv$xlen-unknown-$platform-" RISCV_SIM="spike --isa=RV$xlen$isa " XLEN=$xlen build_project riscv-tests --prefix=$RISCV/riscv$xlen-unknown-$platform --host=riscv$xlen-unknown-$platform

echo -e "\\nRISC-V Toolchain installation completed!"
