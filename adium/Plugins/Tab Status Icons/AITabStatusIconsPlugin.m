//
//  AITabStatusIconsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//

#import "AITabStatusIconsPlugin.h"

@interface AITabStatusIconsPlugin (PRIVATE)
- (NSImage *)_stateIconForChat:(AIChat *)inChat;
- (NSImage *)_statusIconForListObject:(AIListObject *)listObject;
@end

@implementation AITabStatusIconsPlugin

//
- (void)installPlugin
{
	//Load our icons (Hard coded for now)		
	tabUnknown = [[NSImage imageNamed:@"tab-unknown" forClass:[self class]] retain];
	tabAway = [[NSImage imageNamed:@"tab-away" forClass:[self class]] retain];
	tabIdle = [[NSImage imageNamed:@"tab-idle" forClass:[self class]] retain];
	tabOffline = [[NSImage imageNamed:@"tab-offline" forClass:[self class]] retain];
	tabAvailable = [[NSImage imageNamed:@"tab-available" forClass:[self class]] retain];
	tabContent = [[NSImage imageNamed:@"tab-content" forClass:[self class]] retain];
	tabTyping = [[NSImage imageNamed:@"tab-typing" forClass:[self class]] retain];
	tabEnteredText = [[NSImage imageNamed:@"tab-entered-text" forClass:[self class]] retain];
	
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
		
		[[inObject displayArrayForKey:@"Tab Status Icon"] setObject:[self _statusIconForListObject:inObject]
														  withOwner:self];
		
		modifiedAttributes = [NSArray arrayWithObject:@"Tab Status Icon"];
	}
	
	return(modifiedAttributes);
}

- (NSArray *)updateChat:(AIChat *)inChat keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	NSArray		*modifiedAttributes = nil;
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_TYPING] ||
		[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
		
		[[inChat displayArrayForKey:@"Tab State Icon"] setObject:[self _stateIconForChat:inChat] 
													   withOwner:self];
		
		modifiedAttributes = [NSArray arrayWithObject:@"Tab State Icon"];
	}
	
	return(modifiedAttributes);
}

//Returns the state icon for the passed chat (new content, tpying, ...)
- (NSImage *)_stateIconForChat:(AIChat *)inChat
{
	if([inChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
		return(tabContent);
		
	}else{
		AITypingState typingState = [inChat integerStatusObjectForKey:KEY_TYPING];

		if(typingState == AITyping){
			return(tabTyping);
			
		}else if (typingState == AIEnteredText){
			return(tabEnteredText);
		}
	}
	
	//If the chat has no list object, return the online icon for the state since there will be no status
	if(![inChat listObject]) return (tabAvailable);
	
	return(nil);
}

//Returns the status icon for the passed contact (away, idle, online, stranger, ...)
- (NSImage *)_statusIconForListObject:(AIListObject *)listObject
{
	AIStatusSummary statusSummary = [listObject statusSummary];

	switch (statusSummary){
		case AIAwayStatus:
		case AIAwayAndIdleStatus:
			return(tabAway);
			break;

		case AIIdleStatus:
			return (tabIdle);
			break;

		case AIAvailableStatus:
			return (tabAvailable);
			break;

		case AIOfflineStatus:
			return(tabOffline);
			break;

		case AIUnknownStatus:
		default:
			return(tabUnknown);
	}
	
	return nil;
}

@end
