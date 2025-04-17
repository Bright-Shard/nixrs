#!/bin/sh

ROOT=$(dirname $0)/..
HELP="\
nixrs
An alternative build system for Rust.

Usage
=====

nixrs help		Show this help menu.
nixrs build		Build the crate you're currently in.
nixrs run		Run the crate you're currently in.
"

cmd=$(echo "$1" | awk '{print tolower($0)}')
crateRoot=$(realpath .)

findCrateRoot() {
	while [ $crateRoot != "/" ]; do
		if [ $(ls $crateRoot | grep "crate.nix") ]; then
			break
		fi
		crateRoot=$(dirname $crateRoot)
	done

	if [ $crateRoot == "/" ]; then
			echo "ERROR: No \`crate.nix\` found in this folder or any of its parent folders. Is this a nixrs project?"
	fi
}
buildCrate() {
	# nix eval --extra-experimental-features nix-command --impure --expr "import $ROOT/nixrs $crateRoot" --debugger
	nix-build "$ROOT/nixrs/default.nix" --arg crateRoot $crateRoot -o target
}

case "$cmd" in
	"run" | "r")
		findCrateRoot
	;;
	"build" | "b")
		findCrateRoot
		buildCrate
	;;
	*)
		echo -e "$HELP"
	;;
esac
