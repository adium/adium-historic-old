#!/bin/sh
# filename: buildDaily.sh

             ###################################################
             # Adium clean, update, package, and upload script #
             ###################################################

	# Credits:
	
	     # Jeremy Knickerbocker: original script

	     # Evan Schoenberg: modifications, general adium-ness
	
	     # Asher Haig: re-organizated as dynamic script with
	     #		   multiple options in crontabbed environments
	     #		   Added options to replace current Adium binary
	     #		   and execute new application. 

#-----------------------------------------------------------------------------#		

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # WARNING:							     	    #	
    # If this screws your system up it's because you've changed something   #
    # that you didn't understand. Didn't your mother ever tell you not 	    #
    # to play around with other people's shell scripts? They're fragile     #
    # and they break off easily.					    #
    #								            #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    #								     	    #
    # If you really think you need to change something and you can't make   #
    # it work, it's probably a problem with your paths or your		    #
    # permissions.							    #
    #									    #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Username should be set by CVSROOT
# Sourceforge login requires you to set up ssh keys so you can login without 
# a password - this is necessary for crontab.

	#--------#  In a file (I use ~/.crontab):
	# Usage: #  MM HH * * * /full/path/to/script >& /path/to/log.file	
	#--------#  crontab ~/.crontab 
	
		 #  MM and HH should be two digits, 24hr time.

	   	 #  Example:  /Users/ahaig/AdiumNightly/buildDaily.sh >& \
		 #	      /Users/ahaig/AdiumNightly/log/AdiumNightly.log
		 
		 #  That's all on ONE line or two with the \ separating them..

# CVS Root - Needs to be set somewhere. If you're running the script from a
# shell prompt, you can set it as an environment variable. Running from cron
# you should set it here as well.
# 
# Format: CVSROOT=":ext:<user>@cvs.adium.sourceforge.net:/cvsroot/adium"
# - replace <user> with anonymous or your dev login.
# If you use a dev login you _must_ have ssh keys set to use cron.
#
# export CVSROOT=":ext:anonymous@cvs.adium.sourceforge.net:/cvsroot/adium"

# Anonymous? Set No if you have your own login
# This overrides setting a user
anonymous="no"

# Login user not the same as your local user?
diffuser=""

if [ "$anonymous" == "no" ] ; then
	username=`whoami`
elif [ "$anonymous" == "yes" ] ; then
	username="anonymous"
elif !([ -z "$diffuser" ]) ; then
       	username=$diffuser
fi

if [ -z "$CVSROOT" ] ; then
	export CVSROOT=":ext:$username@cvs.adium.sourceforge.net:/cvsroot/adium"
fi

# If you want to use the script to build without updating via CVS, set this to
# "no".
should_update="yes"

# If you want your build to be faster but potentially contain outdated plugins and the like,
# set this to "no".
clean_build="yes"

# Don't do this unless you are a developer and want to automatically upload the .dmg to adium.sourceforge.net
copy_to_sourceforge="yes"

# Where all the nightly build files are kept
# adium/ is created by CVS checkout beneath this dir
adium_build_dir="$HOME/AdiumNightly"

# Where Adium gets built - all the source
adium_co_dir="$adium_build_dir/adium"

# Log info about the last build
lastbuild_log="$adium_build_dir/log/lastbuild.log"

# Where Adium.app comes out - it will _also_ exist in $adium_co_dir/build
build_output_dir="$adium_build_dir/build"

# Normal logging records the status of each step as it completes
# Verbose mode records all CVS activity
#log="normal"
log="verbose"

# Do we want to create a file with change-log information from CVS? (Handled automatically if packaging or uploading)
changelog="no"

# Replace Running Adium with new version
replace_running_adium="no"

# Determines where Adium.app is installed
# set as systemwide or user or none
install_type="systemwide"				# systemwide, user, none

# Set a default install dir - overrides systemwide/user choice
# This is empty by default
install_dir=""

# For optimized setings on a G4 set $OPTIMIZATION_CFLAGS to:
# -mcpu=7450 -O3 -pipe -fsigned-char -maltivec -mabi=altivec -mpowerpc-gfxopt -mtune=7450
# Currently -Os is optimized for size
if [ -z "$OPTIMIZATION_CFLAGS" ] ; then
	OPTIMIZATION_CFLAGS="-Os"
fi

# If you want a .dmg from it (Handled automatically if uploading)
package="no"

# If for some reason you feel compelled to change the name of Adium.app....
# All I have to say is that you better not still be using NS4....

adium_app_name="Adium"

# CVS will use rsh if you don't tell it otherwise. rsh won't use keys.
export CVS_RSH=/usr/bin/ssh

###############################################################################
#			      Stop Editing Here!! 			      #
#-----------------------------------------------------------------------------#
#	 If this were a standardized test, we would take your pencil away.     #
###############################################################################

# ensure the log directory exists
if !([ -x "$adium_build_dir/log" ]) ; then
	mkdir "$adium_build_dir/log"
fi

if !([ -z "$2" ]) ; then
	install_dir=$2
fi

if [ "$copy_to_sourceforge" == "yes" ] ; then
       package="yes"
fi

if [ "$package" == "yes" ] ;  then
	changelog="yes"
	replace_running_adium="no"
fi

if [ "$install_type" == "none" ] || [ "$package" == "yes" ] && \
					[ -z "$install_dir" ] ; then
	install_dir=$build_output_dir
fi
# If $install_dir isn't set 
if [ -z "$install_dir" ] ; then
	if [ "$install_type" == "systemwide" ] ; then
		if [ -x /Applications/Internet ]  ; then		
			install_dir="/Applications/Internet"
							# This seems reasonable. If it's not
							# I'm still going to act like it is.
		elif [ -x /Applications ] ; then		
							# I would hope it exists
			install_dir="/Applications"	# Don't you people subsort your Apps?
		fi
	elif [ "$install_type" == "user" ] ; then
		if [ -x $HOME/Applications ] ; then
			mkdir $HOME/Applications
			install_dir="$HOME/Applications"
		fi
	fi	
fi		
# Liboscar has to be updated each build with ranlib
liboscar="$adium_co_dir/Plugins/Gaim?Service/LIBS/liboscar.a"

# Get the date for version tracking
today=$(date +"%Y-%m-%d")
prettydate=$(date +"%m-%d-%Y")

echo `date`

# Check to see when the last build happened
if [ -f $lastbuild_log ] ; then
	lastbuild=`grep "....-..-.." $lastbuild_log`
else
	lastbuild=$today
fi



# Everything should happen in $adium_build_dir
cd $adium_build_dir

# If adium exists we'll update it. If not we'll get it from CVS
if [ "$should_update" == "yes" ] ; then
	if !([ -x $adium_co_dir ]) ; then
		echo "$adium_co_dir does not exist. Beginning new checkout."
		echo "Begin CVS Checkout in $adium_co_dir"
		if [ "$anonymous" == "yes" ] ; then 
			echo "Using Anonymous - Logging in"
			cvs -z3 login
		fi
		cvs -z3 co adium
	else							# Update from CVS
		echo "Begin CVS Update in $adium_co_dir"
	
		# Update happens from inside adium
		cd $adium_co_dir
	
		# Clean up files that have merge problems
		if [ -e "$adium_co_dir/Plugins/Gaim?Service/LIBS/liboscar.a" ] ; then
			rm "Plugins/Gaim?Service/LIBS/liboscar.a"
		fi
	
		if [ "$log" == "normal" ] ; then
			cvs update -Pd >& /dev/null		# Suppress output
		elif [ "$log" == "verbose" ] ; then
			cvs update -Pd
		fi
	
		echo "CVS Update Complete"
	fi
fi
	

# Time to start
cd $adium_co_dir				# Really just ./adium

# ranlib the static library
ranlib $liboscar

# Delete the (empty) Adium.pbproj
# We only want one .pbproj file so we don't have to tell
# xcodebuild which project file to use
if [ -e $adium_co_dir/Adium.pbproj ]; then
	echo "Deleting old (empty) Adium.pbproj"
	rm -r $adium_co_dir/Adium.pbproj
fi

if [ -e $adium_co_dir/Adium\ XCode.pbproj ]; then
	echo "Deleting Adium XCode.pbproj in favor of Adium.xcode"
	rm -r $adium_co_dir/Adium\ XCode.pbproj
fi

if [ -e $adium_co_dir/Plugins ]; then

if [ "$clean_build" == "yes" ] ; then
	rm -r $adium_co_dir/build
fi

# Produce Changelog
# Probably don't care about this unless we're building a .dmg for distribution
if [ "$changelog" == "yes" ] ; then
	echo "Creating ChangeLog_$prettydate relative to $lastbuild..."
	if [ -e $adium_co_dir/ChangeLog ]; then
		rm $adium_co_dir/ChangeLog
	fi

	if [ "$log" == "normal" ] ; then	# Don't Log
		$adium_co_dir/Utilities/Build/cvs2cl.pl --no-times --day-of-week --prune --hide-filenames --file $adium_co_dir/CompleteChanges --ignore theList.txt >& /dev/null
		$adium_co_dir/Utilities/Build/cvs2cl.pl --no-times --day-of-week -l "-d'>=$lastbuild'" --prune --hide-filenames --file $adium_co_dir/ChangeLog_$prettydate --ignore theList.txt >& /dev/null
		ln -s $adium_co_dir/ChangeLog_$prettydate $adium_co_dir/ChangeLog >& /dev/null
	elif [ "$log" == "verbose" ] ; then
		$adium_co_dir/Utilities/Build/cvs2cl.pl --no-times --day-of-week --prune --hide-filenames --file $adium_co_dir/CompleteChanges --ignore theList.txt
		$adium_co_dir/Utilities/Build/cvs2cl.pl --no-times --day-of-week -l "-d'>=$lastbuild'" --prune --hide-filenames --file $adium_co_dir/ChangeLog_$prettydate --ignore theList.txt
		ln -s $adium_co_dir/ChangeLog_$prettydate $adium_co_dir/ChangeLog
	fi
	if !([ -e $adium_co_dir/ChangeLog_$prettydate ]); then
		echo "No changes from $lastbuild to $prettydate" >> $adium_co_dir/ChangeLog_$prettydate
	fi
fi

# build Adium - OPTIMIZATION_CFLAGS is in the env
xcodebuild -target Adium -buildstyle Deployment

# Check for build output dir
if !([ -e $build_output_dir ]); then
    mkdir -p $build_output_dir
fi

echo Copying files...

# Package it
if [ "$package" == "yes" ] ; then			# We're building a .dmg
	if [ -x "$build_output_dir/Adium_$prettydate.dmg" ] ; then
		rm "$build_output_dir/Adium_$prettydate.dmg"	
	fi
	$adium_co_dir/Utilities/Build/buildDMG.pl \
	-buildDir . -compressionLevel 9 -dmgName "Adium_$prettydate" \
	-volName "Adium_$prettydate" "$adium_co_dir/build/Adium.app" \
	"$adium_co_dir/ChangeLog_$prettydate"
	
	cp Adium_$prettydate.dmg $build_output_dir/Adium_$prettydate.dmg
fi
if [ "$replace_running_adium" == "yes" ] && [ -x "$adium_co_dir/build/Adium.app" ]; then	 	
		osascript -e "tell application \"$adium_app_name\" to quit"
		rm -r "$install_dir/$adium_app_name.old.app"
		mv "$install_dir/$adium_app_name.app" "$install_dir/$adium_app_name.old.app"
		mv "$adium_co_dir/build/Adium.app" "$install_dir/$adium_app_name.app"
		open "$install_dir/$adium_app_name.app"
else
		cp -r "$adium_co_dir/build/Adium.app" "$install_dir/$adium_app_name.app"
fi

if [ "$copy_to_sourceforge" == "yes" ] ; then
       #Copy the files, setting them to be group writeable after copying
       scp Adium_$prettydate.dmg $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
       ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/Adium_$prettydate.dmg
 
       scp CompleteChanges $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/
       ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/CompleteChanges
     
       scp ChangeLog_$prettydate $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/downloads/ChangeLogs
       ssh shell.sf.net chmod 664 /home/groups/a/ad/adium/htdocs/downloads/ChangeLogs/ChangeLog_$prettydate
 
       ssh shell.sf.net ln -fs \
       /home/groups/a/ad/adium/htdocs/downloads/Adium_$prettydate.dmg \
       /home/groups/a/ad/adium/htdocs/downloads/Adium2.dmg

 	$adium_co_dir/Utilities/listToHTML.py $adium_co_dir/theList.txt theList.html
	scp theList.html $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/theList.html

	scp $adium_co_dir/build/version.plist  $username@shell.sf.net:/home/groups/a/ad/adium/htdocs/version.plist
fi

# Get rid of old lastbuild log
rm $lastbuild_log

# Write to new log
echo `date +"%Y-%m-%d"` >> $lastbuild_log

# And we're done
echo "Finished..."

else
	echo "Skipped everything because Plugins was not found..."
fi

echo "Exiting..."
echo
exit 0
