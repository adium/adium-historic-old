//
//  AIToolbar.m
//  Adium
//
//  Created by Evan Schoenberg on 10/20/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIToolbar.h"

/*
 AIToolbar poses as NSToolbar to fix what I consider a bug in Apple's implementation: 
 NSToolbarDidRemoveItemNotification is not sent for the toolbar's items when the toolbar closes.
 
 AIToolbar sends this notification for each item so observers can balance any action taken via
 the NSToolbarWillAddItemNotification notification.
 */

@implementation AIToolbar
/* load
*   install ourself to intercept dealloc calls
*/
+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass: [NSToolbar class]];
}

- (void)dealloc
{
	NSNotificationCenter	*defaultCenter = [NSNotificationCenter defaultCenter];
	NSEnumerator			*enumerator;
	NSToolbarItem			*item;

	//Post the notification for each item
	enumerator = [[self items] objectEnumerator];
	while(item = [enumerator nextObject]){
		[defaultCenter postNotificationName:NSToolbarDidRemoveItemNotification
									 object:self
								   userInfo:[NSDictionary dictionaryWithObject:item
																		forKey:@"item"]];
	}

	//Now perform super's dealloc behavior
	[super dealloc];
}

@end
