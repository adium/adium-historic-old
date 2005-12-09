//
//  AIScriptPreviewView.h
//  Adium
//
//  Created by Colin Barrett on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIXtraPreviewView.h"

@interface AIScriptPreviewView : NSView <AIXtraPreviewView> {
	NSTextView	*readMeView;
}

@end
