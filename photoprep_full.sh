#!/bin/bash
# version 1.0
log='.log'
# Clean up and crop photos ahead of time, making any massive modifications necessary beforehand.
# Rename all photo files before invoking photoprep.
# Depends on:
#		Gimp (http://www.gimp.org/)
#		National Geographic Script (found here: http://registry.gimp.org/node/9592)
#		ImageMagick (http://www.imagemagick.org/script/index.php)
#		DCRAW (for raw processing)

function getRaws() {
	# organize raw Nikon photo files
    # should handle more than just Nikon files.
	raws=echo ls ./original | grep '.nef' #Nikon raw
	return 0
}

function getPhotos() {
	# organize all (png-only) photos to be processed
	photos=echo ls ./original | grep '.png'
	photos+=echo ls ./original | grep '.jpg'
	photos+=echo ls ./original | grep '.cr2' #Canon raw
	return 0
}

function getWatermarks() {
	# organize all watermark files into one variable
	watermarks=echo ls ./Watermarks | grep '.png'
	return 0
}

function convertRAW() {
	# process RAW Nikon (NEF) files to png for further processing
	pngname=${source%.*}
	echo "converting $pngname to png format" >> $log
	dcraw -c6w ./original/$source | pnmtopng > ./original/$pngname.png
}

function processWeb() {
	# process .png photos for the web
	photoname=${photo%.*}
	echo "		$photoname | web effects and resizing" >> $log
	convert -normalize -noise 3 -monitor -background black -adaptive-resize 1280 -adaptive-sharpen 9x3 -sigmoidal-contrast 3x45% -vignette 400x200-150-150 "./original/$photo" "./processed/web_${photoname}.png"
	gimp -idb '(elsamuko-national-geographic-batch "./processed/web_${photoname}.png" 80 .8 55 55 0.1 1 0)' -b '(gimp-quit 0)'
	echo "		$photoname | National Geographic filter complete" >> $log
	for watermark in $watermarks;
	do
		sign $watermark $photoname
	done
	echo "		$photoname | complete - web" >> $log
	return 0
}

function processPrint() {
	photoname=${photo%.*}
	echo "		$photoname | print effects and resizing" >> $log
	convert -normalize -noise 5 -monitor -background black -sigmoidal-contrast 8x45% -vignette 1000x500-500-500 "./original/$photo" "./processed/print_${photoname}.png"
	# gimp -idb '(elsamuko-national-geographic-batch "./processed/print_${photoname}.png" 60 1 60 25 0.4 1 0)' -b '(gimp-quit 0)'
	return 0
}

function sign() {
    # add signature to image

	markname=${watermark%.*}
	composite -gravity south ./Watermarks/$watermark "./processed/web_${photoname}.png" "./processed/${photoname}_${markname}.png"
	echo "		$markname | added to $photoname" >> $log
	if [ -z "$photographer" ];
		then do
			convert ./processed/${photoname}_${markname}.png -font /usr/share/fonts/truetype/Haettenschweiler.ttf -pointsize 32 -gravity southeast -fill white -annotate +5+5 "© $(date +%Y www.driven-daily.com\nPhoto: $photographer" ./processed/${photoname}_${markname}.png
		done;
	fi
	return 0
}

function housekeeping() {
	# clean your room!
	rm -r ./.working_dir
	echo "Finished cleanup. Enjoy your processed photos!" >> $log
	exit 0
}

# clear/set initial variables (messy)
unset raws
unset photos
unset watermarks
photographer=$1

main() {
	# messy main loop, needs organization

    # ensure that required directories exist
	required_dirs=(.working_dir processed original)
	for dir in "${required_dirs[@]}";
	do
		if [ ! -d $dir ]
			mkdir -p $dir/
			then echo "##### $dir required, so it was created #####"
		fi
	done
	
    raws=$(getRaws)
	for source in $raws; #convert all NEF files to .png
	do
		convertRAW $source
	done
	
	photos=$(getPhotos)
	watermarks=$(getWatermarks)

	for photo in $photos;
	do
		processWeb $photo #process for the web
		processPrint $photos #process for print
	done

	housekeeping
}

main
