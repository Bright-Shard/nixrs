#!/bin/sh

time nix --extra-experimental-features nix-command eval --file test.nix --show-trace
