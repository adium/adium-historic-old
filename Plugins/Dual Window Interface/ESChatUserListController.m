//
//  ESChatUserListController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/14/04.
//

#import "ESChatUserListController.h"


@implementation ESChatUserListController

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[[self delegate] performSelector:@selector(outlineViewSelectionDidChange:)
						  withObject:notification];
}

//We don't want to change text colors based on the user's status or state
- (BOOL)shouldUseContactTextColors{
	return(NO);
}

#warning Evan: Tooltips currently crash after the tab is closed. Disabling in the userlist for now.
/*
	Somehow the mouseEntered: and mouseExited: calls are being sent to the tracking rect of the
	user list even after AISmoothTooltipTracker deallocs and removes its tracking rect.  This shows up in
	a stack trace as NSWindow doing a sendEvent: and hitting a released object (which of course the
	AISmoothTooltipTracker object is after it is released).
 */
- (BOOL)shouldShowTooltips{
	return(NO);
}
@end
