//
//  AIExtendedStatusPlugin.m
//  Adium
//
//  Created by Adam Iser on 9/7/04.
//

#import "AIExtendedStatusPlugin.h"

#define STATUS_MAX_LENGTH	100

@interface AIExtendedStatusPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIExtendedStatusPlugin

- (void)installPlugin
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];
	
	whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict 
{
	EXTENDED_STATUS_STYLE statusStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue];
	showStatus = ((statusStyle == STATUS_ONLY) || (statusStyle == IDLE_AND_STATUS));
	showIdle = ((statusStyle == IDLE_ONLY) || (statusStyle == IDLE_AND_STATUS));
	
	if(!group){
		[[adium contactController] registerListObjectObserver:self];
	}else{
		[[adium contactController] updateAllListObjectsForObserver:self];
	}
}

//Called when a handle's status changes
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;

	//Idle time
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Idle"] || [inModifiedKeys containsObject:@"StatusMessage"]){
		NSMutableString	*statusMessage = nil;
		NSString		*finalMessage = nil;
		int				idle;
		
		if (showStatus){
			statusMessage = [[[[[inObject statusObjectForKey:@"StatusMessage"] string] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] mutableCopy] autorelease];
				
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
		}
		
		idle = (showIdle ? [inObject integerStatusObjectForKey:@"Idle"] : 0);
		
		//
		if(idle > 0 && statusMessage){
			finalMessage = [NSString stringWithFormat:@"(%@) %@",[self idleStringForSeconds:idle], statusMessage];
		}else if(idle > 0){
			finalMessage = [NSString stringWithFormat:@"(%@)",[self idleStringForSeconds:idle]];
		}else{
			finalMessage = statusMessage;
		}

		[[inObject displayArrayForKey:@"ExtendedStatus"] setObject:finalMessage withOwner:self];
		modifiedAttributes = [NSSet setWithObject:@"ExtendedStatus"];
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
		idleString = [NSString stringWithFormat:@"%ih",seconds / 60];
	}else if(seconds >= 60){
		idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
	}else{
		idleString = [NSString stringWithFormat:@"%i",seconds];
	}
	
	return(idleString);
}

@end
