//
//  AITabStatusIconsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//

#import "AITabStatusIconsPlugin.h"

@interface AITabStatusIconsPlugin (PRIVATE)
- (NSImage *)_iconForListObject:(AIListObject *)object;
@end

@implementation AITabStatusIconsPlugin

//
- (void)installPlugin
{
	//Load our icons (Hard coded for now)		
	tabStranger = [[NSImage imageNamed:@"tab-stranger" forClass:[self class]] retain];
	tabAway = [[NSImage imageNamed:@"tab-away" forClass:[self class]] retain];
	tabIdle = [[NSImage imageNamed:@"tab-idle" forClass:[self class]] retain];
	tabOffline = [[NSImage imageNamed:@"tab-offline" forClass:[self class]] retain];
	tabAvailable = [[NSImage imageNamed:@"tab-available" forClass:[self class]] retain];
	tabContent = [[NSImage imageNamed:@"tab-content" forClass:[self class]] retain];
	tabTyping = [[NSImage imageNamed:@"tab-typing" forClass:[self class]] retain];
	tabEnteredText = [[NSImage imageNamed:@"tab-entered-text" forClass:[self class]] retain];
	
	//Observe list object changes
	[[adium contactController] registerListObjectObserver:self];
}

//Apply the correct tab icon according to status
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributes = nil;
	
	if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"UnviewedContent"] ||
	   [inModifiedKeys containsObject:@"Typing"] ||
	   [inModifiedKeys containsObject:@"Stranger"] ||
	   [inModifiedKeys containsObject:@"Away"] ||
	   [inModifiedKeys containsObject:@"IdleSince"] ||
	   [inModifiedKeys containsObject:@"Online"]){
		
		[[inObject displayArrayForKey:@"Tab Icon"] setObject:[self _iconForListObject:inObject] withOwner:self];
        modifiedAttributes = [NSArray arrayWithObject:@"Tab Icon"];
	}
	
	return(modifiedAttributes);
}

//Returns the icon for the passed contact
- (NSImage *)_iconForListObject:(AIListObject *)listObject
{
	if([listObject integerStatusObjectForKey:@"UnviewedContent"]){
		return(tabContent);
		
	}else{
		AITypingState typingState = [listObject integerStatusObjectForKey:@"Typing"];
		NSLog(@"%i",typingState);
		if(typingState == AITyping){
			return(tabTyping);
			
		}else if (typingState == AIEnteredText){
			return(tabEnteredText);
			
		}else if([[listObject numberStatusObjectForKey:@"Away"] boolValue]){
			return(tabAway);
			
		}else if([listObject statusObjectForKey:@"IdleSince"]){
			return(tabIdle);
			
		}else if([[listObject numberStatusObjectForKey:@"Online"] boolValue]){
			return(tabAvailable);
			
		}else if([listObject integerStatusObjectForKey:@"Stranger"]){
			return(tabStranger);
			
		}else{
			return(tabOffline);
			
		}
	}
}
@end
