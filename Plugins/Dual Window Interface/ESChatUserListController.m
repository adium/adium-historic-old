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

@end
