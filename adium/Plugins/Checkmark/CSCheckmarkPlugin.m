/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

#import "CSCheckmarkPlugin.h"
#import "CSCheckmarkPreferences.h"

@interface CSCheckmarkPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation CSCheckmarkPlugin

- (void)installPlugin
{
    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CHECKMARK_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_CHECKMARK];
    preferences = [[CSCheckmarkPreferences preferencePane] retain];
	
    //Observe
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	
    [[adium contactController] registerListObjectObserver:self];
	
	//Also code for if you want to use a image instead of the resource
    //checkmarkImage =  [[NSImage alloc] initWithContentsOfFile:CHECKMARK_IMAGE];
	checkmarkImage =  [[NSImage systemCheckmark] retain];
    [checkmarkImage setScalesWhenResized:YES];
    [checkmarkImage setFlipped:YES];
	
	[self preferencesChanged:nil];
}

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