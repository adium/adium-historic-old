#!/bin/sh

if test "x$1" != x; then
	SFUSER=$1
else
	SFUSER=$USER
fi

/usr/bin/ssh $SFUSER@shell1.sourceforge.net 'cd /home/groups/a/ad/adium/htdocs && cvs -z3 update -Pd'
