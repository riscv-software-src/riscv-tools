riscv-tools [![Build Status](https://travis-ci.org/ucb-bar/riscv-tools.svg?branch=master)](https://travis-ci.org/ucb-bar/riscv-tools) 
===========================================================================

Three guides are available for this repo:

1. [Quickstart](#quickstart)

2. [The RISC-V GCC/Newlib Toolchain Installation Manual](#newlibman)

3. [The Linux/RISC-V Installation Manual](#linuxman)




# <a name="quickstart"></a>Quickstart

	$ git submodule update --init --recursive
	$ export RISCV=/path/to/install/riscv/toolchain
	$ ./build.sh


Ubuntu packages needed:

	$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf


Note: This requires GCC >= 4.8 for C++11 support (including thread_local).
To use a compiler different than the default (for example on OS X), use:

	$ CC=gcc-4.8 CXX=g++-4.8 ./build.sh




# <a name="newlibman"></a>The RISC-V GCC/Newlib Toolchain Installation Manual

This document was authored by [Quan Nguyen](http://ocf.berkeley.edu/~qmn) and is a mirrored version (with slight modifications) of the one found at [Quan's OCF
website](http://ocf.berkeley.edu/~qmn/linux/install-newlib.html). Recent updates were made by Sagar Karandikar.

Last updated May 10, 2015

## Introduction

The purpose of this page is to document a procedure through
which an interested user can build the RISC-V GCC/Newlib toolchain.

A project with a duration such as this requires adequate
documentation to support future development and maintenance. This document is
created with the hope of being useful; however, its accuracy is not
guaranteed.

This work was completed at Andrew and Yunsup's request.

## Table of Contents

1.  Introduction
2.  Table of Contents
3.  [Meta-installation Notes](#meta-installation-notes)
4.  [Installing the Toolchain](#installing-toolchain-newlib)
5.  [Testing Your Toolchain](#testing-toolchain)
6.  ["Help! It doesn't work!"](#help-it-doesnt-work)

## <a name="meta-installation-notes"></a>Meta-installation Notes

You may notice this document strikes you as similar to its 
bigger sibling, the <a href="#linuxman">
Linux/RISC-V Installation Manual</a>. That's because the instructions are rather
similar. That said...

### Running Shell Commands

Instructive text will appear as this paragraph does. Any
instruction to execute in your terminal will look like this:

	$ echo "execute this"

_Optional_ shell commands that may be required for
your particular system will have their prompt preceeded with an O:

	O$ echo "call this, maybe"

If you will need to replace a bit of code that applies
specifically to your situation, it will be surrounded by [square brackets].

### The Standard Build Unit

To instruct how long it will take someone to build the
various components of the packages on this page, I have provided build times in
terms of the Standard Build Unit (SBU), as coined by Gerard Beekmans in his
immensely useful [Linux From Scratch](http://www.linuxfromscratch.org)
website.

On an Intel Xeon Dual Quad-core server with 48 GiB RAM, I
achieved the following build time for `binutils`: 38.64 seconds.
Thus, **38.64 seconds = 1 SBU**. (EECS members at the University
 of California, Berkeley: I used the `s141.millennium` server.)

As a point of reference, my 2007 MacBook with an Intel Core 2
Duo and 1 GiB RAM has 100.1 seconds to each SBU. Building
`riscv64-unknown-linux-gnu-gcc`, unsurprisingly, took about an hour.

Items marked as "optional" are not measured.

### Having Superuser Permissions

You will need root privileges to install
the tools to directories like `/usr/bin`, but you may optionally
specify a different installation directory. Otherwise, superuser privileges are
not necessary.

### GCC Version

Note: Building `riscv-tools` requires GCC >= 4.8 for C++11 support (including thread_local). To use a compiler different than the default (for example on OS X), you'll need to do the following when the guide requires you to run `build.sh`:

	$ CC=gcc-4.8 CXX=g++-4.8 ./build.sh


## <a name="installing-toolchain-newlib"></a>Installing the Toolchain

Let's start with the directory in which we will install our
tools. Find a nice, big expanse of hard drive space, and let's call that
`$TOP`. Change to the directory you want to install in, and then set 
the `$TOP` environment variable accordingly:

	$ export TOP=$(pwd)

For the sake of example, my `$TOP` directory is on
`s141.millennium`, at `/scratch/quannguyen/noob`, named so
because I believe even a newbie at the command prompt should be able to complete 
this tutorial. Here's to you, n00bs!

### Tour of the Sources

If we are starting from a relatively fresh install of
GNU/Linux, it will be necessary to install the RISC-V toolchain. The toolchain
consists of the following components:

*   `riscv-gnu-toolchain`, a RISC-V cross-compiler
*   `riscv-fesvr`, a "front-end" server that
services calls between the host and target processors on the Host-Target
InterFace (HTIF) (it also provides a virtualized console and disk device)
*   `riscv-isa-sim`, the ISA simulator and
"golden standard" of execution
*   `riscv-opcodes`, the enumeration of all
RISC-V opcodes executable by the simulator
*   `riscv-pk`, a collection of system software for supporting
    tethered RISC-V implementations
  *   `pk` (Proxy Kernel), a lightweight application execution
      environment for hosting statically-linked RISC-V ELF user
      binaries
  *   `bbl` (Berkeley Boot Loader), a supervisor execution environment
      designed to host the Linux/RISC-V port
      (not needed for this workflow)
*   `riscv-tests`, a set of assembly tests
and benchmarks

In the installation guide for Linux builds, we built only the
simulator, front-end server, and `bbl`. Binaries built against Newlib with
`riscv-gnu-toolchain` will not have the luxury of being run on a full-blown
operating system, but they will still demand to have access to some crucial
system calls.

### What's Newlib?

[Newlib](http://www.sourceware.org/newlib/) is a
"C library intended for use on embedded systems." It has the advantage of not
having so much cruft as Glibc at the obvious cost of incomplete support (and
idiosyncratic behavior) in the fringes. The porting process is much less complex
than that of Glibc because you only have to fill in a few stubs of glue
code.

These stubs of code include the system calls that are
supposed to call into the operating system you're running on. Because there's no
operating system proper, the simulator runs, on top of it, a proxy kernel
(`riscv-pk`) to handle many system calls, like `open`,
`close`, and `printf`.

### Obtaining and Compiling the Sources (7.87 SBU)

First, clone the tools from the `riscv-tools` GitHub
repository:

	$ git clone https://github.com/ucb-bar/riscv-tools.git

This command will bring in only references to the
repositories that we will need. We rely on Git's submodule system to take care
of resolving the references. Enter the newly-created riscv-tools directory and
instruct Git to update its submodules. 

	$ cd $TOP/riscv-tools
	$ git submodule update --init --recursive

To build GCC, we will need several other packages, including
flex, bison, autotools, libmpc, libmpfr, and libgmp. Ubuntu distribution
installations will require this command to be run. If you have not installed
these things yet, then run this:

	O$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf

Before we start installation, we need to set the
`$RISCV` environment variable. The variable is used throughout the
build script process to identify where to install the new tools. (This value is
used as the argument to the `--prefix` configuration switch.)

	$ export RISCV=$TOP/riscv

If your `$PATH` variable does not contain the
directory specified by `$RISCV`, add it to the `$PATH`
environment variable now:

	$ export PATH=$PATH:$RISCV/bin

One more thing: If your machine doesn't have the capacity to
handle 16 make jobs (or conversely, it can handle more), edit
`build.common` to change the number specified by
`JOBS`.

	O$ sed -i 's/JOBS=16/JOBS=[number]/' build.common

With everything else set up, run the build script. Recall that if you're using a new-version of gcc that isn't the default on your system, you'll need to precede the `./build.sh` with `CC=gcc-4.8 CXX=g++-4.8`:

	$ ./build.sh


## <a name="testing-toolchain"></a> Testing Your Toolchain

Now that you have a toolchain, it'd be a good idea to test it
on the quintessential "Hello world!" program. Exit the `riscv-tools`
directory and write your "Hello world!" program. I'll use a long-winded
`echo` command.

	$ cd $TOP
	$ echo -e '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c

Then, build your program with `riscv64-unknown-elf-gcc`.

	$ riscv64-unknown-elf-gcc -o hello hello.c

When you're done, you may think to do `./hello`,
but not so fast. We can't even run `spike hello`, because our "Hello
world!" program involves a system call, which couldn't be handled by our host
x86 system. We'll have to run the program within the
proxy kernel, which itself is run by `spike`, the RISC-V
architectural simulator. Run this command to run your "Hello world!"
program:

	$ spike pk hello

The RISC-V architectural simulator, `spike`, takes
as its argument the path of the binary to run. This binary is `pk`,
and is located at `$RISCV/riscv-elf/bin/pk`.
`spike` finds this automatically.
Then, `riscv-pk` receives as _its_
argument the name of the program you want to run.

Hopefully, if all's gone well, you'll have your program
saying, "Hello world!". If not...


## <a name="help-it-doesnt-work"></a>"Help! It doesn't work!"

I know, I've been there too. Good luck!




# <a name="linuxman"></a> The Linux/RISC-V Installation Manual

## Introduction

The purpose of this page is to document a procedure through
which an interested user can install an executable image of the RISC-V 
architectural port of the Linux kernel.

A project with a duration such as this requires adequate
documentation to support future development and maintenance. This document is
created with the hope of being useful; however, its accuracy is not
guaranteed.

This document is a mirrored version (with slight
modifications) of the one found at 
[Quan's OCF
website](http://ocf.berkeley.edu/~qmn/linux/install.html)

## Table of Contents

1.  Introduction
2.  Table of Contents
3.  [Meta-installation Notes](#meta-installation-notes)
4.  [Installing the Toolchain](#installing-toolchain-linux)
5.  [Building the Linux Kernel](#building-linux)
6.  [Building BusyBox](#building-busybox)
7.  [Creating a Root Disk Image](#creating-root-disk)
8.  ["Help! It doesn't work!"](#help-it-doesnt-work)
9.  [Optional Commands](#optional-commands)
10.  [References](#references)


## <a name="meta-installation-notes"></a>Meta-installation Notes

### Running Shell Commands

Instructive text will appear as this paragraph does. Any
instruction to execute in your terminal will look like this:

	$ echo "execute this"                     
		                         
_Optional_ shell commands that may be required for
your particular system will have their prompt preceeded with an O:

	O$ echo "call this, maybe"

When booted into the Linux/RISC-V kernel, and some command is to be
run, it will appear as a root prompt (with a `#` as the prompt):

	# echo "run this in linux"

If you will need to replace a bit of code that applies
specifically to your situation, it will be surrounded by [square brackets].

### The Standard Build Unit

To instruct how long it will take someone to build the
various components of the packages on this page, I have provided build times in
terms of the Standard Build Unit (SBU), as coined by Gerard Beekmans in his
immensely useful [Linux from Scratch](http://www.linuxfromscratch.org)
website.

On an Intel Xeon Dual Quad-core server with 48 GiB RAM, I
achieved the following build time for `binutils`: 38.64 seconds.
Thus, **38.64 seconds = 1 SBU**. (EECS members at the University
 of California, Berkeley: I used the `s141.millennium` server.)

As a point of reference, my 2007 MacBook with an Intel Core 2
Duo and 1 GiB RAM has 100.1 seconds to each SBU. Building
`riscv64-unknown-linux-gnu-gcc`, unsurprisingly, took about an hour.

Items marked as "optional" are not measured.

### Having Superuser Permissions

You will need root privileges to install
the tools to directories like `/usr/bin`, but you may optionally
specify a different installation directory. Otherwise, superuser privileges are
not necessary.

		

## <a name="installing-toolchain-linux"></a> Installing the Toolchain (11.81 + &epsilon; SBU)

Let's start with the directory in which we will install our
tools. Find a nice, big expanse of hard drive space, and let's call that
`$TOP`. Change to the directory you want to install in, and then set 
the `$TOP` environment variable accordingly:

	$ export TOP=$(pwd)

For the sake of example, my `$TOP` directory is on
`s141.millennium`, at `/scratch/quannguyen/noob`, named so
because I believe even a newbie at the command prompt should be able to boot 
Linux using this tutorial. Here's to you, n00bs!

### Prerequisites

If we are starting from a relatively fresh install of
GNU/Linux, it will be necessary to install the RISC-V toolchain. The toolchain
consists of the following components:

*   `riscv-gnu-toolchain`, a RISC-V cross-compiler
*   `riscv-fesvr`, a "front-end" server that
services calls between the host and target processors on the Host-Target
InterFace (HTIF) (it also provides a virtualized console and disk device)
*   `riscv-isa-sim`, the ISA simulator and
"golden standard" of execution
*   `riscv-opcodes`, the enumeration of all
RISC-V opcodes executable by the simulator
*   `riscv-pk`, a collection of system software for supporting
    tethered RISC-V implementations
  *   `pk` (Proxy Kernel), a lightweight application execution
      environment for hosting statically-linked RISC-V ELF user
      binaries (not needed for this workflow)
  *   `bbl` (Berkeley Boot Loader), a supervisor execution environment
      designed to host the Linux/RISC-V port
*   `riscv-tests`, a set of assembly tests
and benchmarks

In actuality, of this list, we will need to build only
`riscv-fesvr`, `riscv-isa-sim`, and `riscv-pk`. These are the three
components needed to execute RISC-V binaries on the host machine. We will also need to
build `riscv64-unknown-linux-gnu-gcc`, but this involves a little modification of
the build procedure for `riscv64-unknown-elf-gcc`.

First, clone the tools from the `ucb-bar` GitHub
repository:

	$ git clone https://github.com/ucb-bar/riscv-tools.git

This command will bring in only references to the
repositories that we will need. We rely on Git's submodule system to take care
of resolving the references. Enter the newly-created riscv-tools directory and
instruct Git to update its submodules. 

	$ cd $TOP/riscv-tools
	$ git submodule update --init

To build GCC, we will need several other packages, including
flex, bison, autotools, libmpc, libmpfr, and libgmp. Ubuntu distribution
installations will require this command to be run. If you have not installed
these things yet, then run this:

	O$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf

Before we start installation, we need to set the
`$RISCV` environment variable. The variable is used throughout the
build script process to identify where to install the new tools. (This value is
used as the argument to the `--prefix` configuration switch.)

	$ export RISCV=$TOP/riscv

If your `$PATH` variable does not contain the
directory specified by `$RISCV`, add it to the `$PATH`
environment variable now:

	$ export PATH=$PATH:$RISCV/bin

One more thing: If your machine doesn't have the capacity to
handle 16 make jobs (or conversely, it can handle more), edit
`build.common` to change the number specified by
`JOBS`.

	O$ sed -i 's/JOBS=16/JOBS=[number]/' build.common

### <a name="full-toolchain-build-back"></a> Building `riscv64-unknown-linux-gnu-gcc` (11.41 SBU)

`riscv64-unknown-linux-gnu-gcc` is the name of the
cross-compiler used to build binaries linked to the GNU C Library
(`glibc`) instead of the Newlib library. You can build Linux with
`riscv64-unknown-elf-gcc`, but you will need `riscv64-unknown-linux-gnu-gcc` to
cross-compile applications, so we will build that instead.

Enter the `riscv-gnu-toolchain` directory and run the configure script
to generate the Makefile.

	$ cd $TOP/riscv-tools/riscv-gnu-toolchain
	$ ./configure --prefix=$RISCV

These instructions will place your
`riscv64-unknown-linux-gnu-gcc` tools in the same installation directory as the
`riscv64-unknown-elf-gcc` tool installed earlier. This arrangement is the simplest,
but you could optionally supply a different prefix, so long as the bin directory
within that prefix is in your PATH.

Run this command to start the build process:

	$ make linux


### Installing the RISC-V simulator (0.40 SBU)

Return to the `riscv-tools` base directory.

	$ cd $TOP/riscv-tools

Since we only need to build a few tools, we will use a
modified build script, listed in its entirety below.
If you want to build the full toolchain for later use, see
<a href="#full-toolchain-build">here</a>.


	[basic-build.sh contents]
	1 #!/bin/bash
	2 . build.common
	3 build_project riscv-fesvr --prefix=$RISCV
	4 build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
	5 build_project riscv-pk --prefix=$RISCV/riscv64-unknown-elf --host=riscv64-unknown-linux-gnu


Download this script using this command:

	$ curl -L http://riscv.org/install-guides/linux-build.sh > basic-build.sh

(The `-L` option allows curl to handle redirects.)
Make the script executable, and with everything else taken care of, run the
build script.

	$ chmod +x basic-build.sh
	$ ./basic-build.sh


## <a name="building-linux"></a> Building the Linux Kernel (0.40 + &epsilon; SBU)

### Obtaining and Patching the Kernel Sources

We are finally poised to bring in the Linux kernel sources.
Change out of the `riscv-tools/riscv-gnu-toolchain` directory and clone the 
`riscv-linux` Git repository into this directory:
`linux-3.14._xx_`, where _xx_ represents the current
minor revision (which, as of early May 2015, is "41").

	$ cd $TOP
	$ git clone git@github.com:ucb-bar/riscv-linux.git linux-3.14.41

Download the current minor revision of the 3.14 Linux kernel series
from [The Linux Kernel Archives](http://www.kernel.org), and in one fell
swoop, untar them over our repository. (The `-k` switch ensures that
our `.gitignore` and `README` files don't get clobbered.)

	$ curl -L ftp://ftp.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | tar -xJk


### Configuring the Linux Kernel

The Linux kernel is seemingly infinitely configurable. However,
with the current development status, there aren't that many devices or options
to tweak. However, start with a default configuration that should work
out-of-the-box with the ISA simulator.

	$ make ARCH=riscv defconfig

If you want to edit the configuration, you can use a text-based
GUI (ncurses) to edit the configuration:

	O$ make ARCH=riscv menuconfig

Among other things, we have enabled by default procfs, ext2,
and the HTIF virtualized devices (a block driver and console). In development, it
can be very useful to enable "early printk", which will print messages to the
console if the kernel crashes very early. You can access this option at "Early
printk" in the "Kernel hacking" submenu.

<img src="http://riscv.org/install-guides/linux-menuconfig.png" />

_Linux kernel menuconfig interface._

Begin building the kernel once you're satisfied with your
configuration. Note the pattern: to build the RISC-V kernel, you _must_
specify the `ARCH=riscv` in each invocation of `make`.
This line is no exception. If you want to speed up the process, you can pass the
`-j [number]` option to make.

	$ make -j ARCH=riscv

Congratulations! You've just cross-compiled the Linux kernel
for RISC-V! However, there are a few more things to take care of before we boot 
it.

## <a name="building-busybox"></a> Building BusyBox (0.26 SBU)

We currently develop with BusyBox,
an unbelievably useful set of utilities that all compile into one multi-use
binary. We use BusyBox without source code modifications. You can obtain
the source at <a href="http://www.busybox.net">http://www.busybox.net</a>. In
our case, we will use BusyBox 1.21.1, but other versions should work fine.

Currently, we need it for its `init` and
`ash` applets, but with `bash` cross-compiled for RISC-V,
there is no longer a need for `ash`.

First, obtain and untar the source:

	$ cd $TOP
	$ curl -L http://busybox.net/downloads/busybox-1.21.1.tar.bz2 | tar -xj

Then, enter the directory and turn off every configuration
option:

	$ cd busybox-1.21.1
	$ make allnoconfig

We will need to change the cross-compiler, set the build to
"static" (if desired, you can make it dynamic, but you'll have to copy some
libraries later). We will also enable the `init`, `ash`,
and `mount` applets. Also, disable job control for `ash` 
when the drop down menu for `ash`'s suboptions appear.

Here are the configurations you will have to change:

*   `CONFIG_STATIC=y`, listed as "Build
BusyBox as a static binary (no shared libs)" in BusyBox Settings
&rarr; Build Options
*   `CONFIG_CROSS_COMPILER_PREFIX=riscv-linux-`,
listed as "Cross Compiler prefix" in BusyBox Settings &rarr; Build Options
*   `CONFIG_FEATURE_INSTALLER=y`, listed as
"Support --install [-s] to install applet links at runtime" in BusyBox Settings
&rarr; General Configuration
*   `CONFIG_INIT=y`, listed as "init" in Init utilities
*   `CONFIG_ASH=y`, listed as "ash" in Shells
*   `CONFIG_ASH_JOB_CONTROL=n`, listed as "Ash &rarr; Job control" in Shells
*   `CONFIG_MOUNT=y`, listed as "mount" in Linux System Utilities

My configuration file used to create this example is located
here: [busybox-riscv.config](busybox-riscv.config). You
can also download it directly using this snippet of code:

	$ curl -L http://riscv.org/install-guides/busybox-riscv.config > .config

Whether or not you want to use the file provided, enter the
configuration interface much in the same way as that of the Linux kernel:

	O$ make menuconfig

<img src="http://riscv.org/install-guides/busybox-menuconfig.png" />

_BusyBox menuconfig interface. Looks familiar, eh?_

Once you've finished, make BusyBox. You don't need to specify
`$ARCH`, because we've passed the name of the cross-compiler prefix.

	$ make -j

Once that completes, you now have a BusyBox binary
cross-compiled to run on RISC-V. Now we'll need a way for the kernel to access
the binary, and we'll use a root disk image for that. Before we proceed, change
back into the directory with the Linux sources.

	$ cd $TOP/linux-3.14.41


## <a name="creating-root-disk"></a> Creating a Root Disk Image

When we initially developed the kernel, we used an initramfs
to store our binaries ([BusyBox](http://www.busybox.net) in
particular). However, with our HTIF-enabled block device, we can boot off of a
root file system proper. (In fact, we still make use of the initramfs, but only
to set up devices and the symlink to `init`. See
`arch/riscv/initramfs.txt`.)

Currently, we have a root file system pre-packaged
specifically for the RISC-V release. You can obtain it by heading to the index
of my website, [http://ocf.berkeley.edu/~qmn](http://ocf.berkeley.edu/~qmn), finding my
email, and contacting me.

To create your own root image, we need to create an ext2 disk
image. To create an empty disk image, use `dd`, setting the argument
to `count` to the size, in MiB, of your disk image. 64 MiB seems to
be good enough for our purposes.

	$ dd if=/dev/zero of=root.bin bs=1M count=64

The file `root.bin` is just an empty chunk of
zeros and has no partitioning information. To format it as an ext2 disk, run
`mkfs.ext2` on it:

	$ mkfs.ext2 -F root.bin

You can modify this filesystem if you mount it as writable
from within Linux/RISC-V. However, a better option, especially if you want to
copy big binaries, is to mount it on your host machine. _You will normally
need superuser privileges to do a mount._ Do so this way, assuming you want
to mount the disk image at `linux-3.14.41/mnt`:

	$ mkdir mnt
	$ sudo mount -o loop root.bin mnt

(Instructions for mounting provided courtesy of a_ou.)

If you cannot mount as root, you can use Filesystem in Userspace
(FUSE) instead. See [here](#using-fuse).

<a name="using-fuse-back"></a>

Once you've mounted the disk image, you can edit the files 
inside. There are a few directories that you should have:

*   `/bin`
*   `/dev`
*   `/etc`
*   `/lib`
*   `/proc`
*   `/sbin`
*   `/tmp`
*   `/usr`

So create them:

	$ cd mnt
	$ mkdir -p bin etc dev lib proc sbin tmp usr usr/bin usr/lib usr/sbin

Then, place the BusyBox executable we just compiled in
`/bin`.

	$ cp $TOP/busybox-1.21.1/busybox bin

If you have built BusyBox  statically, that will be all
that's needed. If you want to build BusyBox dynamically, you will need to follow
a slightly different procedure, described <a href="#dynamic-busybox">here</a>.

<a name="dynamic-busybox-back"></a>

We will also need to prepare an initialization table in the
aptly-named file `inittab`, placed in `/etc`. Here is the
`inittab` from our disk image:

	1 ::sysinit:/bin/busybox mount -t proc proc /proc
	2 ::sysinit:/bin/busybox mount -t tmpfs tmpfs /tmp
	3 ::sysinit:/bin/busybox mount -o remount,rw /dev/htifbd0 /
	4 ::sysinit:/bin/busybox --install -s
	5 /dev/console::sysinit:-/bin/ash

Line 1 mounts the procfs filesystem onto `/proc`.
Line 2 does similarly for tmpfs. Line 3 mounts the HTIF-virtualized block
device (`htifbd`) onto root. Line 4 installs the various BusyBox
applet symbolic links in `/bin` and elsewhere to make it more
convenient to run them. Finally, line 5 opens up an `ash` shell on
the HTIF-virtualized TTY (`console`, mapped to `ttyHTIF`) for a connection.

Download a copy of the example `inittab` using this command:

	$ curl -L http://riscv.org/install-guides/linux-inittab > etc/inittab

If you would like to use `getty` instead, change
line 5 to invoke that:

	5 ::respawn:/bin/busybox getty 38400 ttyHTIF0

Once you've booted Linux and created the symlinks with line
4, they will persist between boots of the Linux kernel. This will cause a bunch
of unsightly errors in every subsequent boot of the kernel. At the next boot, 
comment out line 4.

Also, we will need to create a symbolic link to `/bin/busybox` for `init` to work.

	$ ln -s ../bin/busybox sbin/init

Add your final touches and binaries to your root disk image,
and then unmount the disk image.<p>

	$ cd ..
	$ sudo umount mnt

Now, we're ready to boot a most basic kernel, with a shell.
Invoke `spike`, the RISC-V architectural simulator, named after the
[golden spike](http://www.nps.gov/gosp/index.htm) that joined the two
tracks of the Transcontinental Railroad, and considered to be the golden model of
execution. We will need to load in the root disk image through the
`+disk` argument to `spike` as well. The command looks
like this:

	$ spike +disk=root.bin bbl vmlinux

`vmlinux` is the name of the compiled Linux kernel binary, which is
loaded by `bbl`, the Berkeley Boot Loader.

If there are no problems, an `ash` prompt will
appear after the boot process completes. It will be pretty useless without the
usual plethora of command-line utilities, but you can add them as BusyBox
applets. Have fun!

To exit the simulator, hit `Ctrl-C`.

<img src="http://riscv.org/install-guides/linux-boot.png"/>

_Linux boot and "Hello world!"_

If you want to reuse your disk image in a subsequent boot of
the kernel, remember to remove (or comment out) the line that creates the
symbolic links to BusyBox applets. Otherwise, it will generate several
(harmless) warnings in each subsequent boot.
		

## <a name="help-it-doesnt-work"></a> "Help! It doesn't work!"

I know, I've been there too. Good luck!		

## <a name="optional-commands"></a> Optional Commands

Depending on your system, you may have to execute a few more
shell commands or execute them differently. It's not too useful if you've
arrived here after reading the main text of the document; it's best that you're 
referred here instead.

### <a name="full-toolchain-build"></a> Building the Full Toolchain (7.62 SBU)

If you want to build `riscv64-unknown-elf-gcc` (as
_distinct_ from `riscv64-unknown-linux-gnu-gcc`), `riscv-pk`, and
`riscv-tests`, then simply run the full build script rather than the
abbreviated one I provided.

	O$ ./build.sh

[Return to text.](#full-toolchain-build-back)

### <a name="linux-headers-install"></a> Installing a Fresh Copy of the Linux Headers

If you (or someone you know) has changed the Linux headers,
you'll need to install a new version to your system root before you build
`riscv64-unknown-linux-gnu-gcc` to make sure the kernel and the C library agree on
their interfaces. (Note that you'll need to pull in the Linux kernel sources
before you perform these steps. If you haven't, do so now.)

First, go to the Linux directory and perform a headers
check:

	O$ cd $TOP/linux-3.14.41
	$ make ARCH=riscv headers_check

Once the headers have been checked, install them.

	O$ make ARCH=riscv headers_install INSTALL_HDR_PATH=$RISCV/sysroot64/usr

(Substitute the path specified by `INSTALL_HDR_PATH` if so desired.)

[Return to text.](#linux-headers-install-back)	

### <a name="using-fuse"></a> Using Filesystem in Userspace (FUSE) to Create a Disk Image

If you are unable (or unwilling) to use `mount` to
mount the newly-created disk image for modification, and you also have
Filesystem in Userspace (FUSE), you can use these commands to modify your disk
image.

First, create a folder as your mount point.

	O$ mkdir mnt

Then, mount the disk image with FUSE. The `-o +rw`
option is considered **experimental** by FUSE developers, and may
corrupt your disk image. If you experience strange behaviors in your disk image,
you might want to delete your image and make a new one. Continuing, mount the
disk:

	O$ fuseext2 -o rw+ root.bin mnt

Modify the disk image as described, but remember to unmount
the disk using FUSE, not `umount`:

	O$ fusermount -u mnt

[Return to text.](#using-fuse-back)

### <a name="dynamic-busybox"></a> Building BusyBox as a Dynamically-Linked Executable

If you want to conserve space on your root disk, or you want
to support dynamically-linked binaries, you will want to build BusyBox as a
dynamically-linked executable. You'll need to have these libraries:

*   `libc.so.6`, the C library
*   `ld.so.1`, the run-time dynamic linker

If BusyBox calls for additional libraries (e.g.
`libm`), you will need to include those as well.

These were built when we compiled
`riscv64-unknown-linux-gnu-gcc` and were placed in `$RISCV/sysroot64`. So, mount
your root disk (if not mounted already), cd into it, and copy the libraries into
`lib`:

	O$ cp $RISCV/sysroot64/lib/libc.so.6 lib/
	O$ cp $RISCV/sysroot64/lib/ld.so.1 lib/

That's it for the libraries. Go back to the BusyBox
configuration and set BusyBox to be built as a dynamically-linked binary by
unchecking the `CONFIG_STATIC` box in the menuconfig interface.

*   `CONFIG_STATIC=n`, listed as "Build
BusyBox as a static binary (no shared libs)" in BusyBox Settings
&rarr; Build Options

 To make things a little faster, I've used a bit of 
`sed` magic instead.

	O$ cd $TOP/busybox-1.21.1
	O$ sed -i 's/CONFIG_STATIC=y/# CONFIG_STATIC is not set/' .config

Then, rebuild and reinstall BusyBox into `mnt/bin`.

	O$ make -j
	O$ cd $TOP/linux-3.14.41/mnt
	O$ cp $TOP/busybox-1.21.1/busybox bin

[Return to text.](#dynamic-busybox-back)

## <a name="references"></a> References

* Waterman, A., Lee, Y., Patterson, D., and Asanovic, K,. "The RISC-V Instruction Set Manual," vol. II, [http://inst.eecs.berkeley.edu/~cs152/sp12/handouts/riscv-supervisor.pdf](http://inst.eecs.berkeley.edu/~cs152/sp12/handouts/riscv-supervisor.pdf), 2012.

* Bovet, D.P., and Cesati, M. _Understanding the Linux Kernel_, 3rd ed., O'Reilly, 2006.

* Gorman, M. _Understanding the Linux Virtual Memory Manager_,
		[http://www.csn.ul.ie/~mel/docs/vm/guide/pdf/understand.pdf](http://www.csn.ul.ie/~mel/docs/vm/guide/pdf/understand.pdf), 2003.

* Corbet, J., Rubini, A., and Kroah-Hartman, G. _Linux Device Drivers_, 3rd ed., O'Reilly, 2005.

* Beekmans, G. _Linux From Scratch_, version 7.3, [http://www.linuxfromscratch.org/lfs/view/stable/](http://www.linuxfromscratch.org/lfs/view/stable/), 2013.

