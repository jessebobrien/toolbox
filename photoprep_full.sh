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

unset raws
unset photos
unset watermarks

getRaws() {
	#organize raw Nikon photo files
	raws=echo ls ./original | grep '.nef' #Nikon raw
	return 0
}

getPhotos() {
	#organize all (png-only) photos to be processed
	photos=echo ls ./original | grep '.png'
	photos+=echo ls ./original | grep '.jpg'
	photos+=echo ls ./original | grep '.cr2' #Canon raw
	return 0
}

getWatermarks() {
	#organize all watermark files
	watermarks=echo ls ./Watermarks | grep '.png'
	return 0
}

convertRAW() {
	#process RAW Nikon (NEF) files to png for further processing
	pngname=${source%.*}
	echo "converting $pngname to png format" >> $log
	dcraw -c6w ./original/$source | pnmtopng > ./original/$pngname.png
}

processWeb() {
	#process .png photos for the web
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

processPrint() {
	photoname=${photo%.*}
	echo "		$photoname | print effects and resizing" >> $log
	convert -normalize -noise 5 -monitor -background black -sigmoidal-contrast 8x45% -vignette 1000x500-500-500 "./original/$photo" "./processed/print_${photoname}.png"
	gimp -idb '(elsamuko-national-geographic-batch "./processed/print_${photoname}.png" 60 1 60 25 0.4 1 0)' -b '(gimp-quit 0)'
	echo "$photoname | National Geographic Effect: complete" >> $log
	return 0
}

sign() {
	markname=${watermark%.*}
	composite -gravity south ./Watermarks/$watermark "./processed/web_${photoname}.png" "./processed/${photoname}_${markname}.png"
	echo "		$markname | added to $photoname" >> $log
	if [ -z "$photographer" ];
		then do
			convert ./processed/${photoname}_${markname}.png -font /usr/share/fonts/truetype/Haettenschweiler.ttf -pointsize 32 -gravity southeast -fill white -annotate +5+5 "© 2012 Driven Daily\nPhoto: $photographer" ./processed/${photoname}_${markname}.png
			echo "		Photo credit added to $photoname" >> $log
		done;
	fi
	return 0
}

housekeeping() {
	#clean your room!
	rm -r ./.working_dir
	echo "Finished cleanup. Enjoy your processed photos!" >> $log
	exit 0
}

photographer=$1

main() {
	#messy main loop, needs organization
	# ensure that required directories exist
	required_dirs=(.working_dir processed original)
	for dir in "${required_dirs[@]}";
	do
		if [ ! -d $dir ]
			mkdir -p $dir/
			then echo "##### $dir required, so it was created #####" >> $log
		else
			echo "##### $dir exists #####" >> $log
		fi
	done
	raws=$(getRaws)
	for source in $raws; #convert all NEF files to .png
	do
		convertRAW $source
	done
	
	photos=$(getPhotos)
	watermarks=$(getWatermarks)

	echo "		Photos to be processed:" >> $log
	for photo in $photos;
	do
		echo $photo >> $log # list all photos to be processed
	done
	echo "		Watermarks to be processed:" >> $log
	for watermark in $watermarks;
	do
		echo $watermark >> $log #list all watermarks to be applied
	done

	for photo in $photos;
	do
		echo "		***** $photo processing started *****" >> $log
		processWeb $photo #process for the web
		processPrint $photos #process for print
		echo "		***** $photo | processing complete *****" >> $log
	done

	echo '##### Core processing complete for all photos, cleanup in progress.#####' >> $log
	housekeeping
}

main
