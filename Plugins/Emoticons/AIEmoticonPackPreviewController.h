//
//  AIEmoticonPackPreviewController.h
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIEmoticonPackPreviewView, AIEmoticonPreferences, AIEmoticonsPlugin, AIEmoticonPack;

@interface AIEmoticonPackPreviewController : NSObject {
	IBOutlet	NSButton					*checkBox_enablePack;
	IBOutlet	AIEmoticonPackPreviewView	*previewView;

	AIEmoticonPack			*emoticonPack;
	AIEmoticonsPlugin		*plugin;
	AIEmoticonPreferences	*preferences;
}

+ (id)previewControllerForPack:(AIEmoticonPack *)inPack withPlugin:(AIEmoticonsPlugin *)inPlugin preferences:(AIEmoticonPreferences *)inPreferences;
- (IBAction)togglePack:(id)sender;

- (NSView *)view;
- (AIEmoticonPack *)emoticonPack;

@end
