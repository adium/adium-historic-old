//
//  AIEmoticonPackPreviewView.h
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIEmoticonPack;

@interface AIEmoticonPackPreviewView : NSView {
	IBOutlet	NSView	*view_preview;
	IBOutlet	NSView	*view_name;

	AIEmoticonPack		*emoticonPack;	
}

- (void)setEmoticonPack:(AIEmoticonPack *)inEmoticonPack;

@end
