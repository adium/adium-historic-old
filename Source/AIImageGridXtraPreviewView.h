//
//  AIImageGridXtraPreviewView.h
//  Adium
//
//  Created by David Smith on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIImageGridView;

@interface AIImageGridXtraPreviewView : NSView {
	AIImageGridView * gridView;
	NSMutableArray * images;
}

@end
