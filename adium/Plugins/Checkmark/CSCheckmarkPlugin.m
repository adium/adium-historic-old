//
//  CSCheckmarkPlugin.m
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CSCheckmarkPlugin.h"
#import "CSCheckmarkPreferences.h"

#define CHECKMARK_IMAGE @"checkmark.tiff"

@interface CSCheckmarkPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation CSCheckmarkPlugin

#pragma mark Plugin Initiation
- (void)installPlugin
{
	displayCheckmark = NO;
	
	[self preferencesChanged:nil];
	
    //Our preference view
    checkmarkPreferences = [[CSCheckmarkPreferences checkmarkPreferences] retain];
	[[adium contactController] registerListObjectObserver:self];
	
	//Observe
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	
	checkmarkImage = [[AIImageUtilities imageNamed:CHECKMARK_IMAGE forClass:[self class]] retain];
	[checkmarkImage setScalesWhenResized:YES];
	[checkmarkImage setFlipped:YES];
}

- (void)dealloc
{
	[checkmarkImage release];
}

#pragma mark Private
- (void)preferencesChanged:(NSNotification *)notification
{
	
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CHECKMARK] == 0){
		
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CHECKMARK];
		
		//Release the old values..
		//Cache the preference values
		displayCheckmark  = [[prefDict objectForKey:KEY_DISPLAY_CHECKMARK] boolValue];
		
        //Update all our status icons
		NSEnumerator		*enumerator;
		AIListObject		*object;
		
		enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
		
		while(object = [enumerator nextObject]){
            [[adium contactController] listObjectAttributesChanged:object modifiedKeys:[self updateListObject:object keys:nil delayed:YES silent:YES] delayed:YES];
        }
    }
	
}


#pragma mark AIListObjectObserver Protocol
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
	if ( inModifiedKeys == nil || [inModifiedKeys containsObject:@"ChatsCount"]) {
		AIMutableOwnerArray		*iconArray = [inObject displayArrayForKey:@"Left View"];
		int chatsCount = [[inObject statusArrayForKey:@"ChatsCount"] greatestIntegerValue];
		
		if (displayCheckmark && (chatsCount > 0))
			[iconArray setObject:self withOwner:self];
		else
			[iconArray setObject:nil withOwner:self];
		
		return ([NSArray arrayWithObjects:@"Left View",nil]);
	}
	return nil;
}

#pragma mark AIListObjectLeftView Protocol
- (void)drawInRect:(NSRect)inRect
{
	[checkmarkImage setSize:inRect.size];
	
	NSPoint drawingPoint = NSMakePoint(inRect.origin.x, inRect.origin.y + ceil((inRect.size.height / 2.0)) - ceil(([checkmarkImage size].height / 2.0)));
	[checkmarkImage drawAtPoint:drawingPoint fromRect:NSMakeRect(0, 0, [checkmarkImage size].width, [checkmarkImage size].height) operation:NSCompositeSourceOver fraction:1.0];

}

- (float)widthForHeight:(int)inHeight
{
	return [checkmarkImage size].width * ((float)inHeight / [checkmarkImage size].height);
}

@end
