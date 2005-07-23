
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

#import "AIDockBadger.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIDockController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIIconState.h>

@interface AIDockBadger (PRIVATE)
- (void)_setOverlay;
@end

@implementation AIDockBadger

/*!
* @brief Install
 */
- (void)installPlugin
{
	overlayObjectsArray = [[NSMutableArray alloc] init];
    overlayState = nil;
	
	//Register as a chat observer (for unviewed content)
//	[[adium chatController] registerChatObserver:self];
#define BadgerBadgerBadger
#ifndef BadgerBadgerBadger
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatClosed:)
									   name:Chat_WillClose
									 object:nil];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contentAdded:)
									   name:Content_WillReceiveContent
									 object:nil];
	
#endif
    //Prefs
//	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
}

- (NSSet *) chatStatusChanged:(AIChat *)chat modifiedStatusKeys:(NSSet *)keys silent:(BOOL)silent
{
	[self performSelector:@selector(_setOverlay)
			   withObject:nil
			   afterDelay:0];
	return nil;
}

- (void)contentAdded:(NSNotification *)not
{
	[self performSelector:@selector(_setOverlay)
			   withObject:nil
			   afterDelay:0];
}

- (void)uninstallPlugin
{
	[[adium chatController] unregisterChatObserver:self];
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	[overlayObjectsArray removeObjectIdenticalTo:chat];
	
	[self performSelector:@selector(_setOverlay)
			   withObject:nil
			   afterDelay:0];
}

- (NSImage *)numberedBadge:(int)count
{
	static int currentCount = -1;
	static NSImage * badgeOne;
	static NSImage * badgeTwo;
	NSImage * badge = nil;
	if(!badgeOne)
	{
		badgeOne = [[NSImage imageNamed:@"newContentTwoDigits"] retain];
		badgeTwo = [[NSImage imageNamed:@"newContentThreeDigits"] retain];
	}

	if(count < 10)
	{
		badge = [[NSImage alloc] initWithSize:[badgeOne size]];
		[badge setFlipped:YES];
		[badge lockFocus];
		[badgeOne compositeToPoint:NSMakePoint(0, [badge size].height) operation:NSCompositeSourceOver];
	}
	else if(count < 100) //99 unread messages should be enough for anyone
	{
		badge = [[NSImage alloc] initWithSize:[badgeTwo size]];
		[badge setFlipped:YES];
		[badge lockFocus];
		[badgeTwo compositeToPoint:NSMakePoint(0, [badge size].height) operation:NSCompositeSourceOver];
	}
	
	NSRect rect = {NSZeroPoint, [badge size]};
	NSDictionary * atts = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [NSFont boldSystemFontOfSize:24], NSFontAttributeName, nil];
	
	NSString * numString = [[NSNumber numberWithInt:count] description];
	NSSize numSize = [numString sizeWithAttributes:atts];
	rect.origin.x = (rect.size.width / 2) - (numSize.width / 2);
	rect.origin.y = (rect.size.height / 2) - (numSize.height / 2);
	[numString drawInRect:rect
		   withAttributes:atts];
	
	[badge unlockFocus];
		
	currentCount = count;
	return badge;
}

//
- (void)_setOverlay
{
    //Remove & release the current overlay state
    if (overlayState) {
        [[adium dockController] removeIconStateNamed:@"UnviewedContentCount"];
        [overlayState release]; overlayState = nil;
    }
	
	int contentCount = [[adium chatController] unviewedContentCount];
	
    //Create & set the new overlay state
    if (contentCount > 0 && contentCount < 100) {
        //Set the state
        overlayState = [[AIIconState alloc] initWithImage:[self numberedBadge:contentCount] 
												  overlay:YES];
        [[adium dockController] setIconState:overlayState named:@"UnviewedContentCount"];
    }   
}

@end
