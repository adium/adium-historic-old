//
//  AITabStatusIconsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
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
	}else if([listObject integerStatusObjectForKey:@"Typing"]){
		return(tabTyping);
	}else if([listObject integerStatusObjectForKey:@"Stranger"]){
		return(tabStranger);
	}else if([[listObject numberStatusObjectForKey:@"Away"] boolValue]){
		return(tabAway);
	}else if([listObject statusObjectForKey:@"IdleSince"]){
		return(tabIdle);
	}else if([[listObject numberStatusObjectForKey:@"Online"] boolValue]){
		return(tabAvailable);
	}else{
		return(tabOffline);
	}
}
		
@end
