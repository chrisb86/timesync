
## Updating rsync on OS X

The rsync version that's delivered with OS X is barely old and doesn''t work properly.

To update to a never version you need to download the current version and compile it by hand.

1. Install Xcode (from your OS X DVD or the AppStore)
2. Open a Terminal
	
	cd ~/Downloads/
    curl -O http://rsync.samba.org/ftp/rsync/src/rsync-3.0.8.tar.gz
    curl -O http://rsync.samba.org/ftp/rsync/src/rsync-patches-3.0.8.tar.gz
    tar -xzvf rsync-3.0.8.tar.gz
	tar -xzvf rsync-patches-3.0.8.tar.gz
	cd rsync-3.0.8
	patch -p1 <patches/fileflags.diff
	patch -p1 <patches/crtimes.diff
	./prepare-source
	./configure
	make
	sudo make install
	
3. Your newly updated binary is located in /usr/local/bin/rsync.
4. Paste this path to the config section of timesync


## Changelog

### 2011-07-11

* Did some code cleanup
* If the target directory on the server doesn't exist, we now try to create it
* Now a folder for every client is created in the backup directory
* rsync is now running as root
* Put some documentation in the code and startet the README and changelog
* Cleaned up the variable names
* Added some error handling (must run as root, host unrechable, write logfile)

### 2011-07-10

* Initial release with code from [Mike Williams] (http://dogbiscuit.org/mdub/weblog/Tech/Mac/Rsync1TimeMachine0)