//
//  AIExtendedStatusPlugin.m
//  Adium
//
//  Created by Adam Iser on 9/7/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIExtendedStatusPlugin.h"

#define STATUS_MAX_LENGTH	100

@implementation AIExtendedStatusPlugin

- (void)installPlugin
{
    [[adium contactController] registerListObjectObserver:self];
}

//Called when a handle's status changes
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray		*modifiedAttributes = nil;

	//Idle time
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Idle"] || [inModifiedKeys containsObject:@"StatusMessage"]){
		NSMutableString	*statusMessage = [[[inObject statusObjectForKey:@"StatusMessage"] string] mutableCopy];
		int				idle = [inObject integerStatusObjectForKey:@"Idle"];
		
		//Incredibly long status messages are slow to size, so we crop them to a reasonable length
		if([statusMessage length] > STATUS_MAX_LENGTH){
			[statusMessage deleteCharactersInRange:NSMakeRange(STATUS_MAX_LENGTH,
															   [statusMessage length] - STATUS_MAX_LENGTH)];
		}
		
		//Linebreaks in the status message cause vertical alignment issues.  We can either cut off at the first break
		//or prune them all.
		[statusMessage replaceOccurrencesOfString:@"\r"
									   withString:@" / "
										  options:0
											range:NSMakeRange(0,[statusMessage length])];
		[statusMessage replaceOccurrencesOfString:@"\n"
									   withString:@" / "
										  options:0
											range:NSMakeRange(0,[statusMessage length])];

		//
		NSString	*finalMessage;
		if(idle > 0 && statusMessage){
			finalMessage = [NSString stringWithFormat:@"(%@) %@",[self idleStringForSeconds:idle], statusMessage];
		}else if(idle > 0){
			finalMessage = [NSString stringWithFormat:@"(%@)",[self idleStringForSeconds:idle]];
		}else{
			finalMessage = statusMessage;
		}

		[[inObject displayArrayForKey:@"ExtendedStatus"] setObject:finalMessage withOwner:self];
		modifiedAttributes = [NSArray arrayWithObject:@"ExtendedStatus"];

		[statusMessage release];
	}
	
   return(modifiedAttributes);
}


//
- (NSString *)idleStringForSeconds:(int)seconds
{
	NSString	*idleString;
	
	//Create the idle string
	if(seconds > 599400){//Cap idle at 999 Hours (999*60*60 seconds)
		idleString = @"Idle";
	}else if(seconds >= 600){
		idleString = [NSString stringWithFormat:@"%i",seconds / 60];
	}else if(seconds >= 60){
		idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
	}else{
		idleString = [NSString stringWithFormat:@"%i",seconds];
	}
	
	return(idleString);
}

@end
