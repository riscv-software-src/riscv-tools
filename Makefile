# Makefile for RISC-V toolchain; run 'make help'; for usage.

PROJECTS := openocd fesvr isa-sim gnu-toolchain pk tests

BUILDIRS := $(addprefix riscv-, $(addsuffix /build, $(PROJECTS)))
CONFDIRS := $(BUILDIRS:/build=/configure)

ifndef DEST
    DESTINATION := $(PWD)/install
else
    DESTINATION := $(realpath $(DEST))
endif

.PHONY: $(DEST)
$(DEST):; [ -e "$@" ] || mkdir -p "$@"
PATH:=$(DESTINATION)/bin:$(PATH)
export PATH

ROOT := $(abspath $(lastword $(MAKEFILE_LIST)))

# default configure flags
openocd       = --enable-remote-bitbang --enable-jtag_vpi --disable-werror
fesvr         =
isa-sim       = --with-fesvr=$(DESTINATION)
gnu-toolchain =
pk            = --host=riscv65-unknown-elf
tests         =

.PHONY: all $(PROJECTS) $(BUILDIRS) $(CONFDIRS) build help

all: $(PROJECTS)

.SECONDEXPANSION:
# Each project relies on the existence of its /build and /configure subdirectories.
$(PROJECTS):| $$(filter %$$@/build, $(BUILDIRS)) $$(filter %$$@/configure, $(CONFDIRS))
	$(foreach project, $@, $(call build,riscv-$(project));)

$(BUILDIRS):
	[ -e $@ ] || mkdir -p $@

$(CONFDIRS):
	$(foreach arg, $(@:/configure=), [ -e $@ ] && break; cd $(ROOT)/$(arg); \
	find . -iname configure.ac | sed s/configure.ac/m4/ | xargs mkdir -p; \
	autoreconf -i)

build =                                        \
	cd $(ROOT)/$(1)/build;                 \
	git rev-parse HEAD > build.log;        \
	../configure $* --prefix=$(DESTINATION) $($(subst riscv-,,$(1))) >> build.log; \
	$(MAKE) >> build.log;                  \
	$(MAKE) install >> build.log;          \
	cd $(ROOT) > /dev/null

linux: busybox
	cd $(ROOT)/riscv-linux
	make ARCH=riscv defconfig
	make $(linux) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu-

busybox:
	curl -L http://busybox.net/downloads/busybox-1.26.2.tar.bz2 | tar xjf -
	cd $(ROOT)/busybox-1.26.2
	make allnoconfig

	sed -i                                        \
	'/CONFIG_STATIC/s/=.*/=y/'                    \
	'/CONFIG_CROSS_COMPILER_PREFIX/s/=.*/=riscv64-unknown-linux-gnu/' \
	'/CONFIG_FEATURE_INSTALLER/s/=.*/=y/'         \
	'/CONFIG_INIT/s/=.*/=y/'                      \
	'/CONFIG_ASH/s/=.*/=y/'                       \
	'/CONFIG_ASH_JOB_CONTROL/s/=.*/=n/'           \
	'/CONFIG_MOUNT/s/=.*/=y/'                     \
	'/CONFIG_FEATURE_USE_INITTAB/s/=.*/=y/' .config

	make -j4
	cd $(ROOT)/riscv-linux

	General Setup → "Initial RAM filesystem and RAM disk"
	General Setup → "Initramfs source file" → "rootfs.cpio"

	make -j4 ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux

	cd $(ROOT)/riscv-tools
	$(MAKE) pk pk="--host=riscv64-unknown-linux-gnu --with-payload=../riscv-linux/vmlinux"

test:
	$(MAKE) DEST=regression_install

	$(MAKE) -C $(ROOT)/riscv-tests/isa/ run
	$(MAKE) -C $(ROOT)/riscv-tests/benchmarks/ run-riscv

	# test the pk
	printf '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c
	riscv64-unknown-elf-gcc -o hello hello.c
	spike pk hello

	# test glibc+pk
	rm -rf $(ROOT)/riscv-gnu-toolchain/build
	mkdir $(ROOT)/riscv-gnu-toolchain/build
	cd $(ROOT)/riscv-gnu-toolchain/build
	../configure --prefix=$(DESTINATION)
	$(MAKE) linux
	cd $(ROOT); rm hello
	riscv64-unknown-linux-gnu-gcc -static -Wl,-Ttext-segment,0x10000 -o hello hello.c
	spike pk hello

clean:
	rm -fr $(BUILDIRS) $(DESTINATION)

help:
	@echo "usage: $(MAKE) [DEST='install/here'] [tool] [<tool>='--<flag> ...'] ..."
	@echo ""
	@echo "install [tool] to DEST with compiler <flag>'s"
	@echo ""
	@echo "where tool can be any one of:"
	@echo ""
	@echo "    openocd fesvr isa-sim gnu-toolchain pk tests"
	@echo ""
	@echo "defaults:"
	@echo "    DEST='$(DESTINATION)'"
	@echo "    openocd:       $(openocd)"
	@echo "    fesvr:         $(fesvr)"
	@echo "    isa-sim:       $(isa-sim)"
	@echo "    gnu-toolchain: $(gnu-toolchain)"
	@echo "    pk:            $(pk)"
	@echo "    tests:         $(tests)"

