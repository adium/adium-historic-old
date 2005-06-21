/*
 ApplescriptRunner.m
 Created by Evan Schoenberg on 10/31/2004
*/

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*
 ApplescriptRunner takes one or more arguments.
 The first argument should be the full path to an Applescript script file.
 The second argument may be the name of a function.
 Any additional arguments are passed to the called function in that file.
 No error checking is performed.
 */

int main (int argc, const char * argv[]) {
    NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	NSProcessInfo			*processInfo = [NSProcessInfo processInfo];
	NSArray					*processArguments = [processInfo arguments]; //Arguments pass to the program
	NSArray					*argumentArray = nil; //Arguments to be passed to the applescript
	NSAppleScript			*appleScript;
	NSAppleEventDescriptor	*thisApplication;
	NSAppleEventDescriptor	*containerEvent;
	NSString				*resultString;
	NSString				*functionName = nil;
	NSURL					*pathURL;
	unsigned				processArgumentsCount = [processArguments count];

	//The first argument is always the path to this program.  The second should be a path to the script
	pathURL = [NSURL fileURLWithPath:[processArguments objectAtIndex:1]];

	//Any additonal arguments should be the function to be called and arguments for it 
	if (processArgumentsCount > 2) {
		functionName = [processArguments objectAtIndex:2];

		if (processArgumentsCount > 3) {
			argumentArray = [processArguments subarrayWithRange:NSMakeRange(3, processArgumentsCount-3)];
		}
	}

	appleScript = [[NSAppleScript alloc] initWithContentsOfURL:pathURL
														 error:nil];

	if (appleScript) {
		if (functionName) {
			/* If we have a functionName (and potentially arguments), we build an NSAppleEvent to execute the script */

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
			if ([argumentArray count]) {
				NSAppleEventDescriptor  *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
				NSEnumerator			*enumerator = [argumentArray objectEnumerator];
				NSString				*object;

				while ((object = [enumerator nextObject])) {
					[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:object]
										atIndex:[arguments numberOfItems]+1]; //This +1 seems wrong... but it's not
				}

				[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
			}

			//Execute the event
			resultString = [[appleScript executeAppleEvent:containerEvent error:nil] stringValue];

		} else {
			resultString = [[appleScript executeAndReturnError:nil] stringValue];
		}
	}

	//Print the resulting string to standard output
	if (resultString) {
		printf("%s", [resultString UTF8String]);
	}

	[appleScript release];
	[pool release];

	return (resultString ? 0 : -1);
}
