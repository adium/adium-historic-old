/* 
Adium, Copyright 2001-2004, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/*
 Catches application exceptions and forwards them to the crash reporter application
 */

#import <ExceptionHandling/NSExceptionHandler.h>
#import "AIExceptionController.h"
#import "AICrashReporter.h"

@implementation AIExceptionController

//Enable exception catching for the crash reporter
static BOOL catchExceptions = NO;
+ (void)enableExceptionCatching
{
    //Remove any existing exception logs
    [[NSFileManager defaultManager] trashFileAtPath:EXCEPTIONS_PATH];

    //Log and Handle all exceptions
    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
	catchExceptions = YES;
}

//This class works by posing as NSException, which we want to do as soon as possible
+ (void)load
{
    [self poseAsClass: [NSException class]];
}

//Raise an exception.  This gets called once with no stack trace, then a second time after the stack trace is
//added by the ExceptionHandling framework.  We therefore just do [super raise] if there is no stack trace, awaiting
//its addition to write the exception log, load the crash reporter, and exit.
- (void)raise
{
	if(!catchExceptions){
		[super raise];
	}else{
		NSString	*theReason = [self reason];
		NSString	*theName = [self name];
		
		//Ignore various known harmless or unavoidable exceptions (From the system or system hacks)
		if((!theReason) || //Harmless
		   [theReason isEqualToString:@"_sharedInstance is invalid."] || //Address book framework is weird sometimes
		   [theReason isEqualToString:@"No text was found"] || //ICeCoffEE is an APE haxie which would crash us whenever a user pasted, or something like that
		   [theReason isEqualToString:@"Error (1000) creating CGSWindow"] || //This looks like an odd NSImage error... it occurs sporadically, seems harmless, and doesn't appear avoidable
		   [theReason isEqualToString:@"Access invalid attribute location 0 (length 0)"] || //The undo manager can throw this one when restoring a large amount of attributed text... doesn't appear avoidable
		   [theReason rangeOfString:@"-patternImage not defined"].location != NSNotFound || //Painters Color Picker throws an exception during the normal course of operation.  Don't you hate that?
		   [theReason isEqualToString:@"Invalid parameter not satisfying: (index >= 0) && (index < (_itemArray ? CFArrayGetCount(_itemArray) : 0))"] || //A couple AppKit methods, particularly NSSpellChecker, seem to expect this exception to be happily thrown in the normal course of operation. Lovely. Also needed for FontSight compatibility.
		   [theReason isEqualToString:@"Invalid parameter not satisfying: (index >= 0) && (index <= (_itemArray ? CFArrayGetCount(_itemArray) : 0))"] || //Like the above, but <= instead of <
		   [theReason isEqualToString:@"Invalid parameter not satisfying: entry"] || //NSOutlineView throws this, particularly if it gets clicked while reloading or the computer sleeps while reloading
		   [theReason isEqualToString:@"Invalid parameter not satisfying: aString != nil"] || //The Find command can through this, as can other AppKitt methods
		   [theReason rangeOfString:@"NSRunStorage, _NSBlockNumberForIndex()"].location != NSNotFound || //NSLayoutManager throws this for fun in a purely-AppKit stack trace
		   [theReason rangeOfString:@"Broken pipe"].location != NSNotFound || //libezv throws broken pipes as NSFileHandleOperationException with this in the reason; I'd rather we watched for "broken pipe" than ignore all file handle errors
		   [theReason rangeOfString:@"incomprehensible archive"].location != NSNotFound || //NSKeyedUnarchiver can get confused and throw this; it's out of our control
		   !theName || //Harmless
		   [theName isEqualToString:@"GIFReadingException"] || //GIF reader sucks
		   [theName isEqualToString:@"NSPortTimeoutException"] || //Harmless - it timed out for a reason
		   [theName isEqualToString:@"NSAccessibilityException"] || //Harmless - one day we should figure out how we aren't accessible, but not today
		   [theName isEqualToString:@"NSImageCacheException"] || //NSImage is silly
		   [theName isEqualToString:@"NSArchiverArchiveInconsistency"] || //Odd system hacks can lead to this one
		   [theName isEqualToString:@"NSObjectInaccessibleException"]){ //We don't use DO, but spell checking does; AppleScript execution requires multiple run loops, and the HIToolbox can get confused and try to spellcheck in the applescript thread. Silly Apple.
			
			[super raise];
			
		}else{
			NSString	*backtrace = [self decodedExceptionBacktrace];
			
			//Check the stack trace for a third set of known offenders
			if(!backtrace ||
			   [backtrace rangeOfString:@"-[NSFontPanel setPanelFont:isMultiple:] (in AppKit)"].location != NSNotFound){
				
				[super raise];
				
			}else{
				NSString	*bundlePath = [[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath];
				NSString	*crashReporterPath = [bundlePath stringByAppendingPathComponent:RELATIVE_PATH_TO_CRASH_REPORTER];
				
				NSLog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@", theName,theReason);
				AILog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@", theName,theReason);
				
				//Pass the exception to the crash reporter and close this application
				[[NSString stringWithFormat:@"Exception:\t%@\nReason:\t%@\nStack trace:\n%@",
					theName,theReason,backtrace] writeToFile:EXCEPTIONS_PATH atomically:YES];
				
				[[NSWorkspace sharedWorkspace] launchApplication:crashReporterPath];
				exit(-1);
			}
		}
	}
}

//Decode the backtrace and save it to disk.  Returns YES if a (harmful) exception is found and logged.
- (NSString *)decodedExceptionBacktrace
{
	NSDictionary    *dict = [self userInfo];
	NSString        *stackTrace = nil;
	
	//Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
	if(dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) {
		NSMutableString		*processedStackTrace = [[[NSMutableString alloc] init] autorelease];
		NSString			*str;
		
		//We use two command line apps to decode our exception
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
		
		return(processedStackTrace);
	}
	
	//If we are unable to decode the stack trace, return the best we have
	return(stackTrace);
}

@end

