#!/bin/sh

set -e
set -x

[ $(id -u) -eq 0 ] || {
	printf >&2 '%s requires root\n' "$0"
	exit 1
}

usage() {
	printf >&2 '%s: [-r release] [-m mirror] [-s] [-a CPU architecture] [-c additional repository]\n' "$0"
	exit 1
}

tmp() {
	TMP=$(mktemp -d ${TMPDIR:-/var/tmp}/alpine-docker-XXXXXXXXXX)
	ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/alpine-docker-rootfs-XXXXXXXXXX)
	trap "rm -rf $TMP $ROOTFS" EXIT TERM INT
}

apkv() {
	curl -sSL $MAINREPO/$ARCH/APKINDEX.tar.gz | tar -Oxz |
		grep '^P:apk-tools-static$' -A1 | tail -n1 | cut -d: -f2
}

getapk() {
	curl -sSL $MAINREPO/$ARCH/apk-tools-static-$(apkv).apk |
		tar -xz -C $TMP sbin/apk.static
}

mkbase() {
        mkdir -p $ROOTFS/usr/bin
        [ $ARCH = armhf ] && cp /usr/bin/qemu-arm-static $ROOTFS/usr/bin || :
	$TMP/sbin/apk.static --repository $MAINREPO --update-cache --allow-untrusted \
		--root $ROOTFS --arch $ARCH --initdb add alpine-base
        [ $ARCH = armhf ] && rm $ROOTFS/usr/bin/qemu-arm-static || :
}

conf() {
	printf '%s\n' $MAINREPO > $ROOTFS/etc/apk/repositories
	printf '%s\n' $ADDITIONALREPO >> $ROOTFS/etc/apk/repositories
}

pack() {
	local id
	id=$(tar --numeric-owner -C $ROOTFS -c . | docker import - alpine:$REL)
	
	docker tag $id alpine:latest
	docker run -i -t --rm alpine printf 'alpine:%s with id=%s created!\n' $REL $id
}

save() {
	[ $SAVE -eq 1 ] || return

	tar --numeric-owner -C $ROOTFS -c . | xz > /tmp/rootfs_$ARCH.tar.xz
}

while getopts "hr:m:a:s" opt; do
	case $opt in
		r)
			REL=$OPTARG
			;;
		m)
			MIRROR=$OPTARG
			;;
		s)
			SAVE=1
			;;
		a)
			ARCH=$OPTARG
			;;
		c)
			ADDITIONALREPO=community
			;;
		*)
			usage
			;;
	esac
done

REL=${REL:-edge}
MIRROR=${MIRROR:-http://nl.alpinelinux.org/alpine}
SAVE=${SAVE:-0}
MAINREPO=$MIRROR/$REL/main
ADDITIONALREPO=$MIRROR/$REL/community
ARCH=${ARCH:-$(uname -m)}

tmp
getapk
mkbase
conf
#pack
save
