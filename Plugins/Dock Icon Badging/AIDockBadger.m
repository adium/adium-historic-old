
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

#pragma mark Birth and death

/*!
* @brief Install
 */
- (void)installPlugin
{
    overlayState = nil;
	currentCount = -1;
	//Register as a chat observer (for unviewed content)
	[[adium chatController] registerChatObserver:self];
#define BadgerBadgerBadger
#ifndef BadgerBadgerBadger
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contentAdded:)
									   name:Content_WillReceiveContent
									 object:nil];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatClosed:)
									   name:Chat_WillClose
									 object:nil];
	
#endif
    //Prefs
//	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
}

- (void)uninstallPlugin
{
	[[adium chatController] unregisterChatObserver:self];
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

#pragma mark Signals to update

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
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

- (void)chatClosed:(NSNotification *)notification
{	
	[self performSelector:@selector(_setOverlay)
			   withObject:nil
			   afterDelay:0];
}

#pragma mark Work methods

- (NSImage *)numberedBadge:(int)count
{
	if(!badgeOne) {
		badgeOne = [[NSImage imageNamed:@"newContentTwoDigits"] retain];
		badgeTwo = [[NSImage imageNamed:@"newContentThreeDigits"] retain];
	}

	NSImage * badge = nil, * badgeToComposite = nil;
	NSString * numString = nil;

	if(count < 1000) {
		NSImage *badges[] = { badgeOne, badgeTwo };
		badgeToComposite = badges[(count >= 10)];
		numString = [[NSNumber numberWithInt:count] description];
	} else {
		//999 unread messages should be enough for anyone
		badgeToComposite = badgeTwo;
		numString = AILocalizedString(@"Too many unread messages", /*comment*/ nil);
	}
	
	NSRect rect = { NSZeroPoint, [badgeToComposite size] };
	NSDictionary * atts = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor whiteColor], NSForegroundColorAttributeName,
		[NSFont boldSystemFontOfSize:24], NSFontAttributeName,
		nil];
	
	NSSize numSize = [numString sizeWithAttributes:atts];
	rect.origin.x = (rect.size.width / 2) - (numSize.width / 2);
	rect.origin.y = (rect.size.height / 2) - (numSize.height / 2);

	badge = [[[NSImage alloc] initWithSize:rect.size] autorelease];
	[badge setFlipped:YES];
	[badge lockFocus];
	[badgeToComposite compositeToPoint:NSMakePoint(0, rect.size.height) operation:NSCompositeSourceOver];

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
    if (contentCount > 0) {
        //Set the state
        overlayState = [[AIIconState alloc] initWithImage:[self numberedBadge:contentCount] 
												  overlay:YES];
        [[adium dockController] setIconState:overlayState named:@"UnviewedContentCount"];
    }   
}

@end
