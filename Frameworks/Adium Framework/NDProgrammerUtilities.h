/*
 *  NDProgrammerUtilities.h
 *  NDAppleScriptObjectProjectAlpha
 *
 *  Created by Nathan Day on Sat May 01 2004.
 *  Copyright (c) 2004 Nathan Day. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include <Cocoa/Cocoa.h>

#ifdef NDTurnLoggingOff
#define NDLogFalse( CONDITION_ ) ((CONDITION_) != NO)
#else
#define NDLogFalse( CONDITION_ ) NDLogFalseBody( ( CONDITION_ ) != NO, __TIME__, __FILE__, __func__, __LINE__, # CONDITION_ )
#endif
inline BOOL NDLogFalseBody( const BOOL cond, const char * logTime, const char * fileName, const char * funcName, const unsigned int line, const char * codeLine );
/*!
	@defined NDLogOSStatus
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param OS_ERROR_ An expression that returns a <tt>OSStatus</tt>, evaluated only once.
	@result if <tt><i>OS_ERROR_</i></tt> evaluates to <tt>noErr</tt> then <tt>NDLogOSStatus</tt> returns <tt>YES</tt> otherwise it return <tt>NO</tt>.
 */
#ifdef NDTurnLoggingOff
#define NDLogOSStatus( OS_ERROR_ ) ((OS_ERROR_) == noErr)
#else
#define NDLogOSStatus( OS_ERROR_ ) NDLogOSStatusBody( (OS_ERROR_), __TIME__, __FILE__, __func__, __LINE__, # OS_ERROR_ )
#endif
inline BOOL NDLogOSStatusBody( const OSStatus osError, const char * logTime, const char * fileName, const char * funcName, const unsigned int line, const char * codeLine );

#define NDUntestedMethod( ) NDUntestedMethodBody( __FILE__, __func__, __LINE__ )
inline void NDUntestedMethodBody( const char * fileName, const char * funcName, const unsigned int line );

