#! /bin/bash
# toss destination folder contents into 'unsorted' bin

# convert all to ogg
dir2ogg -rdwm $AudioDir >> $AudioDir/ogg_conversion.log

# convert id3v1 to id3v2 tags
id3v2 -C $AudioDir/*
# read id3 tags, move untagged folders into 'unsortable' folder

# sort into artist folders

# rename to format: "album - title"


