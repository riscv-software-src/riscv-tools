#!/bin/bash

#####################################################################
# Setup
#####################################################################
TOP="$(pwd)"

# In order to actually run the regression tests we need to setup some
# enviornment variables.
export RISCV="$(pwd)/regression-workdir"
export PATH="$RISCV/bin:$PATH"

# Clean anything that was installed, just in case it's left over from
# a previous regression test run.
rm -rf "$RISCV"

# Fetch all the latest source code and build everything that's built
# by default.
git submodule update --init --recursive
./build.sh

#####################################################################
# Tests
#####################################################################

# Run the RISC-V assembly tests in Spike -- this is really just a
# sanity test, it doesn't test a whole lot.
cd "$TOP"/riscv-tests
./configure
make
make -C isa run
