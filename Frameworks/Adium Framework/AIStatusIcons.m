//
//  AIStatusIcons.m
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIStatusIcons.h"

static NSMutableDictionary	*statusIcons[NUMBER_OF_STATUS_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*statusIconBasePath = nil;
static NSDictionary			*statusIconNames[NUMBER_OF_STATUS_ICON_TYPES];

@interface AIStatusIcons(PRIVATE)
+ (NSString *)_stateIDForChat:(AIChat *)chat;
+ (NSString *)_statusIDForListObject:(AIListObject *)listObject;
@end

@implementation AIStatusIcons

+ (void)initialize
{
	int i, j;
	
	[super initialize];
	
	//Allocate our status icon cache
	for(i = 0; i < NUMBER_OF_STATUS_ICON_TYPES; i++){
		for(j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++){
			statusIcons[i][j] = [[NSMutableDictionary alloc] init];
		}
	}
}

//Retrieve the correct status icon for a given list object
+ (NSImage *)statusIconForListObject:(AIListObject *)object type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusID:[AIStatusIcons _statusIDForListObject:object]
										   type:iconType
									  direction:iconDirection];
}

//Retrieve the correct status icon for a given chat
+ (NSImage *)statusIconForChat:(AIChat *)chat type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusID:[AIStatusIcons _stateIDForChat:chat]
										   type:iconType
									  direction:iconDirection];
}



//Retrieve the correct status icon for the internal status ID
//We will probably want to remove this method and have everyone pass us list objects instead
+ (NSImage *)statusIconForStatusID:(NSString *)statusID type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage				*statusIcon;
	
	//Retrieve the service icon from our cache
	statusIcon = [statusIcons[iconType][iconDirection] objectForKey:statusID];
	
	//Load the status icon if necessary
	if(!statusIcon){
		NSString	*path = [statusIconBasePath stringByAppendingPathComponent:[statusIconNames[iconType] objectForKey:statusID]];
		
		if(path){
			statusIcon = [[NSImage alloc] initWithContentsOfFile:path];
			
			if(statusIcon){
				if(iconDirection == AIIconFlipped) [statusIcon setFlipped:YES];
				[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusID];
			}
			
			[statusIcon release];
		}
	}
	
	return(statusIcon);
}

//Set the active status icon pack
+ (BOOL)setActiveStatusIconsFromPath:(NSString *)inPath
{
	if(!statusIconBasePath || ![statusIconBasePath isEqualToString:inPath]){
		NSDictionary	*statusIconPath = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
		
		if(statusIconPath && [[statusIconPath objectForKey:@"AdiumSetVersion"] intValue] == 1){
			statusIconBasePath = [inPath retain];
			
			statusIconNames[AIStatusIconTab] = [[statusIconPath objectForKey:@"Tabs"] retain];
			statusIconNames[AIStatusIconList] = [[statusIconPath objectForKey:@"List"] retain];
			
			return(YES);
		}else{
			return(NO);
		}
	}
}

//Returns the state icon for the passed chat (new content, tpying, ...)
+ (NSString *)_stateIDForChat:(AIChat *)inChat
{
	if([inChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
		return(@"content");
		
	}else{
		AITypingState typingState = [inChat integerStatusObjectForKey:KEY_TYPING];

		if(typingState == AITyping){
			return(@"typing");
			
		}else if (typingState == AIEnteredText){
			return(@"enteredtext");
		}
	}
	
	return(nil);
}

//Returns the status icon for the passed contact (away, idle, online, stranger, ...)
+ (NSString *)_statusIDForListObject:(AIListObject *)listObject
{
	AIStatusSummary statusSummary = [listObject statusSummary];

	switch (statusSummary){
		case AIAwayStatus:
		case AIAwayAndIdleStatus:
			return(@"away");
			break;

		case AIIdleStatus:
			return (@"idle");
			break;

		case AIAvailableStatus:
			return (@"available");
			break;

		case AIOfflineStatus:
			return(@"offline");
			break;

		case AIUnknownStatus:
		default:
			return(@"unknown");
	}
	
	return nil;
}

@end

