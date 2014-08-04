riscv-tools [![Build Status](https://travis-ci.org/ucb-bar/riscv-tools.svg?branch=master)](https://travis-ci.org/ucb-bar/riscv-tools) [View on Github](http://github.com/ucb-bar/riscv-tools)
===========

Quick and dirty instructions:

```sh
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain
$ ./build.sh
```

Ubuntu packages needed:

```sh
$ sudo apt-get install autoconf automake autotools-dev libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo
```

Note: This requires GCC >= 4.8 for C++11 support (including thread_local).
To use a compiler different than the default (for example on OS X), use:
$ CC=gcc-4.8 CXX=g++-4.8 ./build.sh
