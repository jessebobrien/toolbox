#!/bin/bash
# Simple script to unzip all .zip files in a dir

for zipfile in $(ls *.zip)
	do
		unzip $zipfile
	done
