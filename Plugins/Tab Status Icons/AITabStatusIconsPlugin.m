//
//  AITabStatusIconsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AITabStatusIconsPlugin.h"

@interface AITabStatusIconsPlugin (PRIVATE)
- (NSString *)_stateIDForChat:(AIChat *)inChat;
- (NSString *)_statusIDForListObject:(AIListObject *)listObject;
@end

@implementation AITabStatusIconsPlugin

//
- (void)installPlugin
{
	//Observe list object changes
	[[adium contactController] registerListObjectObserver:self];
	
	//Observe chat changes
	[[adium contentController] registerChatObserver:self];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(statusIconSetDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
}

- (void)statusIconSetDidChange:(NSNotification *)aNotification
{
	[[adium contactController] updateAllListObjectsForObserver:self];
	[[adium contentController] updateAllChatsForObserver:self];
}

//Apply the correct tab icon according to status
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;
	
	if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Stranger"] ||
	   [inModifiedKeys containsObject:@"Away"] ||
	   [inModifiedKeys containsObject:@"IsIdle"] ||
	   [inModifiedKeys containsObject:@"Online"]){
		
		//Tab
		NSImage	*icon = [AIStatusIcons statusIconForListObject:inObject
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inObject displayArrayForKey:@"Tab Status Icon"] setObject:icon withOwner:self];

		//List
		icon = [AIStatusIcons statusIconForListObject:inObject
											   type:AIStatusIconList
										  direction:AIIconNormal];
		[[inObject displayArrayForKey:@"List Status Icon"] setObject:icon withOwner:self];
		
		modifiedAttributes = [NSSet setWithObjects:@"Tab Status Icon", @"List Status Icon", nil];
	}
	
	return(modifiedAttributes);
}

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;
	
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_TYPING] ||
		[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
		

		NSImage	*icon = [AIStatusIcons statusIconForChat:inChat
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inChat displayArrayForKey:@"Tab State Icon"] setObject:icon withOwner:self];
		
		modifiedAttributes = [NSSet setWithObject:@"Tab State Icon"];
	}
	
	return(modifiedAttributes);
}

@end
