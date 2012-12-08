#!/bin/bash
gitpulls ()
{
	#fetches repositories in subdirectories
	echo "$(find . -name '.git' | sort)" | while read i; do
		cd "$(dirname ${i})"
		echo ">>>> pulling $(dirname ${i#./}) ... <<<<"
		git pull
		echo ''
		cd - > /dev/null;
	done
	unset i
}

gitpulls
