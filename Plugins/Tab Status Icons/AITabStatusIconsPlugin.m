//
//  AITabStatusIconsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//

#import "AITabStatusIconsPlugin.h"

@interface AITabStatusIconsPlugin (PRIVATE)
- (NSString *)_stateIDForChat:(AIChat *)inChat;
- (NSString *)_statusIDForListObject:(AIListObject *)listObject;
@end

@implementation AITabStatusIconsPlugin

#warning temporary status icon stuff in here

//
- (void)installPlugin
{
	//Observe list object changes
	[[adium contactController] registerListObjectObserver:self];
	
	//Observe chat changes
	[[adium contentController] registerChatObserver:self];
}

//Apply the correct tab icon according to status
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;
	
	if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Stranger"] ||
	   [inModifiedKeys containsObject:@"Away"] ||
	   [inModifiedKeys containsObject:@"IdleSince"] ||
	   [inModifiedKeys containsObject:@"Online"]){
		
		//Tab
		NSImage	*icon = [AIStatusIcons statusIconForStatusID:[self _statusIDForListObject:inObject]
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inObject displayArrayForKey:@"Tab Status Icon"] setObject:icon withOwner:self];

		//List
		icon = [AIStatusIcons statusIconForStatusID:[self _statusIDForListObject:inObject]
											   type:AIStatusIconList
										  direction:AIIconNormal];
		[[inObject displayArrayForKey:@"List Status Icon"] setObject:icon withOwner:self];
		
		modifiedAttributes = [NSArray arrayWithObjects:@"Tab Status Icon", @"List Status Icon", nil];
	}
	
	return(modifiedAttributes);
}

- (NSArray *)updateChat:(AIChat *)inChat keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray		*modifiedAttributes = nil;
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_TYPING] ||
		[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
		

		NSImage	*icon = [AIStatusIcons statusIconForStatusID:[self _stateIDForChat:inChat]
														type:AIStatusIconTab
												   direction:AIIconNormal];
		[[inChat displayArrayForKey:@"Tab State Icon"] setObject:icon withOwner:self];
		
		modifiedAttributes = [NSArray arrayWithObject:@"Tab State Icon"];
	}
	
	return(modifiedAttributes);
}

//Returns the state icon for the passed chat (new content, tpying, ...)
- (NSString *)_stateIDForChat:(AIChat *)inChat
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
- (NSString *)_statusIDForListObject:(AIListObject *)listObject
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
