#!/bin/sh

BBVERSION="1-26.2"

usage () {

    echo "usage: $0 [options] ..."
    echo
    echo "where [options] are any one of"
    echo
    echo "dynamic"
    echo "    setup for building dynamically"
    echo "getty"
    echo "    use getty instead of ash"
    echo "fuse"
    echo "    use FUSE instead of mount(1)"

}

if [ -e "$RISCV" ];
    echo "error: \$RISCV must be set"
fi

mkdir root
cd root
mkdir -p bin etc dev lib proc sbin sys tmp usr usr/bin usr/lib usr/sbin
cp $RISCV/busybox-$BBVERSION/busybox bin

if [ "$@" = "dynamic" ]; then
    if [ $(ldconfig -p | grep libc.so.6) ]; then
        echo "libc.so.6 required"
    fi
    if [ $(ldconfig -p | grep ld.so.1) ]; then
        echo "ld.so.1 required"
    fi

    cp $RISCV/build/sysroot64/lib/libc.so.6 lib/
    cp $RISCV/build/sysroot64/lib/ld.so.1 lib/
    cd $RISCV/busybox-$BBVERSION
    sed -i 's/CONFIG_STATIC=y/# CONFIG_STATIC is not set/' .config
fi

if [ "$@" = "getty" ]; then
    five="::respawn:/bin/busybox getty 38400 ttyHTIF0"
fi

echo "::sysinit:/bin/busybox mount -t proc proc /proc
::sysinit:/bin/busybox mount -t tmpfs tmpfs /tmp
::sysinit:/bin/busybox mount -o remount,rw /dev/htifblk0 /
::sysinit:/bin/busybox --install -s
/dev/console::sysinit:-/bin/ash" > mnt/etc/inittab

ln -s ../bin/busybox mnt/sbin/init
ln -s sbin/init init

sudo mknod dev/console c 5 1
find . | cpio --quiet -o -H newc > $RISCV/riscv-linux/rootfs.cpio

if=/dev/zero of=root.bin bs=1M count=64
mkfs.ext2 -F root.bin

mkdir mnt

if [ "$@" = "fuse" ]; then
    fuseext2 -o rw+ root.bin mnt
    fusermount -u mnt
else
    mount -o loop root.bin mnt
    umount mnt
fi


