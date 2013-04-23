#!/bin/bash

# Creates a rotating backup
# Jesse O'Brien Sept 11, 2012

# Usage: backupcontroller.sh

# User configuration options
# Edit values below to change the behavior of this script

SOURCE="/home/jobrien/Development/"
DESTINATION="/home/jobrien/backup"
HOSTNAME=`hostname -s`
#Total number of backups to keep
ROTATIONS=5

# List files or directories to skip
EXCLUDES="lost+found"
EXCLUDES_FILE="${DESTINATION}/etc/backups.exclude"

# Error email address
MAILTO="jesse.b.obrien@gmail.com"

# Generic error when there aren't enough backups
ERROR="There are fewer than ${ROTATIONS} backup(s) available in ${DESTINATION} on ${HOSTNAME}."

# Lock file location
LOCK=/var/lock/backup_controller.lock

# Sleep time configuration
SLEEP_TIME=.1
sleep ${SLEEP_TIME}

# Check for running backups
if [ -e "${lock}" ]; then
	# Yes, error out
	logger -s "A backup lockfile exists. Exiting."
	exit 1
fi

# Is an external drive present?
if [ -d "${DESTINATION}" ]; then
	# Yes
	logger "${DESTINATION} disk is mounted, continuing..."
else
	# No
	logger -s "${DESTINATION} disk _not_ mounted, exiting."
	exit 1
fi

# Is there an excludes file present?
if [ -e ${excludes_file} ]; then
	RSYNC_ARGS='-a --delete --exclude='${EXCLUDES}' --exclude-from='${EXCLUDES_FILE}' --delete-excluded'
else
	RSYNC_ARGS='-a --delete --exclude='${EXCLUDES}' --delete-excluded'
fi

# Check for free space
NEED=`${RSYNC} -n --stats ${RSYNC_ARGS} ${ORIGIN} ${DESTINATION}/Backups.1/ | grep "Total transferred" | awk '{print $5}'`
HAVE0=`df -k ${DESTINATION} | grep -v File | awk '{print $4}'`
NEED=$[${need}/1024]
HAVE=$[${have0}*100/105] # Leaves 5% of disk space free, just in case.

logger "I Need ${NEED} kB, I have ${HAVE} kB (${HAVE0} kB actual)"

# Touch the lock file.
touch ${LOCK}

# Start pruning old backups, as necessary.
while [ "${have}" -lt "${need}" ]; do
	# See if there is anything I can delete.
	NUMBAK=`ls -d ${DESTINATION}/Backups.* | wc -l 2>/dev/null`
	if [ "${numbak}" -eq "0" ]; then
		logger -s "There is insufficient space on ${DESTINATION} to do backups."
		exit 1
	fi

	# Find the oldest files and delete them until we have room.
	OLDEST=`ls -trd ${DESTINATION}/Backups.* | head -1`
	logger -s "Deleting ${OLDEST}..."
	rm -rf ${OLDEST}
	
	# Update the variable so I can retest.
	HAVE0=`df -k ${DESTINATION} | grep -v File | awk '{print $4}'`
	HAVE=$[${have0}*100/105] # Again, leave a 5% buffer.
done

# Now we have enough room to backup.
logger "We have enough disk space, continuing..."

# Current number of Backups available
numbak=`ls -d ${DESTINATION}/Backups.* | wc -l 2>/dev/null`

# Rotate the older files
until [ "${numbak}" -lt "2" ];do
	logger "Moving ${DESTINATION}/Backups.${NUMBAK} to ${DESTINATION}/Backups.$((NUMBAK+1))"
	mv  "${DESTINATION}/Backups.${NUMBAK}" "${DESTINATION}/Backups.$((NUMBAK+1))" 
	NUMBAK=$((NUMBAK-1))
done

# Hard link the newest backup to backup.(almost new)
if [ -e "${DESTINATION}/backups.1" ]; then
	# Yes
	logger "Linking ${DESTINATION}/Backups.1 to ${DESTINATION}/Backups.2"
	${CP} -al "${DESTINATION}/Backups.1" "${DESTINATION}/Backups.2" 
fi

# And finally, rsync the new differences
logger "Syncing the new and updated files."
${RSYNC} ${RSYNC_ARGS} ${ORIGIN} ${DESTINATION}/Backups.1

# Touch the directory so that the timestamp is updated
touch ${DESTINATION}/Backups.1

# Give me a logger timestamp knowing when I finish
logger "Backup Finished."
rm -f ${LOCK}

# If the number of backups is < the desired number, email a warning.
NUMBAK=`ls -d ${DESTINATION}/Backups.* | wc -l`
if [ "${numbak}" -lt "$rotations" ]; then
	${WALL} "Be advised, you have ${NUMBAK} backup(s) available in ${DESTINATION}."
	echo ${ERROR} | ${MAIL} -s "`hostname -s` has only ${NUMBAK} of ${ROTATIONS} backup(s) available." ${MAILTO}
fi