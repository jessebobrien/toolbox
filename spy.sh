#!/bin/bash

# Create a list of users and direct it to a file.
cat /etc/passwd | grep bash | grep home | awk -F: '{print $1}' > names.txt

# Create an HTML file. This part must be outside the loop. This is a clunky implementation ... replace with if -d file.
touch user_space.html
mv user_space.html user_space.html.old
touch user_space.html
# Start the WHILE loop
while read NAME
	do
		# This sets output of the command to the variable name, SPACE.
		SPACE=`du -shm /home/$NAME | awk -F" " '{print $1}'`
		echo " <br>" >> user_space.html
	done < names.txt
# End the table entry outside the loop.
echo "
User	|	Space<br>
$NAME	|	$SPACE
" >> user_space.html
