#!/bin/bash
#Created by Jeremy Knickerbocker, modified by Evan Schoenberg
#If this screws your system up, don't blame me :-)
#Adium clean, update, package, and upload script

#Sourceforge username - your login name by default; change if necessary
#Sourceforge login requires you to set up ssh keys so you can login without a password
username=`whoami`

today=$(date +"%Y-%m-%d")
prettydate=$(date +"%m-%d-%Y")
if [ -f .lastadiumbuild ]; then
	lastbuild=`grep "....-..-.." .lastadiumbuild`
else
	lastbuild=$today
fi

cd ~/adium

#This gaim stuff has more conflicts and angst than the WB
rm -f "Plugins/Gaim Service/LIBS/liboscar.a"
rm -f "Plugins/Gaim Service/CBGaimAIMAccount.m"

cvs update -Pd

#ranlib the static library
ranlib "Plugins/Gaim Service/LIBS/liboscar.a"

#Delete the prefix header from before, just in case
rm -r "build/PrefixHeaders"

#Log everything
Utilities/Build/cvs2cl.pl --no-times --day-of-week --prune --hide-filenames --file CompleteChanges
Utilities/Build//cvs2cl.pl --no-times --day-of-week -l "-d'>=$lastbuild'" --prune --hide-filenames --file ChangeLog
cp ChangeLog ChangeLog_$prettydate
#build it
xcodebuild -target Adium GENERATE_DEBUGGING_SYMBOLS=NO COPY_PHASE_STRIP=YES DEBUGGING_SYMBOLS=NO MACOSX_DEPLOYMENT_TARGET=10.2 ZERO_LINK=NO OPTIMIZATION_CFLAGS=-Os FIX_AND_CONTINUE=NO OTHER_CFLAGS=-DDEPLOYMENT_BUILD
#Package it
Utilities/Build/buildDMG.pl -buildDir . -compressionLevel 9 -dmgName "Adium_$prettydate" -volName "Adium_$prettydate" build/Adium.app ChangeLog

mkdir ~/AdiumBuilds

cp Adium_$prettydate.dmg ~/AdiumBuilds/Adium_$prettydate.dmg

#Copy the files, setting them to be group writeable after copying
scp Adium_$prettydate.dmg $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/Adium_$prettydate.dmg

scp CompleteChanges $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/CompleteChanges

scp ChangeLog_$prettydate $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/ChangeLogs
ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/ChangeLogs/ChangeLog_$prettydate

ssh shell.sf.net ln -fs \
    /home/groups/a/ad/adium/htdocs/downloads/Adium_$prettydate \
    /home/groups/a/ad/adium/htdocs/downloads/Adium2.dmg

#cleanup
rm CompleteChanges ChangeLog ChangeLog_$prettydate
rm Adium_$prettydate.dmg
cd ..
rm .lastadiumbuild
echo `date +"%Y-%m-%d"` >> .lastadiumbuild
exit 0
