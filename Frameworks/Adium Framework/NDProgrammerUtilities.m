/*
 *  NDProgrammerUtilities.m
 *  NDAppleScriptObjectProjectAlpha
 *
 *  Created by Nathan Day on Sat May 01 2004.
 *  Copyright (c) 2004 Nathan Day. All rights reserved.
 *
 */

#include "NDProgrammerUtilities.h"

BOOL NDLogFalseBody( const BOOL aCond, const char * aTime, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
	if( aCond == NO )
		fprintf( stderr, "[%s] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", aTime, aFuncName, aCodeLine, aFileName, aLine );
	return aCond;
}

BOOL NDLogOSStatusBody( const OSStatus anError, const char * aTime, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
	if( anError != noErr )
		fprintf( stderr, "Error result [%s] OSStatus %li:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", aTime, anError, aCodeLine, aFileName, aFuncName, aLine );
	return anError == noErr;
}

inline void NDUntestedMethodBody( const char * aFileName, const char * aFuncName, const unsigned int aLine )
{
	fprintf( stderr, "WARRING: The function %s has not been tested\n\tfile: %s\n\tline: %u.\n", aFileName, aFuncName, aLine );
}
