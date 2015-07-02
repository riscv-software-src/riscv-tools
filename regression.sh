#! /bin/bash
#
# Script to build RISC-V tools and then test (some of) them.

set -ex

echo "Starting RISC-V Toolchain Regression"

# build the tools
export base_dir=${PWD}
mkdir -p regression_install
export RISCV=${base_dir}/regression_install
./build.sh

# test the tools
export PATH="$RISCV/bin:$PATH"
make -C ${base_dir}/riscv-tests/isa/ run
make -C ${base_dir}/riscv-tests/benchmarks/ run-riscv


echo -e "\\nRISC-V Toolchain regression completed!"
