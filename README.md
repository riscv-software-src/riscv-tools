riscv-tools [![Build Status](https://travis-ci.org/riscv/riscv-tools.svg?branch=master)](https://travis-ci.org/riscv/riscv-tools)
===========================================================================

This repository houses a set of RISC-V simulators and other tools,
including the following projects:

* [Spike](https://github.com/riscv/riscv-isa-sim/), the ISA simulator
* [riscv-tests](https://github.com/riscv/riscv-tests/), a battery of
ISA-level tests
* [riscv-opcodes](https://github.com/riscv/riscv-opcodes/), the
enumeration of all RISC-V opcodes executable by the simulator
* [riscv-pk](https://github.com/riscv/riscv-pk/), which contains `bbl`,
a boot loader for Linux and similar OS kernels, and `pk`, a proxy kernel that
services system calls for a target-machine application by forwarding them to
the host machine

Several RISC-V tools that were previously maintained through this
repository have since been upstreamed to their parent projects and are
no longer included here.  Your favorite software distribution should
already have packages for these upstream tools, but if it doesn't then
here are a handful of my favorites:

* Your favorite software distribution may already have packages that
  include a RISC-V cross compiler, which is probably the fastest way to
  get started.  As of writing this README (March, 2019) I can trivially
  find packages for ALT Linux, Arch Linux, Debian, Fedora, FreeBSD,
  Mageia, OpenMandriva, openSUSE, and Ubuntu.
  [pkgs.org](https://pkgs.org/) appears to be a good place to find an up
  to date list, just search for "riscv".
* [crosstool-ng](http://crosstool-ng.github.io/docs/) can build RISC-V
  cross compilers of various flavors.
* The [RISC-V Port of
  OpenEmbedded](https://github.com/riscv/meta-riscv#quick-start)
  builds a cross compiler, Linux kernel, and enough of userspace to do
  many interesting things.
* [buildroot](https://github.com/buildroot/buildroot) is a lighter
  weight cross compiled Linux distribution.

This repository uses crosstool-ng to configure a `riscv64-unknown-elf`
toolchain.

# <a name="quickstart"></a>Quickstart

	$ git submodule update --init --recursive
	$ export RISCV=/path/to/install/riscv/toolchain
	$ ./build.sh


Ubuntu packages needed:

	$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev

Fedora packages needed:

	$ sudo dnf install autoconf automake @development-tools curl dtc libmpc-devel mpfr-devel gmp-devel libusb-devel gawk gcc-c++ bison flex texinfo gperf libtool patchutils bc zlib-devel expat-devel

_Note:_ This requires a compiler with C++11 support (e.g. GCC >= 4.8).
To use a compiler different than the default, use:

	$ CC=gcc-5 CXX=g++-5 ./build.sh

_Note for OS X:_ We recommend using [Homebrew](https://brew.sh) to install the dependencies (`libusb dtc gawk gnu-sed gmp mpfr libmpc isl wget automake md5sha1sum`) or even to install the tools [directly](https://github.com/riscv/homebrew-riscv). This repo will build with Apple's command-line developer tools (clang) in addition to gcc.
