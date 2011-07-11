#! /bin/sh

set -e
set -u

## Which folders do you want to Backup? (Without trailing "/")
# SOURCES="/Library /System /bin /etc /mach_kernel /private /sbin /tmp /usr /var /etc /opt /Volumes/Macintosh/Library /Volumes/Macintosh/System /Volumes/Macintosh/Users /Volumes/Macintosh/Applications"
SOURCES="/Volumes/Macintosh/Users/chris/Downloads"

# Any non-valuable stuff to exclude by name/location (seperated by ",")?
EXCLUDE='.DS_Store,/.chris/,./elli/,LastPass/pipes/,log/,.log,/tmp/*,/Network/*,/cores/*,*/.Trash,/afs/*,/automount/*,/private/tmp/*,/private/var/run/*,/private/var/spool/postfix/*,/private/var/vm/*,.Spotlight-*/'

## Your server login ("username@server")
SSH_USER="chris@baader"

## What's your path for Backups on the Server? (i.e. "/home/username/backups"
SRV_PATH="/volume1/homes/chris/Backup"

## The path to your rsync binary (usually "/usr/bin/rsync")
RSYNC="/usr/local/bin/rsync"


### DO NOT EDIT BELOW THIS LINE ###

## Get the hostname of the client
SRCHOST=`hostname -fs`

## Add cleint name to the backup path
SRV_PATH="${SRV_PATH}/${SRCHOST}/"

echo $SRV_PATH

## Split SSH_USER in username and host
SRV_USER=${SSH_USER%@*}
SRV_HOST=${SSH_USER#*@}

## The name for the snapshots
SNAPSHOT_ID=`date "+%Y-%m-%d-%H%M%S"`

# Is your server online?
ping -o $SRV_HOST > /dev/null || {
  echo "WARNING: can't see $SRV_HOST -- skipping backup"
  exit 1
}

# Are we able to create and write to the backup folder?
ssh $SSH_USER "test -d $SRV_PATH" || {
  ssh $SSH_USER "mkdir -p $SRV_PATH" || {
  	echo "ERROR: can't see $SSH_USER:$SRV_PATH" >&2
  	exit 2
  }
}

## Modify the excludes list for rsync
EXPEXCLUDES=`eval "echo --exclude={$EXCLUDE} "`

## Do it!
sudo $RSYNC -v --archive --verbose \
  --delete --delete-excluded \
  $EXPEXCLUDES \
  --numeric-ids \
  --one-file-system \
  --partial \
  --link-dest ../Latest/ \
  --relative \
  $SOURCES \
  $SSH_USER:$SRV_PATH/in.Progress/
  
## Finish backup and get some cleaning done
ssh $SSH_USER "cd $SRV_PATH; rm -fr $SNAPSHOT_ID; mv in.Progress $SNAPSHOT_ID; rm -f Latest; ln -s $SNAPSHOT_ID $SRV_PATH/Latest"