#! /bin/sh

set -e 

snapshot_host=baader
snapshot_dir=/volume1/homes/chris/Backup
snapshot_user=chris
ssh_user=$snapshot_user@$snapshot_host

ping -o $snapshot_host > /dev/null || {
  echo "WARNING: can't see $snapshot_host -- skipping backup"
  exit 1
}

ssh $ssh_user "test -d $snapshot_dir" || {
  echo "ERROR: can't see $ssh_user:$snapshot_dir" >&2
  exit 2
}
  
snapshot_id=`date "+%Y-%m-%d-%H%M%S"`

/usr/bin/rsync --archive --verbose \
  --delete --delete-excluded \
  --numeric-ids \
  --one-file-system \
  --partial \
  --link-dest ../current/ \
  --relative \
  /Users/chris/Downloads /Users/chris/bin /Users/chris/Library \
  $ssh_user:$snapshot_dir/in-progress/

ssh $ssh_user "cd $snapshot_dir; rm -fr $snapshot_id; mv in-progress $snapshot_id; rm -f current; ln -s $snapshot_id $snapshot_dir/current"