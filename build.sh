#!/bin/sh
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

usage () {
    echo
    echo "usage: $0 [<tool> --<flag> --<flag> ...] [<tool>] ..."
    echo
    echo "where <tool> can be any one of:"
    echo "    openocd fesvr isa_sim gnu_toolchain pk tests"
    echo "and the --reset flag"
    echo "    clears all flags of the preceeding tool (except --prefix)"
    echo
    echo "[no args]      build all of the default tools"
    echo "rv32ima        build 32-bit versions"
    echo
    echo "The default flags are:"
    echo
    echo "riscv-openocd$openocdflags"
    echo "riscv-fesvr$fesvrflags"
    echo "riscv-isa-sim$isa_simflags"
    echo "riscv-gnu-toolchain$gnu_toolchainflags"
    echo "riscv-pk$pkflags"
    echo "riscv-tests$testsflags"
    echo
    echo "with --prefix=\$RISCV assumed where missing"
    echo
    exit 1
}

if [ $# -eq 0 ]; then
    all=true
fi

# default flags
      openocdflags=" --enable-remote-bitbang --enable-jtag_vpi --disable-werror"
        fesvrflags=" "
      isa_simflags=" --with-fesvr=$RISCV"
gnu_toolchainflags=" "
           pkflags=" --host=riscv64-unknown-elf"
        testsflags=" "

appendarg () {
    eval new="\$$1"
    append="$new $2"

    if [ "$2" = "--reset" ]
    then
        eval $1= ""
    else
        eval $1=\$append
    fi
}

while test $# -gt 0; do
    case "$1" in
        all)           all=true ;;
        openocd)       openocd=true
                       lastarg="$1" ;;
        fesvr)         fesvr=true
                       lastarg="$1" ;;
        isa_sim)       isa_sim=true
                       lastarg="$1" ;;
        gnu_toolchain) gnu_toolchain=true
                       lastarg="$1" ;;
        pk)            pk=true
                       lastarg="$1" ;;
        tests)         tests=true
                       lastarg="$1" ;;
        rv32ima)       rv32ima=true
                       lastarg="$1" ;;
        -h)
            usage ;;
        -*)
            appendarg "${lastarg}flags" "$1"
            if [ $rv32ima ]; then
                usage
            fi ;;
        *)  
            echo "error: unrecognized parameter: $1"
            usage ;;
    esac
    shift
done

if [ $all ] || [ $openocd ] || [ $fesvr ] || [ $isa_sim ] || [ $gnu_toolchain ] || [ $pk ] || [ $tests ]; then
     others=true
fi

if [ $rv32ima ] && [ $others ]; then
   echo "error: rv32ima cannot be used with any other option"
   usage
fi

if [ $rv32ima ]; then
          openocdflags=" --enable-remote-bitbang --disable-werror"
          isa_simflags=" --with-fesvr=$RISCV --with-isa=rv32ima"
    gnu_toolchainflags=" --with-arch=rv32ima --with-abi=ilp32"
               pkflags=" --host=riscv32-unknown-elf"
fi


if [ "x$RISCV" = "x" ]; then
  echo "Please set the RISCV environment variable to your preferred install path."
  exit 1
fi

# Use gmake instead of make if it exists.
MAKE=$(command -v gmake || command -v make)

PATH="$RISCV/bin:$PATH"
#GCC_VERSION=`gcc -v 2>&1 | tail -1 | awk '{print $3}'`

set -e

build_project () {
  PROJECT="$1"
  shift
  echo

  if [ -e "$PROJECT/build" ]; then
    echo "Removing existing $PROJECT/build directory"
    rm -rf "$PROJECT/build"
  fi

  if [ ! -e "$PROJECT/configure" ]; then
    (
      cd "$PROJECT"
      find . -iname configure.ac | sed s/configure.ac/m4/ | xargs mkdir -p
      autoreconf -i
    )
  fi

  mkdir -p "$PROJECT/build"
  cd "$PROJECT/build"
  git rev-parse HEAD > build.log
  echo "Configuring $PROJECT"
  ../configure $* >> build.log
  echo "Building $PROJECT"
  $MAKE >> build.log
  echo "Installing $PROJECT"
  $MAKE install >> build.log
  cd - > /dev/null
}

echo "Starting RISC-V Toolchain build process"

if [ $all ] || [ $openocd ]; then
    build_project riscv-openocd --prefix="$RISCV/build" "$openocdflags"
fi

if [ $all ] || [ $fesvr ]; then
    build_project riscv-fesvr --prefix="$RISCV/build" "$fesvrflags"
fi

if [ $all ] || [ $isa_sim ] || [ $rv32ima ]; then
    build_project riscv-isa-sim --prefix="$RISCV/build" "$isa_simflags"
fi

if [ $all ] || [ $gnu_toolchain ] || [ $rv32ima ]; then
    build_project riscv-gnu-toolchain --prefix="$RISCV/build" "$gnu_toolchainflags"
fi

if [ $all ] || [ $pk ] || [ $rv32ima ]; then
    CC='' CXX='' build_project riscv-pk --prefix="$RISCV/build" "$pkflags"
fi

if [ $all ] || [ $tests ]; then
    build_project riscv-tests --prefix="$RISCV/build/riscv64-unknown-elf" "$testsflags"
fi

printf "\nRISC-V Toolchain installation complete!"

