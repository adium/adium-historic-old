//
//  ApplescriptDebugging.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//

#import <Foundation/Foundation.h>

#ifndef APPLESCRIPT_DEBUGGING_ENABLED
#define APPLESCRIPT_DEBUGGING_ENABLED FALSE
#endif

#if APPLESCRIPT_DEBUGGING_ENABLED

@interface NSScriptClassDescription (NSScriptClassDescriptionAIPrivate)
- (short)_readClass:(void *)someSortOfInput;
@end

@interface AIScriptClassDescription : NSScriptClassDescription {

}

@end

@interface AIScriptCommand : NSScriptCommand {
	
}

@end

@interface AIScriptCommandDescription : NSScriptCommandDescription {

}

@end

#endif