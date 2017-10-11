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
	@echo "* Add the following to your profile:"
	@echo "  export PATH=$(DEST)/bin:\$$PATH"

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

linux: busybox
	$(MAKE) -C $(ROOT)/riscv-linux ARCH=riscv defconfig
	$(MAKE) -C $(ROOT)/riscv-linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu-

BBCONF := \
CONFIG_STATIC=y \
CONFIG_CROSS_COMPILER_PREFIX=riscv64-unknown-linux-gnu \
CONFIG_FEATURE_INSTALLER=y \
CONFIG_INIT=y \
CONFIG_ASH=y \
CONFIG_ASH_JOB_CONTROL=n \
CONFIG_MOUNT=y \
CONFIG_FEATURE_USE_INITTAB=y

busybox:
	[ -e "${BUSYBOX}" ] || curl -L http://busybox.net/downloads/${BUSYBOX}.tar.bz2 | tar xjf -
	$(MAKE) -C $(ROOT)/$(BUSYBOX) allnoconfig
	$(foreach line, $(BBCONF), $(file >>$(ROOT)/$(BUSYBOX)/.config,$(line)))
	$(MAKE) -C $(ROOT)/$(BUSYBOX)
	#General Setup → "Initial RAM filesystem and RAM disk"
	#General Setup → "Initramfs source file" → "rootfs.cpio"
	$(MAKE) -C $(ROOT)/riscv-linux ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux
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

