#!/bin/bash
# Automated script to fetch repositories 
# Designed to be run as a Cron job

function gitpulls () {
	# fetch repositories in subdirectories
	echo "$(find . -name '.git' | sort)" | while read i; do
		cd "$(dirname ${i})"
		echo "Pulling $(dirname ${i#./}) repository"
		git pull
		cd - > /dev/null;
	done
	unset i
}

# Main Loop
# This section only exists for extensibility.
gitpulls