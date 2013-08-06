#!/bin/bash

# Call this from a script that sets up these variables:
# * SVNUSER and SVNPASS, the user for core.svn write operations.
# * DEVELOP_REPO and CORE_REPO, paths to the local SVN repositories (on the filesystem). Trailing slashed.
# * DEVELOP_CO and CORE_CO, paths to where working copies should be checked out. 
# Optional:
# * DEVELOP_URL and CORE_URL, ideally local URLs for URL-based repository operations.
#   By referencing a repository in local file:/// fashion, our operations can be faster.

DEVELOP_HTTP="http://develop.svn.wordpress.org"
CORE_HTTP="http://core.svn.wordpress.org"

# DEVELOP_URL and CORE_URL defaults to the public URLs:
DEVELOP_URL=${DEVELOP_URL-$DEVELOP_HTTP}
CORE_URL=${CORE_URL-$CORE_HTTP}

# Allow for a custom error handler.
type syncError > /dev/null 2>&1
if [ "$?" -gt 0 ]; then
	syncError() {
		echo $1 >&2
		exit 1
	}
fi

# This is designed to be run on cron. Lock the process!
# If we have the lock for too long, start raising flags.
LOCKFILE=$DEVELOP_REPO/sync-develop.lock
if [ -f $LOCKFILE ]; then
	if [ "$(wc -l $LOCKFILE | awk '{print $1}')" -gt 5 ]; then
		syncError "Something has gone wrong, we've been locked for more than 5 minutes."
	fi
	echo "Locked" >> $LOCKFILE
	echo "Locked"
	exit 0
fi
echo "Locked" > $LOCKFILE

# Initialize our checkouts. Use some depth tricks to avoid unnecessarily checking out tags.
if [ ! -d $DEVELOP_CO ]; then
	svn co --depth immediates $DEVELOP_URL $DEVELOP_CO
	svn up --ignore-externals --set-depth infinity $DEVELOP_CO/trunk $DEVELOP_CO/branches
fi
if [ ! -d $CORE_CO ]; then
	svn co --depth immediates $CORE_URL $CORE_CO
	svn up --ignore-externals --set-depth infinity $CORE_CO/trunk $CORE_CO/branches
fi

# Find the last synced revision.
# This file must be set up manually (so as to be nacin-proof).
LAST_SYNCED_FILE=$DEVELOP_REPO/.develop-rev-synced
if [ -f $LAST_SYNCED_FILE ]; then
	if [ ! -s $LAST_SYNCED_FILE ]; then
		syncError "The sync log, $LAST_SYNCED_FILE, is empty."
	fi
else
	syncError "The sync log, $LAST_SYNCED_FILE, does not exist."
fi

REV=$(cat $LAST_SYNCED_FILE)
LATEST_REV=$(svnlook youngest $DEVELOP_REPO)

syncRevision() {
	local REV=$1

	local TRUNK=$(svnlook dirs-changed -r $REV $DEVELOP_REPO | grep ^trunk/)
	if [ -z "$TRUNK" ]; then
		local BRANCH=$(svnlook dirs-changed -r $REV $DEVELOP_REPO | grep ^branches/. | head -n 1 | awk -F'/' '{print $1"/"$2}')
		if [ -z "$BRANCH" ]; then
			syncError "Commit $REV-develop has curious roots. I don't think it is trunk but I can't find a branch. Check it out please."
		fi
	else
		local BRANCH=trunk
	fi

	local MIXED_ROOTS=$(svnlook dirs-changed -r $REV $DEVELOP_REPO | grep -v "^$BRANCH/")
	if [ ! -z "$MIXED_ROOTS" ]; then
		syncError "Commit $REV-develop has curious roots. I think it is $BRANCH but I'm seeing mixed roots. Check it out please."
	fi

	svn up -r $REV --ignore-externals $DEVELOP_CO/$BRANCH
	svn up --ignore-externals $CORE_CO/$BRANCH

	if [ ! -d $DEVELOP_CO/$BRANCH ]; then
		syncError "$DEVELOP_CO/$BRANCH does not exist after svn up -r $REV"
	fi

	if [ ! -d $CORE_CO/$BRANCH ]; then
		syncError "$CORE_CO/$BRANCH does not exist after svn up"
	fi

	cd $DEVELOP_CO/$BRANCH

	# * leaves dotfiles, which is perfect because we want to keep the root .svn dir
	rm -r $CORE_CO/$BRANCH/*

	# Old and busted, or new hotness?
	if [ -f $DEVELOP_CO/$BRANCH/Gruntfile.js ]; then
		# Cool, execute our new build process.
		npm install
		grunt
		cp -r $DEVELOP_CO/$BRANCH/build/* $CORE_CO/$BRANCH
	else
		# Old build process is a simple root-to-root copy.
		cp -r $DEVELOP_CO/$BRANCH/* $CORE_CO/$BRANCH
	fi

	cd $CORE_CO/$BRANCH

	# Handle new and removed files
	# It could be nice in the future to parse svnlook --copy-info and do proper moves
	DELETES=$(svn stat --ignore-externals | grep '^!' | sed 's/! *//')
	ADDS=$(svn stat --ignore-externals | grep '^?' | sed 's/? *//')
	for DEL in $DELETES; do
		svn delete --force $DEL
	done
	for ADD in $ADDS; do
		svn add $ADD
	done

	AUTHOR=$(svnlook author -r $REV $DEVELOP_REPO)

	# Append to the synced commit message
	# "Built from http://develop.svn.wordpress.org/trunk@12345"
	MSG=$(mktemp)
	COMMIT_RESULT=$(mktemp)
	svnlook log -r $REV "$DEVELOP_REPO" > $MSG
	echo "Built from $DEVELOP_HTTP/$BRANCH@$REV" >> $MSG

	# Time to roll.
	svn commit --non-interactive --no-auth-cache --username $SVNUSER --password $SVNPASS -F "$MSG" $CORE_CO/$BRANCH > $COMMIT_RESULT

	# Actual failures produce an exit code > 0.
	COMMIT_ERR="$?"
	if [ "$COMMIT_ERR" -ne 0 ]; then
		syncError "$REV-develop failed to sync. SVN exited with a code of $COMMIT_ERR."
	fi

	# If there is nothing to commit, nothing is returned (but, note, exit code is 0).
	if [ -s $COMMIT_RESULT ]; then
		# Update our mixed-revision working copy before figuring out the new revision
		svn up --ignore-externals $CORE_CO/$BRANCH
		CORE_REV=$(svn info | grep ^Revision: | awk '{print $2}')
		# Update the last revision with the proper svn:author
		svn propset svn:author --non-interactive --no-auth-cache --username $SVNUSER --password $SVNPASS --revprop -r $CORE_REV "$AUTHOR" $CORE_CO
	fi
	rm $MSG $COMMIT_RESULT
}

# Loop through each new revision in develop.svn, syncing them one by one.

while [ "$REV" -lt "$LATEST_REV" ]; do
	REV=$(($REV+1))
	echo "Syncing $REV-develop..."
	syncRevision $REV
	echo $REV > $LAST_SYNCED_FILE
done
echo "Synced to $REV-develop."

rm $LOCKFILE
