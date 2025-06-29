#!/bin/sh

# Builds currently working examples.
#
# To build all examples, use `build-all.sh`.

set -e

ROOT=$(dirname $0)
for example in $(ls $ROOT); do
	if [ -d $ROOT/$example ]; then
		case "$example" in
			"cratesio-dep" | "workspace")
				echo "Skipping blacklisted example '$example'"
			;;
			*)
				echo "Building example '$example'"
				cd $ROOT/$example
				nixrs b
				cd - >/dev/null
			;;
		esac
	fi
done
