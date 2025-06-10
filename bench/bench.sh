#!/bin/sh

if [ -z "$1" ]; then
	echo "Usage: $0 <crate>"
fi

ROOT=$(dirname $0)

cd $ROOT/$1

rm -rf target
rm -rf toolchain-sysroot

nixrs b
if [ ! $? = 0 ]; then
	echo "Nixrs failed to build, exiting..."
	exit 1
fi
ln -sf $(realpath target/toolchain-sysroot) toolchain-sysroot
rmdir --ignore-fail-on-non-empty $(realpath target)
echo "nixrs cold build"
time nixrs b
rm -rf target
echo "cargo cold build"
time cargo b
echo "cargo warm build"
time cargo b
echo "nixrs warm build"
rm -rf target
nixrs b
sleep 1
time nixrs b
