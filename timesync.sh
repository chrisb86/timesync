#! /bin/sh

set -e 

SOURCES="/Library /System /bin /etc /mach_kernel /private /sbin /tmp /usr /var /etc /opt /Volumes/Macintosh/Library /Volumes/Macintosh/System /Volumes/Macintosh/Users /Volumes/Macintosh/Applications"

SRCHOST=`hostname -fs`
snapshot_host=baader
snapshot_user=chris
snapshot_dir=/volume1/homes/chris/Backup/$SRCHOST
ssh_user=$snapshot_user@$snapshot_host

ping -o $snapshot_host > /dev/null || {
  echo "WARNING: can't see $snapshot_host -- skipping backup"
  exit 1
}

ssh $ssh_user "test -d $snapshot_dir" || {
  ssh $ssh_user "mkdir -p $snapshot_dir" || {
  	echo "ERROR: can't see $ssh_user:$snapshot_dir" >&2
  	exit 2
  }
}
  
snapshot_id=`date "+%Y-%m-%d-%H%M%S"`

/usr/bin/rsync --archive --verbose \
  --delete --delete-excluded \
  --numeric-ids \
  --one-file-system \
  --partial \
  --link-dest ../current/ \
  --relative \
  $SOURCES \
  $ssh_user:$snapshot_dir/in-progress/

ssh $ssh_user "cd $snapshot_dir; rm -fr $snapshot_id; mv in-progress $snapshot_id; rm -f current; ln -s $snapshot_id $snapshot_dir/current"