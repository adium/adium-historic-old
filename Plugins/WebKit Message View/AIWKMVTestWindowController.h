//
//  AIWKMVTestWindowController.h
//  Adium
//
//  Created by David Smith on 10/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIWebKitMessageViewController, ESWebView, AIAdium, AIChat;

@interface AIWKMVTestWindowController : NSWindowController {
	IBOutlet	NSView				*view_previewLocation;
	NSMutableDictionary				*previewListObjectsDict;
	AIWebKitMessageViewController	*previewController;
	ESWebView						*preview;
	NSMutableDictionary				*list;
	AIAdium							*adium;
	AIChat							*previewChat;
	id								plugin;
}

- (IBAction) sendMessage:(id)sender;

@end
