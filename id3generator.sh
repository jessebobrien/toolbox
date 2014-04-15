#! /bin/bash

for fn in /home/irish/Music/*/*/*.m4a
	do
		if [ -f "$fn" ];then
			p='.*/\([^/]*\'
			title=$(echo "$fn" | sed "s%$p\.m4a$%\1%")
			album=$(echo "$fn" | sed "s%$p/$title\.m4a$%\1%")
			artist=$(echo "$fn" | sed "s%$p/$album/$title\.m4a$%\1%")
			# testing purposes only
			echo id3tool -t "$title" -a "$album" -r "$artist" "$fn"
		fi
	done
