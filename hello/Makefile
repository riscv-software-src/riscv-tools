#=======================================================================
# Makefile for the Hello World programs
#-----------------------------------------------------------------------

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX=riscv64-unknown-elf-
RISCV_GCC = $(RISCV_PREFIX)gcc
RISCV_LINUX_PREFIX=riscv-linux-
RISCV_LINUX_GCC = $(RISCV_LINUX_PREFIX)gcc

RISCV_GCC_OPTS = -std=gnu99 -O3 -DPREALLOCATE=1
RISCV_GCC_BARE_LNK_OPTS = -nostdlib -nostartfiles -lc
RISCV_LINUX_GCC_OPTS = -I.. -O3 -static

#--------------------------------------------------------------------
# Build
#--------------------------------------------------------------------

hello.bare: hello.bare.o syscalls.o crt.o 
	$(RISCV_GCC) -T ./common/test.ld $^ -o $@ $(RISCV_GCC_BARE_LNK_OPTS)

hello.bare.o:hello.c
	$(RISCV_GCC) -static -DBARE_MODE $(RISCV_GCC_OPTS) -c $< -o $@

syscalls.o:common/syscalls.c
	$(RISCV_GCC) -static -Icommon -Ienv $(RISCV_GCC_OPTS) -c $< -o $@

crt.o:common/crt.S
	$(RISCV_GCC) -static -Icommon -Ienv $(RISCV_GCC_OPTS) -c $< -o $@

hello.pk: hello.c
	$(RISCV_GCC) $(RISCV_GCC_OPTS) $< -o $@

hello.linux: hello.c
	$(RISCV_LINUX_GCC) $(RISCV_LINUX_GCC_OPTS) $< -o $@

all: hello.bare hello.pk hello.linux

clean:
	rm -fr *.o hello.bare hello.linux hello.pk
