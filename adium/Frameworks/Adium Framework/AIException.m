//
//  AIException.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//

#import "AIException.h"
#import <ExceptionHandling/NSExceptionHandler.h>

@implementation AIException
/* load
*   install ourself to handle exceptions
 */
+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSException class]];
}

/* raise
*   raise an exception
 */
- (void)raise
{
    NSLog(@"little angel raised up!");
    NSDictionary    *dict = [self userInfo];
    NSString        *stackTrace = nil;
    NSMutableString *processedStackTrace = [[[NSMutableString alloc] init] autorelease];

    //This call is an NSException addition provided by the ExceptionHandling framework according to class-dump.  It doesn't seem to actually be added?
   // [super _addExceptionHandlerStackTrace];
    
    //This seemed like a clever idea but causes an infinite loop - presumeably the defaultExceptionHandler has to grab the exception when it happens, not afterwards, to generate the stackTrace.
  /*  if (!dict) {
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
        [self raise];
    } else {
         [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:0];   
    }
*/
    
    //Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
    if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) { 
        NSString *str = [NSString stringWithFormat:@"/usr/bin/atos -p %d %@ | tail -n +3 | head -n +%d | c++filt | cat -n",
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
    } 
    
    //Log it - this will be replaced by ramoth4's 
    NSLog(@"***An exception of type %@ occurred:\n%@\nTrace:%@",[self name],[self reason],processedStackTrace);
   
    //Pass it along, citizen, nothing to see here.
    [super raise];
}

@end