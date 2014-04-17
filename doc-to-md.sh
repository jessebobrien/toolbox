#!/bin/bash

# Converts .doc, .odt, and .pdf files to standard .md format
# This script is far from perfect/bulletproof. Use at your own risk.

working_dir="$1"

function getDocs() {
	# organize all documents
	docs=echo ls ${working_dir} | grep '.htm'
	docs+=echo ls ${working_dir} | grep '.docx'
	docs+=echo ls ${working_dir} | grep '.odt'
	docs+=echo ls ${working_dir} | grep '.txt'
	docs+=echo ls ${working_dir} | grep '.rtf'
	docs+=echo ls ${working_dir} | grep '.pdf'
	return 0
}

function convertDoc() {
	# if odt or docx
	mimetype=$(mimetype -b ${working_dir}/${document})
    
    # Can this mimetype be handled by libreoffice?
    if [ "$mimetype" == "application/vnd.oasis.opendocument.text" -o "$mimetype" == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ]; then
		echo "Processing $document as a doc file"

        # check to see if this file already exists in the output directory.
        if [ -s "${working_dir}/${document%%.*}*" ]; then
            echo "This file appears to have already been converted. Skipping"
            return 1
        fi

		libreoffice --headless --convert-to html:HTML --outdir ${working_dir}/html ${working_dir}/${document}
		echo "starting html-to-markdown conversion."
		pandoc -f html -t markdown ${working_dir}/html/${document%%.*}.html -o ${working_dir}/converted/${document##*/}.md
        return 0

    # Can this mimetype be handled by pdftotext?
    elif [ "$mimetype" == "application/pdf" ]; then
		#process as a pdf
		echo "Processing $document as PDF"
		pdftotext ${working_dir}/${document} ${working_dir}/txt/${document%%.*}.txt
        return 0
	else
		echo "Couldn't decide how to process this file."
        return 1
	fi
	echo "$document processed."
	echo
	echo
}

function main() {
	# manage the main functions
	doclist=$(getDocs)
	echo "Document list: ${doclist}"
	echo
	echo

	# IFS must be changed to ignore spaces
	SAVEIFS=$IFS #retain original IFS
	IFS=$(echo -en "\n\b") #reset IFS to a newline
	for document in $doclist;
	do
		echo "${working_dir}/${document} processing started."
        if (convertDoc ${document}); then
            echo "Converted successfully. Cleaning up the source file."
        	mv ${working_dir}/${document} ${working_dir}/.processed
        else
            echo "There was an error with ${document}";
        fi
	done
	IFS=$SAVEIFS #revert original IFS
}

main
