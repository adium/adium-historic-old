//
//  AIAppleScriptAdditions.m
//  Adium XCode
//
//  Created by Adam Iser on Mon Feb 16 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIAppleScriptAdditions.h"

@implementation NSAppleScript (AIAppleScriptAdditions)

//Execute an applescript function
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo
{
	NSAppleEventDescriptor	*thisApplication;
	NSAppleEventDescriptor	*containerEvent;
	
	//Get a descriptor for ourself
	int pid = [[NSProcessInfo processInfo] processIdentifier];
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
	
	//Pass arguments
//	arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
//	[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
	
	//Execute the event
	return([self executeAppleEvent:containerEvent error:nil]);
}

@end
