//
//  AIContactListRecentImagesWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/19/05.
//

#import "AIContactListRecentImagesWindowController.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "AIStandardListWindowController.h"
#import "AIContactListImagePicker.h"
#import "AIMenuItemView.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIImageGridView.h>
#import <AIUtilities/AIBorderlessWindow.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIColorSelectionPopUpButton.h>
#import <AIUtilities/AIColoredBoxView.h>

#import "NSIPRecentPicture.h"

#define ALL_OTHER_ACCOUNTS AILocalizedString(@"All Other Accounts", nil)

#define FADE_INCREMENT	0.3
#define FADE_TIME		.3

@interface AIContactListRecentImagesWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)inWindowNibName
				imagePicker:(AIContactListImagePicker *)inPicker
	  recentPictureSelector:(SEL)inRecentPictureSelector;
- (void)fadeOutAndClose;
@end

@implementation AIContactListRecentImagesWindowController
/*
 * @brief Show the widow
 *
 * @param inPoint The bottom-right corner of our parent view
 */
+ (void)showWindowFromPoint:(NSPoint)inPoint
				imagePicker:(AIContactListImagePicker *)inPicker
	  recentPictureSelector:(SEL)inRecentPictureSelector
{
	AIContactListRecentImagesWindowController	*controller = [[self alloc] initWithWindowNibName:@"ContactListRecentImages"
																					  imagePicker:inPicker
																			recentPictureSelector:inRecentPictureSelector];

	NSWindow			*window = [controller window];

	[controller positionFromPoint:inPoint];
	[(AIBorderlessWindow *)window setMoveable:NO];
	
	[controller showWindow:nil];
	[window makeKeyAndOrderFront:nil];
}

- (id)initWithWindowNibName:(NSString *)inWindowNibName
				imagePicker:(AIContactListImagePicker *)inPicker
	  recentPictureSelector:(SEL)inRecentPictureSelector
{
	if ((self = [super initWithWindowNibName:inWindowNibName])) {
		picker = [inPicker retain];
		recentPictureSelector = inRecentPictureSelector;
	}
	
	return self;
}

- (void)dealloc
{
	[picker release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[imageGridView setImageSize:NSMakeSize(30, 30)];	
	[coloredBox setColor:[NSColor windowBackgroundColor]];
	currentHoveredIndex = -1;
}

- (void)positionFromPoint:(NSPoint)inPoint
{
	NSWindow *window = [self window];
	NSRect	 frame = [window frame];
	NSRect	 screenFrame = [[window screen] visibleFrame];
	
	frame.origin.x = inPoint.x - frame.size.width;
	if (frame.origin.x < screenFrame.origin.x) {
		frame.origin.x = screenFrame.origin.x;
	} else if (frame.origin.x + frame.size.width > screenFrame.origin.x + screenFrame.size.width) {
		frame.origin.x = screenFrame.origin.x + screenFrame.size.width - frame.size.width;
	}
	
	frame.origin.y = inPoint.y - frame.size.height;
	if (frame.origin.y < screenFrame.origin.y) {
		frame.origin.y = screenFrame.origin.y;
	}
	
	[window setFrame:frame display:NO animate:NO];	
}

- (int)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return 10;
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(int)index
{
	NSImage		 *displayImage;

	if (index < [[NSIPRecentPicture recentPictures] count]) {
		NSImage		 *image = [[NSIPRecentPicture recentSmallIcons] objectAtIndex:index];
		NSSize		size = [image size];
		NSBezierPath *fullPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, size.width, size.height)];
		displayImage = [image copy];
		
		[displayImage setFlipped:YES];
		[displayImage lockFocus];
		
		if (index == currentHoveredIndex) {
			[[[NSColor blueColor] colorWithAlphaComponent:0.30] set];
			[fullPath fill];
			
			[[NSColor blueColor] set];
			[fullPath stroke];
			
		} else {
			[[NSColor whiteColor] set];
			[fullPath stroke];
		}
		
		[displayImage unlockFocus];
	} else {
		NSSize		 size = NSMakeSize(32, 32);
		NSBezierPath *fullPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, size.width, size.height)];

		displayImage = [[NSImage alloc] initWithSize:size];
		[displayImage lockFocus];
		
		[[NSColor lightGrayColor] set];
		[fullPath fill];
		
		[displayImage unlockFocus];
	}
	
	return [displayImage autorelease];
}

- (void)imageGridView:(AIImageGridView *)inImageGridView cursorIsHoveringImageAtIndex:(int)index
{
	//Update our hovered index and redisplay the image
	currentHoveredIndex = index;
	[imageGridView setNeedsDisplayOfImageAtIndex:index];
}

- (void)imageGridViewSelectionDidChange:(NSNotification *)notification
{
	//Notify as if the image had been selected in the picker
	[[picker delegate] imageViewWithImagePicker:picker
						   didChangeToImageData:[NSData dataWithContentsOfFile:[[[NSIPRecentPicture recentPictures] objectAtIndex:[imageGridView selectedIndex]] originalImagePath]]];

	[self fadeOutAndClose];
}

- (void)selectedAccount:(id)sender
{
	AIAccount	*activeAccount = [sender representedObject];

	//Change the active account
	[[adium preferenceController] setPreference:(activeAccount ? [activeAccount internalObjectID] : nil)
										 forKey:@"Active Icon Selection Account"
										  group:GROUP_ACCOUNT_STATUS];

	[menuItemView setMenu:[self menuForMenuItemView:menuItemView]];
}

- (void)chooseIcon:(id)sender
{
	[picker showImagePicker:nil];
	
	[self fadeOutAndClose];
}

- (void)clearRecentPictures:(id)sender
{
	[NSIPRecentPicture removeAllButCurrent];
	[imageGridView reloadData];
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	[self fadeOutAndClose];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[self fadeOutAndClose];		
}

#pragma mark Fading
- (void)fadeOut:(NSTimer *)inTimer
{
	float				currentAlpha = [[self window] alphaValue];
	currentAlpha -= 0.15;
	
	if (currentAlpha <= 0) {
		[self close];
		[inTimer invalidate];

	} else {
		[[self window] setAlphaValue:currentAlpha];
	}
}

- (void)fadeOutAndClose
{
	[NSTimer scheduledTimerWithTimeInterval:.01
									 target:self 
								   selector:@selector(fadeOut:)
								   userInfo:nil
									repeats:YES];
}

#pragma mark AIMenuItemView delegate

- (NSMenu *)menuForMenuItemView:(AIMenuItemView *)inMenuItemView
{
	NSMenu		 *menu = [[NSMenu alloc] init];
	NSMutableSet *onlineAccounts = [NSMutableSet set];
	NSMutableSet *ownIconAccounts = [NSMutableSet set];
	AIAccount	 *activeAccount = nil;
	NSMenuItem	 *menuItem;

	activeAccount = [AIStandardListWindowController activeAccountGettingOnlineAccounts:onlineAccounts ownIconAccounts:ownIconAccounts];
	
	int ownIconAccountsCount = [ownIconAccounts count];
	int onlineAccountsCount = [onlineAccounts count];
	if (ownIconAccountsCount && ((ownIconAccountsCount > 1) || (onlineAccountsCount > 1))) {
		//There are at least some accounts using the global preference if the counts differ
		BOOL		 includeGlobal = (onlineAccountsCount != ownIconAccountsCount);
		AIAccount	 *account;
		NSEnumerator *enumerator;

		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Change Icon For:", nil)
											  target:nil
											  action:nil
									   keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[menu addItem:menuItem];
		[menuItem release];
		
		enumerator = [ownIconAccounts objectEnumerator];
		while ((account = [enumerator nextObject])) {
			//Put a check before the account if it is the active account
			menuItem = [[NSMenuItem alloc] initWithTitle:[account formattedUID]
												  target:self
												  action:@selector(selectedAccount:)
										   keyEquivalent:@""];
			[menuItem setRepresentedObject:account];

			if (activeAccount == account) {
				[menuItem setState:NSOnState];
			}
			[menu addItem:menuItem];
			
			[menuItem release];
		}
		
		if (includeGlobal) {
			menuItem = [[NSMenuItem alloc] initWithTitle:ALL_OTHER_ACCOUNTS
												  target:self
												  action:@selector(selectedAccount:)
										   keyEquivalent:@""];
			if (!activeAccount) {
				[menuItem setState:NSOnState];
			}

			[menu addItem:menuItem];
			[menuItem release];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];

	} else {
		//All accounts are using the global preference
	}

	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Choose Icon", nil) stringByAppendingEllipsis]
										  target:self
										  action:@selector(chooseIcon:)
								   keyEquivalent:@""];
	[menu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Clear Recent Pictures", nil) stringByAppendingEllipsis]
										  target:self
										  action:@selector(clearRecentPictures:)
								   keyEquivalent:@""];
	[menu addItem:menuItem];
	[menuItem release];

	return [menu autorelease];
}

- (void)menuItemViewDidChangeMenu:(AIMenuItemView *)inMenuItemView
{
	NSRect	oldFrame = [inMenuItemView frame];
	[inMenuItemView sizeToFit];
	NSRect	newFrame = [inMenuItemView frame];

	float	heightDifference = newFrame.size.height - oldFrame.size.height;

	if (heightDifference != 0) {
		NSRect	myFrame = [[self window] frame];
		
		myFrame.size.height += heightDifference;
		myFrame.origin.y -= heightDifference;
		
		[[self window] setFrame:myFrame display:YES animate:NO];
	}
}


@end
