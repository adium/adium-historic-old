//
//  ESSecureMessagingPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 1/24/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOCK_IMAGE_ANIMATION_STEPS 15

typedef enum {
	AISecureMessagingMenu_Toggle = 1,
	AISecureMessagingMenu_ShowDetails,
	AISecureMessagingMenu_ShowAbout
} AISecureMessagingMenuTag;

@interface ESSecureMessagingPlugin : AIPlugin <AIChatObserver> {
	NSImage	*lockImage_Locked;
	NSImage	*lockImage_Unlocked;
	NSImage *lockImageAnimation[LOCK_IMAGE_ANIMATION_STEPS];
	
	NSMutableSet	*toolbarItems;
	
	NSMenu	*_secureMessagingMenu;
}

@end
