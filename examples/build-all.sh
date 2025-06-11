#!/bin/sh

ROOT=$(dirname $0)
for example in $(ls $ROOT); do
	if [ -d $example ]; then
		cd $example
		nixrs b
		cd - >/dev/null
	fi
done
