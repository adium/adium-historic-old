//
//  ESDebugAILog.h
//  Adium
//
//  Created by Evan Schoenberg on 1/29/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#ifdef DEBUG_BUILD
/* For a debug build, declare the AILog() function */
	void AILog (NSString *format, ...);
#else
/* For a non-debug build, define it to be a comment so there is no overhead in using it liberally */
	#define AILog(fmt, ...) /**/
#endif