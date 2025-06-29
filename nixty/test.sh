#!/bin/sh

set -e

runNix() {
	nix --extra-experimental-features nix-command eval --show-trace --file $1
}

echo "Running tests..."
time runNix test.nix
echo "(Performance comparison) Running empty Nix file..."
time runNix empty.nix
