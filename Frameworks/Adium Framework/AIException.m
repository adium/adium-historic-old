//
//  AIException.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//

#import "AIException.h"
#import <ExceptionHandling/NSExceptionHandler.h>
#import "AIAdium.h"

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
	NSString	*theReason;
	NSString	*theName;
	
	theReason = [self reason];
	theName = [self name];
	
    //Ignore various harmless or unavoidable exceptions the system uses
	
	//First, check our reason against known offenders, then check our name against known offenders
    if ((!theReason) || //Harmless
		([theReason isEqualToString:@"_sharedInstance is invalid."]) || //Address book framework is weird sometimes
		([theReason isEqualToString:@"No text was found"]) || //ICeCoffEE is an APE haxie which would crash us whenever a user pasted, or something like that
		([theReason isEqualToString:@"Error (1000) creating CGSWindow"]) || //This looks like an odd NSImage error... it occurs sporadically, seems harmless, and doesn't appear avoidable
		([theReason isEqualToString:@"Access invalid attribute location 0 (length 0)"]) || //The undo manager can throw this one when restoring a large amount of attributed text... doesn't appear avoidable
		([theReason rangeOfString:@"-patternImage not defined"].location != NSNotFound) || //Painters Color Picker throws an exception during the normal course of operation.  Don't you hate that?
		([theReason isEqualToString:@"Invalid parameter not satisfying: (index >= 0) && (index < (_itemArray ? CFArrayGetCount(_itemArray) : 0))"]) || //A couple AppKit methods, particularly NSSpellChecker, seem to expect this exception to be happily thrown in the normal course of operation. Lovely. Also needed for FontSight compatibility.
		([theReason isEqualToString:@"Invalid parameter not satisfying: entry"]) || //NSOutlineView throws this, particularly if it gets clicked while reloading or the computer sleeps while reloading
		([theReason rangeOfString:@"NSRunStorage, _NSBlockNumberForIndex()"].location != NSNotFound) || //NSLayoutManager throws this for fun in a purely-AppKit stack trace
		([theReason rangeOfString:@"Broken pipe"].location != NSNotFound) || //libezv throws broken pipes as NSFileHandleOperationException with this in the reason; I'd rather we watched for "broken pipe" than ignore all file handle errors
		([theReason rangeOfString:@"incomprehensible archive"].location != NSNotFound)) //NSKeyedUnarchiver can get confused and throw this; it's out of our control
	{

	    [super raise];
		
    }else if((!theName) || //Harmless
			 ([theName isEqualToString:@"GIFReadingException"]) || //GIF reader sucks
			 ([theName isEqualToString:@"NSPortTimeoutException"]) || //Harmless - it timed out for a reason
			 ([theName isEqualToString:@"NSAccessibilityException"]) || //Harmless - one day we should figure out how we aren't accessible, but not today
			 ([theName isEqualToString:@"NSImageCacheException"]) || //NSImage is silly
			 ([theName isEqualToString:@"NSArchiverArchiveInconsistency"]) || //Odd system hacks can lead to this one
			 ([theName isEqualToString:@"NSObjectInaccessibleException"]) //We don't use DO, but spell checking does; AppleScript execution requires multiple run loops, and the HIToolbox can get confused and try to spellcheck in the applescript thread. Silly Apple.
			/*|| ([theName isEqualToString:@"NSInternalInconsistencyException"])*/) //Ignore NSAssert?
	{
	    [super raise];
	
    }else{
        NSDictionary    *dict;
        NSString        *stackTrace;
		
		dict = [self userInfo];
		
        //Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
        if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) {
			NSMutableString		*processedStackTrace;
			NSString			*str;
			
			processedStackTrace  = [[[NSMutableString alloc] init] autorelease];
			
            str = [NSString stringWithFormat:@"%s -p %d %@ | tail -n +3 | head -n +%d | %s | cat -n",
                [[[NSBundle mainBundle] pathForResource:@"atos" ofType:nil] fileSystemRepresentation],
                [[NSProcessInfo processInfo] processIdentifier],
                stackTrace,
                ([[stackTrace componentsSeparatedByString:@"  "] count] - 4),
                [[[NSBundle mainBundle] pathForResource:@"c++filt" ofType:nil] fileSystemRepresentation]];
			
            FILE *file = popen( [str UTF8String], "r" );
            
            if(file){
                char	buffer[512];
                size_t	length;
                
                while(length = fread(buffer, 1, sizeof(buffer), file)){
                    [processedStackTrace appendString:[NSString stringWithCString:buffer]];
                }
                
                pclose(file);
            }
            
			//Check the stack trace for a third set of known offenders
			if ([processedStackTrace rangeOfString:@"-[NSFontPanel setPanelFont:isMultiple:] (in AppKit)"].location != NSNotFound){
				[super raise];

			}else{
				
				[[NSString stringWithFormat:@"Exception:\t%@\nReason:\t%@\nStack trace:\n%@",
					theName,theReason,processedStackTrace] writeToFile:EXCEPTIONS_PATH 
															atomically:YES];
				
				NSLog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@",
					  theName,theReason);
				AILog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@",
					  theName,theReason);
				
				[[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_CRASH_REPORTER];
				
				//Move along, citizen, nothing more to see here.
				exit(-1);
			}
			
        }else{
            [super raise];
        }
    }
}

@end