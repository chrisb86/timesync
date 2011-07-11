#! /bin/sh

set -e 

## Which folders do you want to Backup? (Without trailing "/")
# SOURCES="/Library /System /bin /etc /mach_kernel /private /sbin /tmp /usr /var /etc /opt /Volumes/Macintosh/Library /Volumes/Macintosh/System /Volumes/Macintosh/Users /Volumes/Macintosh/Applications"
SOURCES="/Volumes/Macintosh/Users/chris"

## Your server login ("username@server")
SSH_USER="chris@baader"

## What's your path for Backups on your Server? (i.e. "/home/username/backups"
SNAPSHOT_DIR="/volume1/homes/chris/Backup"

## Path to your rsync exclude file
EXCLUDE_FILE="/Users/chris/bin/backup_excludes.txt"

## The path to your rsync binary (usually "/usr/bin/rsync")
RSYNC="/usr/local/bin/rsync"


### DO NOT EDIT BELOW THIS LINE ###

## Get the hostname of the client
SRCHOST=`hostname -fs`

## Add cleint name to the backup path
SNAPSHOT_DIR="${SNAPSHOT_DIR}/${SRCHOST}/"

## Split SSH_USER in username and host
SNAPSHOT_USER=${SSH_USER%@*}
SNAPSHOT_HOST=${SSH_USER#*@}

## The name for the snapshots
SNAPSHOT_ID=`date "+%Y-%m-%d-%H%M%S"`

# Is your server online?
ping -o $SNAPSHOT_HOST > /dev/null || {
  echo "WARNING: can't see $SNAPSHOT_HOST -- skipping backup"
  exit 1
}

# Are we able to create and write to the backup folder?
ssh $SSH_USER "test -d $SNAPSHOT_DIR" || {
  ssh $SSH_USER "mkdir -p $SNAPSHOT_DIR" || {
  	echo "ERROR: can't see $SSH_USER:$SNAPSHOT_DIR" >&2
  	exit 2
  }
}

## Do it!
sudo $RSYNC -v --archive --verbose \
  --delete --delete-excluded \
  --exclude-from $EXCLUDE_FILE \
  --numeric-ids \
  --one-file-system \
  --partial \
  --link-dest ../current/ \
  --relative \
  $SOURCES \
  $SSH_USER:$SNAPSHOT_DIR/in-progress/
  
## Finish backup and get some cleaning done
ssh $SSH_USER "cd $SNAPSHOT_DIR; rm -fr $SNAPSHOT_ID; mv in-progress $SNAPSHOT_ID; rm -f current; ln -s $SNAPSHOT_ID $SNAPSHOT_DIR/current"