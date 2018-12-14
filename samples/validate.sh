#!/bin/sh
for file in "$@"
do
	echo "Validating $file:"
	StdInParse -v=always -n -s -f < $file
done

