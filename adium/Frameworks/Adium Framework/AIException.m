//
//  AIException.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//

#import "AIException.h"
#import <ExceptionHandling/NSExceptionHandler.h>

#define EXCEPTIONS_PATH		[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]

@implementation AIException
/* initialize
*   install ourself to handle exceptions
 */
+ (void)initialize
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSException class]];
}

//Raise an exception.  This gets called once with no stack trace, then a second time after the stack trace is added by the ExceptionHandling framework.  We therefore just do [super raise] if there is no stack trace, awaiting its addition to write the exception log, load the crash reporter, and exit Adium
- (void)raise
{
    //Ignore various harmless or unavoidable exceptions the system uses
    if ((![self reason]) ||
		([[self reason] isEqualToString:@"_sharedInstance is invalid."])) {
    
	    [super raise];
		
    } else if ((![self name]) || 
		  ([[self name] isEqualToString:@"GIFReadingException"]) || 
		  ([[self name] isEqualToString:@"NSPortTimeoutException"]) ||
		  ([[self name] isEqualToString:@"NSAccessibilityException"]) /*||
		  ([[self name] isEqualToString:@"NSInternalInconsistencyException"])*/) {
	
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