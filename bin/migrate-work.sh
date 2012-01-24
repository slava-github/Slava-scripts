#!/bin/bash
TO=$1

FLAG_FILE=/home/slava/.work-server

if [ -z $TO ]; then
	echo "Usage: $0 <server-full-name>"
	exit 1;
elif [ $TO == 'work-server' ];then
	cat $FLAG_FILE
	exit
fi

FROM=$(cat $FLAG_FILE)

echo "Migrate from $FROM to $TO"

pkill firefox
FPATH=/home/slava/.mozilla/firefox/slava.prof/
for fn in bookmarks.html;do
	BM_FILE=$FPATH$fn
	cp $BM_FILE $BM_FILE.sav
	sed -r "s/$FROM/$TO/g" <$BM_FILE.sav >$BM_FILE
done

wmount umount

echo $TO >$FLAG_FILE

wmount mount
