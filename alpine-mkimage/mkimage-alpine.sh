#!/bin/sh

set -e

[ $(id -u) -eq 0 ] || {
	printf >&2 '%s requires root\n' "$0"
	exit 1
}

usage() {
	printf >&2 '%s: [-v] [-r release] [-m mirror] [-s] [-a CPU architecture] [-c additional repository] [-p additional packages]\n' "$0"
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
    # TODO
    # Get right qemu-static both for HOST (machine with Docker Engine) and TARGET ($ARCH) architecture
    case $ARCH in
        armhf)
            cp /usr/bin/qemu-arm-static $ROOTFS/usr/bin
            ;;
        x86)
            cp /usr/bin/qemu-i386-static $ROOTFS/usr/bin
            ;;
        *)
            ;;
    esac
	$TMP/sbin/apk.static --repository $MAINREPO --update-cache --allow-untrusted \
		--root $ROOTFS --arch $ARCH --initdb add alpine-base $PKGS
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

while getopts "hvr:m:a:sp:" opt; do
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
		v)
			VERBOSE=1
			;;
		a)
			ARCH=$OPTARG
			;;
		c)
			ADDITIONALREPO=community
			;;
		p)
			PKGS=$OPTARG
			;;
		*)
			usage
			;;
	esac
done

[ $VERBOSE -eq 1 ] && set -x || :

REL=${REL:-edge}
MIRROR=${MIRROR:-http://nl.alpinelinux.org/alpine}
SAVE=${SAVE:-0}
MAINREPO=$MIRROR/$REL/main
ADDITIONALREPO=$MIRROR/$REL/community
ARCH=${ARCH:-$(uname -m)}
PKGS=${PKGS:-''}

tmp
getapk
mkbase
conf
#pack
save
