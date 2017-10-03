#!/bin/sh
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

usage () {
    echo "usage: $0 [rv32isa] || [<tool>] [<tool>] ..."
    echo ""
    echo "where <tool> can be any one of:"
    echo "    openocd fesvr isa-sim gnu-toolchain pk tests"
    echo ""
    echo "[default]      build all of the tools"
    echo "rv32ima        build 32-bit versions"
    exit 1
}

if [ $# -eq 0 ]
then
    all=true
fi

while test $# -gt 0
do
    case "$1" in
        openocd)       openocd=true ;;
        fesvr)         fesvr=true  ;;
        isa-sim)       isa=true  ;;
        gnu-toolchain) gnu=true ;;
        pk)            pk=true  ;;
        tests)         tests=true ;;
        rv32ima)       rv32ima=true ;;
        -h)            usage ;;
        *) echo "error: unrecognized parameter: $1"
           usage ;;
    esac
    shift
done

if [ $rv32ima ] && [ $all ] || [ $opencd ] || [ $fesvr ] || [ $isa ] || [ $gnu ] || [ $pk ] || [ $tests ]
then
   echo "error: rv32ima cannot be used with any other option"
   usage
fi

if [ "x$RISCV" = "x" ]
then
  echo "Please set the RISCV environment variable to your preferred install path."
  exit 1
fi

# Use gmake instead of make if it exists.
MAKE=`command -v gmake || command -v make`

PATH="$RISCV/bin:$PATH"
#GCC_VERSION=`gcc -v 2>&1 | tail -1 | awk '{print $3}'`

set -e

function build_project {
  PROJECT="$1"
  shift
  echo
  if [ -e "$PROJECT/build" ]
  then
    echo "Removing existing $PROJECT/build directory"
    rm -rf "$PROJECT/build"
  fi
  if [ ! -e "$PROJECT/configure" ]
  then
    (
      cd "$PROJECT"
      find . -iname configure.ac | sed s/configure.ac/m4/ | xargs mkdir -p
      autoreconf -i
    )
  fi
  mkdir -p "$PROJECT/build"
  cd "$PROJECT/build"
  echo "Configuring project $PROJECT"
  ../configure $* > build.log
  echo "Building project $PROJECT"
  $MAKE >> build.log
  echo "Installing project $PROJECT"
  $MAKE install >> build.log
  cd - > /dev/null
}


echo "Starting RISC-V Toolchain build process"

if [ $all ] || [ $openocd ]
then
    build_project riscv-openocd --prefix=$RISCV --enable-remote-bitbang --enable-jtag_vpi --disable-werror
fi

if [ $all ] || [ $fesvr ]
then
    build_project riscv-fesvr --prefix=$RISCV
fi

if [ $all ] || [ $isa ] || [ $rv32ima ]
then
    if [ $rv32ima ]
    then
        build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV --with-isa=rv32ima
    else
        build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
    fi
fi

if [ $all ] || [ $gnu ] || [ $rv32ima ]
then
    if [ $rv32ima ]
    then
        build_project riscv-gnu-toolchain --prefix=$RISCV --with-arch=rv32ima --with-abi=ilp32
    else
        build_project riscv-gnu-toolchain --prefix=$RISCV
    fi
fi

if [ $all ] || [ $pk ] || [ $rv32ima ]
then
    if [ $rv32ima ]
    then
        CC= CXX= build_project riscv-pk --prefix=$RISCV --host=riscv32-unknown-elf
        build_project riscv-openocd --prefix=$RISCV --enable-remote-bitbang --disable-werror
    else
        CC= CXX= build_project riscv-pk --prefix=$RISCV --host=riscv64-unknown-elf
    fi
fi

if [ $all ] || [ $tests ]
then
    build_project riscv-tests --prefix=$RISCV/riscv64-unknown-elf
fi

echo -e "\\nRISC-V Toolchain installation complete!"

