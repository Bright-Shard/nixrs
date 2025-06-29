#!/bin/sh

# Builds currently working examples.
#
# To build all examples, use `build-all.sh`.

set -e

EXAMPLES_FOLDER=$(dirname $0)
ROOT=$EXAMPLES_FOLDER/..
for example in $(ls $EXAMPLES_FOLDER); do
	if [ -d $EXAMPLES_FOLDER/$example ]; then
		case "$example" in
			"cratesio-dep" | "workspace")
				echo "Skipping blacklisted example '$example'"
			;;
			*)
				echo "Building example '$example'"
				cd $EXAMPLES_FOLDER/$example
				$ROOT/bin/nixrs b
				cd - >/dev/null
			;;
		esac
	fi
done
