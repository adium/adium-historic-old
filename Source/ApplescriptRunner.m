/*
 ApplescriptRunner.m
 Created by Evan Schoenberg on 10/31/2004
*/

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*
 @brief Shell tool to run an applescript, optionally with a function name and arguments
 *
 * ApplescriptRunner takes one or more arguments.
 * The first argument should be the full path to an Applescript script file.
 * The second argument may be the name of a function.
 * Any additional arguments are passed to the called function in that file.
 *
 * Minimal error checking is performed.
 */
int main (int argc, const char *argv[])
{
    NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	NSProcessInfo			*processInfo;
	NSAppleScript			*appleScript;
	NSAppleEventDescriptor	*thisApplication, *containerEvent;
	NSString				*functionName = nil, *resultString = nil;
	NSArray					*processArguments, *scriptArgumentArray = nil;
	NSURL					*pathURL;
	unsigned				processArgumentsCount;

	processInfo = [NSProcessInfo processInfo];
	processArguments = [processInfo arguments];
	processArgumentsCount = [processArguments count];
	 
	//The first argument is always the path to this program.  The second should be a path to the script
	pathURL = [NSURL fileURLWithPath:[processArguments objectAtIndex:1]];

	//Any additonal arguments should be the function to be called and arguments for it 
	if (processArgumentsCount > 2) {
		functionName = [processArguments objectAtIndex:2];

		if (processArgumentsCount > 3) {
			scriptArgumentArray = [processArguments subarrayWithRange:NSMakeRange(3, processArgumentsCount-3)];
		}
	}

	appleScript = [[NSAppleScript alloc] initWithContentsOfURL:pathURL
														 error:NULL];

	if (appleScript) {
		if (functionName) {
			/* If we have a functionName (and potentially arguments), we build
			 * an NSAppleEvent to execute the script. */

			//Get a descriptor for ourself
			int pid = [processInfo processIdentifier];
			thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
																			 bytes:&pid
																			length:sizeof(pid)];

			//Create the container event
			containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
																	  eventID:kASSubroutineEvent
															 targetDescriptor:thisApplication
																	 returnID:kAutoGenerateReturnID
																transactionID:kAnyTransactionID];

			//Set the target function
			[containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:functionName]
									forKeyword:keyASSubroutineName];

			//Pass arguments - arguments is expecting an NSArray with only NSString objects
			if ([scriptArgumentArray count]) {
				NSAppleEventDescriptor  *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
				NSEnumerator			*enumerator = [scriptArgumentArray objectEnumerator];
				NSString				*object;

				while ((object = [enumerator nextObject])) {
					[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:object]
										atIndex:([arguments numberOfItems] + 1)]; //This +1 seems wrong... but it's not
				}

				[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
				[arguments release];
			}

			//Execute the event
			resultString = [[appleScript executeAppleEvent:containerEvent error:NULL] stringValue];

		} else {
			resultString = [[appleScript executeAndReturnError:NULL] stringValue];
		}
	}

	//Print the resulting string to standard output
	if (resultString) {
		printf("%s", [resultString UTF8String]);
	}

	[appleScript release];
	[pool release];

	return !resultString;
}
