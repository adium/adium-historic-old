//
//  CSCheckmarkPlugin.m
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CSCheckmarkPlugin.h"
#import "CSCheckmarkPreferences.h"

//In case you want to use an image uncomment this and comment out the @interface
//#define CHECKMARK_IMAGE @"/Applications/Mail.app/Contents/Resources/iChatToolbar.tiff"
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
    
    //Also code for if you want to use a image instead of the resource
    //checkmarkImage =  [[NSImage alloc] initWithContentsOfFile:CHECKMARK_IMAGE];
    checkmarkImage =  [[NSImage systemCheckmark] retain];
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
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
    
}


#pragma mark AIListObjectObserver Protocol
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
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
    if ([checkmarkImage size].height > inRect.size.height)
	[checkmarkImage setSize:inRect.size];
    
    NSPoint drawingPoint = NSMakePoint(inRect.origin.x, inRect.origin.y + ceil((inRect.size.height / 2.0)) - ceil(([checkmarkImage size].height / 2.0)));
    [checkmarkImage drawAtPoint:drawingPoint fromRect:NSMakeRect(0, 0, [checkmarkImage size].width, [checkmarkImage size].height) operation:NSCompositeSourceOver fraction:1.0];
    
}

- (float)widthForHeight:(int)inHeight
{
    if ([checkmarkImage size].height > inHeight)
	return [checkmarkImage size].width * ((float)inHeight / [checkmarkImage size].height);
    return ([checkmarkImage size].width);
}

@end