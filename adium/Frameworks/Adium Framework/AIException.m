//
//  AIException.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//

#import "AIException.h"
#import <ExceptionHandling/NSExceptionHandler.h>

#define EXCEPTIONS_PATH		[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]

@implementation AIException
/* load
*   install ourself to handle exceptions
 */
+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSException class]];
}

//Raise an exception.  This gets called once with no stack trace, then a second time after the stack trace is added by the ExceptionHandling framework.  We therefore just do [super raise] if there is no stack trace, awaiting its addition to write the exception log, load the crash reporter, and exit Adium
- (void)raise
{
    //Ignore various harmless or unavoidable exceptions the system uses
    if ((![self reason]) || //Harmless
		([[self reason] isEqualToString:@"_sharedInstance is invalid."]) || //Address book framework is weird sometimes
		([[self reason] isEqualToString:@"No text was found"]) || //ICeCoffEE is an APE haxie which would crash us whenever a user pasted, or something like that
		([[self reason] isEqualToString:@"Error (1000) creating CGSWindow"]) || //This looks like an odd NSImage error... it occurs sporadically, seems harmless, and doesn't appear avoidable
		([[self reason] isEqualToString:@"Access invalid attribute location 0 (length 0)"])) //The undo manager can throw this one when restoring a large amount of attributed text... doesn't appear avoidable
	{

	    [super raise];
		
    } else if ((![self name]) || //Harmless
		  ([[self name] isEqualToString:@"GIFReadingException"]) || //GIF reader sucks
		  ([[self name] isEqualToString:@"NSPortTimeoutException"]) || //Harmless - it timed out for a reason
		  ([[self name] isEqualToString:@"NSAccessibilityException"]) || //Harmless - one day we should figure out how we aren't accessible, but not today
		  ([[self name] isEqualToString:@"NSImageCacheException"]) /*|| //NSImage is silly
		  ([[self name] isEqualToString:@"NSInternalInconsistencyException"])*/) //Ignore NSAssert?
	{
	    [super raise];
	
    } else {
        NSDictionary    *dict = [self userInfo];
        NSString        *stackTrace = nil;
        NSMutableString *processedStackTrace = [[[NSMutableString alloc] init] autorelease];
		
        //Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
        if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) { 
            NSString *str = [NSString stringWithFormat:@"%s -p %d %@ | tail -n +3 | head -n +%d | %s | cat -n",
                [[[NSBundle mainBundle] pathForResource:@"atos" ofType:nil] fileSystemRepresentation],
                [[NSProcessInfo processInfo] processIdentifier],
                stackTrace,
                ([[stackTrace componentsSeparatedByString:@"  "] count] - 4),
                [[[NSBundle mainBundle] pathForResource:@"c++filt" ofType:nil] fileSystemRepresentation]];
            FILE *file = popen( [str UTF8String], "r" );
            
            if( file )
            {
                char buffer[512];
                size_t length;
                
                while( (length = fread(buffer, 1, sizeof(buffer), file) ))
                {
                    [processedStackTrace appendString:[NSString stringWithCString:buffer]];
                }
                
                pclose( file );
            }
            
            [[NSString stringWithFormat:@"Exception:\t%@\nReason:\t%@\nStack trace:\n%@",
                [self name],[self reason],processedStackTrace] writeToFile:EXCEPTIONS_PATH 
                                                                atomically:YES];
            
            NSLog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@)",
                  [self name],[self reason]);
            
            [[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_CRASH_REPORTER];
            //Move along, citizen, nothing more to see here.
            exit(-1);
        } else {
            [super raise];
        }
    }
}

@end