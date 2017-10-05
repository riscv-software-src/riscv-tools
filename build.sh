#!/bin/sh -e

usage () {
    echo "usage: $0 <directory> [-h] [-v] [-d] [<tool> --<flag> ...] [<tool>] ..."
    echo
    echo "installs the RISC-V <tool>'s to <directory>, where <tool> can be any one of:"
    echo
    echo "    openocd fesvr isa_sim gnu_toolchain pk tests"
    echo
    echo "and the special 'reset' <flag> clears all flags of the preceeding <tool> (except for 'prefix')"
    echo
    echo "    -h             prints this help message and exits"
    echo "    -v             prints verbose runtime information"
    echo "    -d             prints debug information"
    echo "    [no args]      build all of the default tools"
    echo "    linux          build the linux cross-compiler"
    echo "    rv32ima        build 32-bit versions"
    echo
    echo "The default flags are:"
    echo
    echo "    openocd$openocdflags"
    echo "    fesvr$fesvrflags"
    echo "    isa_sim$isa_simflags"
    echo "    gnu_toolchain$gnu_toolchainflags"
    echo "    pk$pkflags"
    echo "    tests$testsflags"
    echo
    echo "with --prefix=<directory> assumed where missing"
    exit 1
}

appendarg () {
    eval new="\$$1"
    append="$new $2"

    if [ "$2" = "--reset" ]; then
        eval $1= ""
    else
        eval $1=\$append
    fi
}

printrun () {
    if [ "$debug" ]; then
        printf "%s: " "$PWD"
        echo "$@"
    fi
    eval "$@"
}

build_project () {
    PROJECT="$1"
    shift

    [ "$verbose" ] && printf "\n-------- %s --------\n" "$PROJECT"

    if [ -e "$PROJECT/build" ]; then
        [ "$verbose" ] && echo "Removing $PROJECT/build directory"
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

    [ "$verbose" ] && echo "Configuring..."
    printrun "../configure $* >> build.log"

    [ "$verbose" ] && echo "Building..."
    printrun "$MAKE >> build.log"

    [ "$verbose" ] && echo "Installing..."
    printrun "$MAKE install >> build.log"

    cd - > /dev/null
}


if [ ! -e "$1"  ]; then
    mkdir "$1"
fi

RISCV=$(cd "$(dirname -- "$1/.")"; printf %s "$PWD")
shift

export PATH="${RISCV}/bin:$PATH"


# default flags
      openocdflags=" --enable-remote-bitbang --enable-jtag_vpi --disable-werror"
        fesvrflags=" "
      isa_simflags=" --with-fesvr=$RISCV"
gnu_toolchainflags=" "
           pkflags=" --host=riscv64-unknown-elf"
        testsflags=" "


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
        linux)         linux=true
                       lastarg="$1" ;;
        rv32ima)       rv32ima=true
                       lastarg="$1" ;;
        -h)            usage ;;
        -v)            verbose=true ;;
        -d)            debug=true ;;
        -*)
            appendarg "${lastarg}flags" "$1"
            if [ "$rv32ima" ]; then
                usage
            fi ;;
        *)  
            echo "error: unrecognized parameter: $1"
            usage ;;
    esac
    shift
done


if [ "$linux" ] || [ "$openocd" ] || [ "$fesvr" ] || [ "$isa_sim" ] || [ "$gnu_toolchain" ] || [ "$pk" ] || [ "$tests" ]; then
     others=true
else
     all=true
fi

if [ "$rv32ima" ] && [ "$others" ]; then
   echo "error: rv32ima cannot be used with any other option"
   usage
fi

if [ "$rv32ima" ]; then
          openocdflags=" --enable-remote-bitbang --disable-werror"
          isa_simflags=" --with-fesvr=$RISCV --with-isa=rv32ima"
    gnu_toolchainflags=" --with-arch=rv32ima --with-abi=ilp32"
               pkflags=" --host=riscv32-unknown-elf"
fi


# Use gmake instead of make if it exists.
MAKE=$(command -v gmake || command -v make)

#GCC_VERSION=`gcc -v 2>&1 | tail -1 | awk '{print $3}'`


[ "$verbose" ] && echo "Starting RISC-V Toolchain build process"

if [ "$all" ] || [ "$openocd" ]; then
    build_project riscv-openocd --prefix="$RISCV" "$openocdflags"
fi

if [ "$all" ] || [ "$fesvr" ]; then
    build_project riscv-fesvr --prefix="$RISCV" "$fesvrflags"
fi

if [ "$all" ] || [ "$isa_sim" ] || [ "$rv32ima" ]; then
    build_project riscv-isa-sim --prefix="$RISCV" "$isa_simflags"
fi

if [ "$linux" ]; then
    (
        cd "riscv-gnu-toolchain/build"
        printrun "$MAKE $linuxflags linux >> build.log"
    )
fi

if [ "$all" ] || [ "$gnu_toolchain" ] || [ "$rv32ima" ]; then
    build_project riscv-gnu-toolchain --prefix="$RISCV" "$gnu_toolchainflags"
fi

if [ "$all" ] || [ "$pk" ] || [ "$rv32ima" ]; then
    CC='' CXX='' build_project riscv-pk --prefix="$RISCV" "$pkflags"
fi

if [ "$all" ] || [ "$tests" ]; then
    build_project riscv-tests --prefix="$RISCV/riscv64-unknown-elf" "$testsflags"
fi

[ "$verbose" ] && printf "\nRISC-V Toolchain installation complete!"

