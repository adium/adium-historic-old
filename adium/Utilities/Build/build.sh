#!/bin/bash
#Created by Jeremy Knickerbocker
#If this screws your system up, don't blame me :-)
#Adium clean, update, package, and upload script
today=$(date +"%Y-%m-%d")
prettydate=$(date +"%m-%d-%Y")
if [ -f .lastadiumbuild ]; then
	lastbuild=`grep "....-..-.." .lastadiumbuild`
else
	lastbuild = today
fi
rm -Rf adium
cvs -z3 co adium
cd adium
#Delete the Xcode Project
rm -r "Adium XCode.pbproj"
#Log everything
../cvs2cl.pl --no-times --day-of-week --chrono --prune --hide-filenames --file CompleteChanges
../cvs2cl.pl --no-times --day-of-week -l "-d'>=$lastbuild'" --chrono --prune --hide-filenames
cp ChangeLog ChangeLog_$prettydate
#build it
pbxbuild -target Adium -buildstyle Deployment
#Package it
../buildDMG.pl -buildDir . -compressionLevel 9 -dmgName "Adium_$prettydate" -volName "Adium_$prettydate" ~/adium/build/Adium.app ~/adium/ChangeLog
cp Adium_$prettydate.dmg ~/AdiumBuilds
#Copy the files
scp Adium_$prettydate.dmg cronnix@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
scp CompleteChanges cronnix@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
scp ChangeLog_$prettydate cronnix@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/ChangeLogs
#cleanup
rm CompleteChanges ChangeLog ChangeLog_$prettydate
rm Adium_$prettydate.dmg
cd ..
rm .lastadiumbuild
echo `date +"%Y-%m-%d"` >> .lastadiumbuild
exit 0