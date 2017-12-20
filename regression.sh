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
make -C ${base_dir}/riscv-tests/benchmarks/ run riscv

# test the pk
echo -e '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c
riscv64-unknown-elf-gcc -o hello hello.c
spike pk hello

# test glibc+pk
rm -rf ${base_dir}/riscv-gnu-toolchain/build
mkdir ${base_dir}/riscv-gnu-toolchain/build
cd ${base_dir}/riscv-gnu-toolchain/build
../configure --prefix=$RISCV
make linux
cd ${base_dir}; rm hello
riscv64-unknown-linux-gnu-gcc -static -Wl,-Ttext-segment,0x10000 -o hello hello.c
spike pk hello


echo -e "\\nRISC-V Toolchain regression completed!"
