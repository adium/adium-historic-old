//
//  AIStatusIcons.m
//  Adium
//
//  Created by Adam Iser on 8/23/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
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
+ (NSImage *)statusIconForListObject:(AIListObject *)object type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusID:[AIStatusIcons _statusIDForListObject:object]
										   type:iconType
									  direction:iconDirection];
}

//Retrieve the correct status icon for a given chat
+ (NSImage *)statusIconForChat:(AIChat *)chat type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusID:[AIStatusIcons _stateIDForChat:chat]
										   type:iconType
									  direction:iconDirection];
}



//Retrieve the correct status icon for the internal status ID
//We will probably want to remove this method and have everyone pass us list objects instead
+ (NSImage *)statusIconForStatusID:(NSString *)statusID type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage				*statusIcon = nil;
	
	if(statusID){
		//Retrieve the service icon from our cache
		statusIcon = [statusIcons[iconType][iconDirection] objectForKey:statusID];
		
		//Load the status icon if necessary
		if(!statusIcon){
			NSString	*path = [statusIconBasePath stringByAppendingPathComponent:[statusIconNames[iconType] objectForKey:statusID]];
			
			if(path){
				statusIcon = [[NSImage alloc] initByReferencingFile:path];
				
				if(statusIcon){
					if(iconDirection == AIIconFlipped) [statusIcon setFlipped:YES];
					[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusID];
				}
				
				[statusIcon release];
			}
		}
	}
	
	return(statusIcon);
}

//Set the active status icon pack
+ (BOOL)setActiveStatusIconsFromPath:(NSString *)inPath
{
	if(!statusIconBasePath || ![statusIconBasePath isEqualToString:inPath]){
		NSDictionary	*statusIconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
		
		if(statusIconDict && [[statusIconDict objectForKey:@"AdiumSetVersion"] intValue] == 1){
			[statusIconBasePath release];
			statusIconBasePath = [inPath retain];
			
			[statusIconNames[AIStatusIconTab] release];
			statusIconNames[AIStatusIconTab] = [[statusIconDict objectForKey:@"Tabs"] retain];
			
			[statusIconNames[AIStatusIconList] release];
			statusIconNames[AIStatusIconList] = [[statusIconDict objectForKey:@"List"] retain];
			
			//Clear out the status icon cache
			int i, j;
			
			for(i = 0; i < NUMBER_OF_STATUS_ICON_TYPES; i++){
				for(j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++){
					[statusIcons[i][j] removeAllObjects];
				}
			}
			
			[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:@"AIStatusIconSetDidChange"
																			   object:nil];
			
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

#define	PREVIEW_MENU_IMAGE_SIZE		13
#define	PREVIEW_MENU_IMAGE_MARGIN	2

+ (NSImage *)previewMenuImageForStatusIconsAtPath:(NSString *)inPath
{
	NSImage			*image;
	NSDictionary	*iconDict;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize((PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN) * 4,
															  PREVIEW_MENU_IMAGE_SIZE)];

	iconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
	
	if(iconDict && [[iconDict objectForKey:@"AdiumSetVersion"] intValue] == 1){
		NSDictionary	*previewIconNames = [iconDict objectForKey:@"List"];
		NSEnumerator	*enumerator = [[NSArray arrayWithObjects:@"available",@"away",@"idle",@"offline",nil] objectEnumerator];
		NSString		*iconID;
		int				xOrigin = 0;

		[image lockFocus];
		while(iconID = [enumerator nextObject]){
			NSString	*anIconPath = [inPath stringByAppendingPathComponent:[previewIconNames objectForKey:iconID]];
			NSImage		*anIcon;
			
			if(anIcon = [[[NSImage alloc] initWithContentsOfFile:anIconPath] autorelease]){
				NSSize	anIconSize = [anIcon size];
				NSRect	targetRect = NSMakeRect(xOrigin, 0, PREVIEW_MENU_IMAGE_SIZE, PREVIEW_MENU_IMAGE_SIZE);
				
				if(anIconSize.width < targetRect.size.width){
					float difference = (targetRect.size.width - anIconSize.width)/2;
					
					targetRect.size.width -= difference;
					targetRect.origin.x += difference;
				}
				
				if(anIconSize.height < targetRect.size.height){
					float difference = (targetRect.size.height - anIconSize.height)/2;
					
					targetRect.size.height -= difference;
					targetRect.origin.y += difference;
				}
				
				[anIcon drawInRect:targetRect
						  fromRect:NSMakeRect(0,0,anIconSize.width,anIconSize.height)
						 operation:NSCompositeCopy
						  fraction:1.0];
				
				//Shift right in preparation for next image
				xOrigin += PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN;
			}
		}
		[image unlockFocus];
	}		

	return([image autorelease]);
}

@end

