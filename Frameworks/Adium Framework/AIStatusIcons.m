/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIChat.h"
#import "AIContentTyping.h"
#import "AIListObject.h"
#import "AIObject.h"
#import "AIStatusIcons.h"
#import "AIStatusController.h"

@implementation AIStatusIcons

static NSMutableDictionary	*statusIcons[NUMBER_OF_STATUS_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*statusIconBasePath = nil;
static NSDictionary			*statusIconNames[NUMBER_OF_STATUS_ICON_TYPES];

static NSString* statusNameForListObject(AIListObject *listObject);
static AIStatusType statusTypeForListObject(AIListObject *listObject);

static NSString* statusNameForChat(AIChat *inChat);

static BOOL					statusIconsReady = NO;

+ (void)initialize
{
	if(self == [AIStatusIcons class]){
		int i, j;
		
		//Allocate our status icon cache
		for(i = 0; i < NUMBER_OF_STATUS_ICON_TYPES; i++){
			for(j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++){
				statusIcons[i][j] = [[NSMutableDictionary alloc] init];
			}
		}
	}
}

//Retrieve the correct status icon for a given list object
+ (NSImage *)statusIconForListObject:(AIListObject *)listObject type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusName:statusNameForListObject(listObject)
									   statusType:statusTypeForListObject(listObject)
										 iconType:iconType
										direction:iconDirection];
}

+ (NSImage *)statusIconForUnknownStatusWithIconType:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusName:@"Unknown"
									   statusType:AIAvailableStatusType
										 iconType:iconType
										direction:iconDirection];	
}

//Retrieve the correct status icon for a given chat
+ (NSImage *)statusIconForChat:(AIChat *)chat type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSString	*statusName = statusNameForChat(chat);
	
	if(statusName){
		return [AIStatusIcons statusIconForStatusName:statusName
										   statusType:AIAvailableStatusType
											 iconType:iconType
											direction:iconDirection];
	}else{
		return nil;
	}
}

/* Copied from AIStatusController... this is called with a nil statusName frequently, so avoid making lots of extra method calls. */
NSString* defaultNameForStatusType(AIStatusType statusType)
{
	switch(statusType){
		case AIAvailableStatusType:
			return STATUS_NAME_AVAILABLE;
			break;
		case AIAwayStatusType:
			return STATUS_NAME_AWAY;
			break;
		case AIInvisibleStatusType:
			return STATUS_NAME_INVISIBLE;
			break;
		case AIOfflineStatusType:
			return STATUS_NAME_OFFLINE;
			break;
	}
}
							 
//Retrieve the correct status icon for the internal status ID
+ (NSImage *)statusIconForStatusName:(NSString *)statusName
						  statusType:(AIStatusType)statusType
							iconType:(AIStatusIconType)iconType
						   direction:(AIIconDirection)iconDirection
{
	NSImage				*statusIcon = nil;

	//If not passed a statusName, find a default
	if(!statusName) statusName = defaultNameForStatusType(statusType);
	
	//Retrieve the service icon from our cache
	statusIcon = [statusIcons[iconType][iconDirection] objectForKey:statusName];
	
	//Load the status icon if necessary
	if(!statusIcon && statusIconsReady){
		NSString	*fileName;
		
		//Look for a file name with this status name in the active pack
		fileName = [statusIconNames[iconType] objectForKey:statusName];
		if(fileName){
			NSString	*path = [statusIconBasePath stringByAppendingPathComponent:fileName];
			
			if(path){
				statusIcon = [[NSImage alloc] initByReferencingFile:path];
				
				if(statusIcon){
					if(iconDirection == AIIconFlipped) [statusIcon setFlipped:YES];
					[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
					
				}
				
				[statusIcon release];
			}
		}else{
			NSString	*defaultStatusName = defaultNameForStatusType(statusType);

			if(![defaultStatusName isEqualToString:statusName]){
				/* If the pack doesn't provide an icon for this specific status name, fall back on and then cache the default. */
				statusIcon = [self statusIconForStatusName:defaultStatusName
												statusType:statusType
												  iconType:iconType
												 direction:iconDirection];
				[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];

			}else{
				if(statusType == AIInvisibleStatusType){
					/* If we get here with an invisible status type, fall back on AIAwayStatusType */
					statusIcon = [self statusIconForStatusName:nil
													statusType:AIAwayStatusType
													  iconType:iconType
													 direction:iconDirection];
					[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
					
				}else{
					
					/* If we get here for a status name which is a default name, the pack doesn't have an image for us. */
					NSAssert2(FALSE, @"Invalid status icon pack %@: Missing required item %@",
							  [statusIconBasePath lastPathComponent], 
							  defaultStatusName);
				}
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
			
			statusIconsReady = YES;
			
			[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:AIStatusIconSetDidChangeNotification
																			   object:nil];
			
			return(YES);
		}else{
			statusIconsReady = NO;

			return(NO);
		}
	}
}

//Returns the state icon for the passed chat (new content, tpying, ...)
static NSString* statusNameForChat(AIChat *inChat)
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

/*
 * @brief Return the status name to use for looking up and caching this object's image
 *
 * Offline objects always use the STATUS_NAME_OFFLINE name.
 * Idle objects which are otherwise available (i.e. AIIdleStatus but not AIAwayAndIdleStatus) 
 * must explicitly be returned as @"Idle".
 *
 * If neither of those are the case, return the statusState's statusName if it exists.
 * If it doesn't, and the status is unknown, return @"Unknown".
 *
 * Finally, return nil if none of these conditions are met, indicating that the statusType's default
 * should be used.
 */
static NSString* statusNameForListObject(AIListObject *listObject)
{
	NSString		*statusName;
	AIStatusSummary	statusSummary = [listObject statusSummary];

	if(statusSummary == AIOfflineStatus){
		return STATUS_NAME_OFFLINE;
	}else if(statusSummary == AIIdleStatus){
		/* Note: AIIdleStatus, but not AIAwayAndIdleStatus, which implies an away state */
		return @"Idle";
	}else if(statusName = [[listObject statusState] statusName]){
		/* If we have a status name, use that */
		return statusName;
	}else{
		if(statusSummary == AIUnknownStatus){
			/* If the object is unknown and we don't have one yet, we'll use that */
			return @"Unknown";
		}
	}
	
	/* Otherwise, return nil, which will imply using the default status name for whatever statusType the object is in */
	return nil;
}

static AIStatusType statusTypeForListObject(AIListObject *listObject)
{
	AIStatusSummary	statusSummary = [listObject statusSummary];

	if(statusSummary == AIOfflineStatus)
		return AIOfflineStatusType;
	else
		return [[listObject statusState] statusType];
}

#pragma mark Preview menu images

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
		NSEnumerator	*enumerator = [[NSArray arrayWithObjects:STATUS_NAME_AVAILABLE,STATUS_NAME_AWAY,@"idle",@"offline",nil] objectEnumerator];
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

