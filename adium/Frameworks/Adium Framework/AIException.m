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
    NSDictionary    *dict = [self userInfo];
    NSString        *stackTrace = nil;
    NSMutableString *processedStackTrace = [[[NSMutableString alloc] init] autorelease];

    //Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
    if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) { 
        NSString *str = [NSString stringWithFormat:@"%s -p %d %@ | tail -n +3 | head -n +%d | c++filt | cat -n",[[[NSBundle mainBundle] pathForResource:@"atos" ofType:nil] fileSystemRepresentation],
            [[NSProcessInfo processInfo] processIdentifier],
            stackTrace,
            ([[stackTrace componentsSeparatedByString:@"  "] count] - 4)];
        FILE *file = popen( [str UTF8String], "r" );
        
        if( file )
        {
            char buffer[512];
            size_t length;

            while( length = fread( buffer, 1, sizeof( buffer ), file ) )
            {
                [processedStackTrace appendString:[NSString stringWithCString:buffer]];
            }
            
            pclose( file );
        }
        
        [[NSString stringWithFormat:@"Exception:\t%@\nReason:\t%@\nStack trace:\n%@",[self name],[self reason],processedStackTrace] writeToFile:EXCEPTIONS_PATH atomically:YES];
        NSLog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@)",[self name],[self reason]);
        [[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_CRASH_REPORTER];
        //Move along, citizen, nothing more to see here.
        exit(-1);
    } else {
        [super raise];
    }
}

@end