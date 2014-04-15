#!/bin/bash
# This is a script to convert markdown-formatted text files to pdf, html, and .docx formatted output files. It depends on LaTeX (for PDF, the xelatex engine appears to support styling the best) and Pandoc (for markdown handling), and should be run when files are changed, or as a cron job for an entire directory.

#file-specific variables
# Authored in 2012 by Jesse O'Brien (jesse.b.obrien@gmail.com) to maintain end-user technical manuals and documentation.
# This is a script to convert markdown-formatted text files to pdf, html, and .docx formatted output files. 
# It depends on LaTeX (for PDF, the xelatex engine appears to support styling the best) and Pandoc (for markdown handling).
# This script should be run when files are changed, as a cron job for an entire directory, or on an entire filesystem.
# Further markdown documentation can be found on the pandoc website (I don't have the link handy right now).

# future feature: add usage documentation

# file-specific variables
sourcefile="$1"
filename=$(basename "$sourcefile")
filename="${filename%.*}"
directory=$(dirname "$sourcefile")

#script-specific variables (should be abstracted to args, such as --pdf --html --docx or -phd)
formats="pdf html docx"

#main loop to convert source .txt file to all listed formats
for format in $formats
do
	# should compare the modification times and sizes of the source and destination, and only change if a substantial (>5minute) difference is found. 
	echo "Converting $sourcefile to $directory/$filename.$format"
	# Convert to PDF
	if [ $format == "pdf" ]
		then
			pandoc --toc --tab-stop=2 --chapters -s --variable mainfont="Kinnari" --variable monofont="FreeMono" --variable fontsize="12pt" --variable urlcolor="red" --latex-engine=xelatex "${sourcefile}" -o "$directory/${filename}.pdf"
			echo "Success!"
	fi
	#Convert to HTML
	if [ $format == "html" ]
		then
			pandoc --toc --tab-stop=2 --chapters -s "${sourcefile}" -o "$directory/${filename}.html"
	fi
	#Convert to DOCX
	if [ $format == "docx"]
		then
			pandoc --toc --tab-stop=2 --chapters -s "${sourcefile}" -o "$directory/${filename}.docx"
	fi
	echo "Finished converting $sourcefile to $directory/$filename.$format."
	echo "All files are located in $directory."
# script-specific variables (should be abstracted to args, such as --pdf --html --docx or -phd)
formats="pdf html docx"

# main loop to convert source .txt file to all listed formats
for format in $formats
do
    # should compare the modification times and sizes of the source and destination, and only change if a substantial (>5minute) difference is found. 
    echo "Converting $sourcefile to $directory/$filename.$format"
    # Convert to PDF
    if [ $format == "pdf" ]
        then
            pandoc --toc --tab-stop=2 --chapters -s --variable mainfont="Kinnari" --variable monofont="FreeMono" --variable fontsize="12pt" --variable urlcolor="red" --latex-engine=xelatex "${sourcefile}" -o "$directory/${filename}.pdf"
            echo "Success!"
    fi
    #Convert to HTML
    if [ $format == "html" ]
        then
            pandoc --toc --tab-stop=2 --chapters -s "${sourcefile}" -o "$directory/${filename}.html"
    fi
    #Convert to DOCX
    if [ $format == "docx"]
        then
            pandoc --toc --tab-stop=2 --chapters -s "${sourcefile}" -o "$directory/${filename}.docx"
    fi
    echo "Finished converting $sourcefile to $directory/$filename.$format."
    echo "All files are located in $directory."
done #ends for loop
exit
