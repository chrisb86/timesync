#! /bin/sh

#set -e
#set -u

## Which folders do you want to Backup? (Without trailing "/")
# SOURCES="/Library /System /bin /etc /mach_kernel /private /sbin /tmp /usr /var /etc /opt /Volumes/Macintosh/Library /Volumes/Macintosh/System /Volumes/Macintosh/Users /Volumes/Macintosh/Applications"
SOURCES="/Volumes/Macintosh/Users/chris"

# Any non-valuable stuff to exclude by name/location (seperated by ",")?
EXCLUDE='.DS_Store,/.chris/,./elli/,LastPass/pipes/,log/,.log,/tmp/*,/Network/*,/cores/*,*/.Trash,*/.Trashes,/afs/*,/automount/*,/private/tmp/*,/private/var/run/*,/private/var/spool/postfix/*,/private/var/vm/*,.Spotlight-*/'

## Your server login ("username@server")
SSH_USER="chris@baader"

## Where should I write the errorlog?
ERRORLOG="/Users/chris/backup-errors.log"

## What's your path for Backups on the Server? (i.e. "/home/username/backups"
SRV_PATH="/volume1/homes/chris/Backup"

## The path to your rsync binary (usually "/usr/bin/rsync")
RSYNC="/usr/local/bin/rsync"


### DO NOT EDIT BELOW THIS LINE ###

## Get the hostname of the client
SRCHOST=`hostname -fs`

## Add client name to the backup path
SRV_PATH="${SRV_PATH}/${SRCHOST}/"

## Split SSH_USER in username and host
SRV_USER=${SSH_USER%@*}
SRV_HOST=${SSH_USER#*@}

# Get the date and time
DATE=`date "+%Y-%m-%d-%H%M%S"`

## Check if we're running as root

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Script must be run as root. Skipping backup."
   exit 1
fi

## Check, if another backup is in progress and stop if it is
PROCS=`ps -A -o "pid=,command="`
MYNAME="$0"
MYBASENAME=`basename $MYNAME`
MYPID=$$
 
# The next line works like so:
# * take the process list (for all users),
# * filter *in* processes named like this script (making sure we're on word boundaries),
# * filter *out* (-v) the one that *is* this script (by PID), and finally
# * filter *out* the grep commands themselves.
 
MERUNNING=`echo "$PROCS" | grep -E -e "\b$MYBASENAME\b" \
  | grep -E -v "\b$MYPID\b" | grep -v grep`
 
## Then, if anything's left (i.e. MERUNNING isn't a zero-length string...)
 
if [ ! -z "$MERUNNING" ]; then
  echo "WARNING: Another backup seems to be in progress. Ignoring scheduled backup"
  exit 2
fi 

# Is the server online?
SRV_DOWN=`ping -c 3 $SRV_HOST >&1 | grep -c "100.0%"`

if [ "$SRV_DOWN" -eq 1 ]; then
  echo "ERROR: $SRV_HOST is unreacheble. Skipping Backup."
  exit 3
fi

# Are we able to create and write to the backup folder?
ssh $SSH_USER "test -d $SRV_PATH" || {
  ssh $SSH_USER "mkdir -p $SRV_PATH" || {
  	echo "ERROR: Can't access $SSH_USER:$SRV_PATH. Skipping backup."
  	exit 4
  }
}

## The name for the snapshots
SNAPSHOT_ID=$DATE

## Modify the excludes list for rsync
EXPEXCLUDES=`eval "echo --exclude={$EXCLUDE} "`

## Do it!
RUN_RSYNC=`sudo $RSYNC -v --archive \
  --delete --delete-excluded \
  $EXPEXCLUDES \
  --numeric-ids \
  --one-file-system \
  --partial \
  --link-dest ../Latest/ \
  --relative \
  $SOURCES \
  ${SSH_USER}:${SRV_PATH}in.Progress/ \
  2>&1 > $ERRORLOG`

if [ -z "$RUN_RSYNC" ]; then
	## Finish backup and get some cleaning done
	ssh $SSH_USER "cd $SRV_PATH; rm -fr $SNAPSHOT_ID; mv in.Progress $SNAPSHOT_ID; rm -f Latest; ln -s $SNAPSHOT_ID $SRV_PATH/Latest"
else
	echo "There were some errors while backing up $SRV_HOST. See $ERRORLOG for further information."
	exit 5
fi