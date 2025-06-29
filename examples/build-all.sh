#!/bin/sh

# Builds all examples.
#
# To only build currently functional ones, use `build-valid.sh`.

set -e

ROOT=$(dirname $0)
for example in $(ls $ROOT); do
	if [ -d $ROOT/$example ]; then
		echo "Building example '$example'"
		cd $ROOT/$example
		nixrs b
		cd - >/dev/null
	fi
done
