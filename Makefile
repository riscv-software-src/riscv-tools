# Makefile for RISC-V toolchain; run 'make help' for usage.

PROJECTS  = openocd fesvr isa-sim gnu-toolchain pk tests
BUSYBOX   = busybox-1.26.2

BUILDIRS := $(addprefix riscv-, $(addsuffix /build, $(PROJECTS)))
CONFDIRS := $(BUILDIRS:/build=/configure)

ROOT     := $(patsubst %/,%, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
RISCV    ?= $(PWD)/install

DEST     := $(abspath $(RISCV))
PATH     := $(DEST)/bin:$(PATH)

# default configure flags
openocd       = --enable-remote-bitbang --enable-jtag_vpi --disable-werror
fesvr         =
isa-sim       = --with-fesvr=$(DEST)
gnu-toolchain =
pk            = --host=riscv64-unknown-elf
tests         =

.PHONY: all $(PROJECTS) help clean docs test linux busybox
all: $(PROJECTS)

.SECONDEXPANSION:
# Each project relies on the existence of its own /build and /configure subdirectories.
$(PROJECTS): | $$(filter %$$@/build, $(BUILDIRS)) $$(filter %$$@/configure, $(CONFDIRS))
	$(foreach project, $@, $(call build,$(project));)

$(BUILDIRS) $(DEST):
	[ -e $@ ] || mkdir -p $@

$(CONFDIRS):
	$(foreach arg, $(@:/configure=), [ -e $@ ] && break; cd $(ROOT)/$(arg);\
	find . -iname configure.ac | sed s/configure.ac/m4/ | xargs mkdir -p;\
	autoreconf -i)

build =\
	cd $(ROOT)/riscv-$(1)/build;\
	git rev-parse HEAD > build.log;\
	../configure $* --prefix=$(DEST) $($(1)) >> build.log;\
	$(MAKE) >> build.log;\
	$(MAKE) install >> build.log;\
	cd $(ROOT) > /dev/null

riscv-linux/vmlinux: linux
linux: busybox
	cd $(ROOT)/riscv-linux
	$(MAKE) ARCH=riscv defconfig
	$(MAKE) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu-

$(BUSYBOX)/busybox: busybox
busybox:
	[ -e "${BUSYBOX}" ] || curl -L http://busybox.net/downloads/${BUSYBOX}.tar.bz2 | tar xjf -
	cd $(ROOT)/${BUSYBOX}
	$(MAKE) allnoconfig

	sed -i                                        \
	'/CONFIG_STATIC/s/=.*/=y/'                    \
	'/CONFIG_CROSS_COMPILER_PREFIX/s/=.*/=riscv64-unknown-linux-gnu/' \
	'/CONFIG_FEATURE_INSTALLER/s/=.*/=y/'         \
	'/CONFIG_INIT/s/=.*/=y/'                      \
	'/CONFIG_ASH/s/=.*/=y/'                       \
	'/CONFIG_ASH_JOB_CONTROL/s/=.*/=n/'           \
	'/CONFIG_MOUNT/s/=.*/=y/'                     \
	'/CONFIG_FEATURE_USE_INITTAB/s/=.*/=y/' .config

	$(MAKE)
	cd $(ROOT)/riscv-linux

	#General Setup → "Initial RAM filesystem and RAM disk"
	#General Setup → "Initramfs source file" → "rootfs.cpio"

	$(MAKE) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux

	cd $(ROOT)
	$(MAKE) pk pk="--host=riscv64-unknown-linux-gnu --with-payload=$(ROOT)/riscv-linux/vmlinux"

test: test-pk test-linux
	$(MAKE) -C $(ROOT)/riscv-tests/isa/ run
	$(MAKE) -C $(ROOT)/riscv-tests/benchmarks/ run

test-pk: pk gnu-toolchain
	printf '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c
	riscv64-unknown-elf-gcc -o hello hello.c
	spike pk hello
	$(RM) hello hello.c

test-linux: linux
	printf '#include <stdio.h>\n int main(void) { printf("Hello world!\\n"); return 0; }' > hello.c
	riscv64-unknown-linux-gnu-gcc -static -Wl,-Ttext-segment,0x10000 -o hello hello.c
	spike pk hello
	$(RM) hello hello.c

docs:
	@asciidoctor $(ROOT)/README.adoc $(ROOT)/doc/*.adoc

clean:
	$(RM) -rf $(ROOT)/$(BUILDIRS) $(ROOT)/$(DEST)
	$(RM) -rf $(ROOT)/doc/*.html README.html hello{,.c}

help:
	@echo "usage: $(MAKE) [RISCV='<install/here>'] [<tool>] [<tool>='--<flag> ...'] ..."
	@echo ""
	@echo "install [tool] to \$$RISCV with compiler <flag>'s"
	@echo ""
	@echo "where tool can be any one of:"
	@echo ""
	@echo "    $(PROJECTS)"
	@echo ""
	@echo "defaults:"
	@echo "    RISCV='$(DEST)'"
	@$(foreach project, $(PROJECTS), echo "    $(project)='$($(project))'";)

