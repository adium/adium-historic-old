//
//  BZProgressView.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sat May 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BZProgressTracker.h"

#define PROGRESS_VIEW_GUTTER        8.0
#define PROGRESS_VIEW_BAR_HEIGHT   14.0
#define PROGRESS_VIEW_FIELD_HEIGHT 14.0

@interface BZProgressView : NSView {
	id <BZProgressTracker>        myTracker;

	IBOutlet NSTextField         *statusField;
	IBOutlet NSProgressIndicator *progressBar;
}

- initWithTracker:(id <BZProgressTracker>)tracker inFrame:(NSRect)frame;

- (void)setTracker:(id <BZProgressTracker>)tracker;
- (id <BZProgressTracker>)tracker;

- (void)update;
- (void)updateWithTracker:(id <BZProgressTracker>)tracker;

+ (float)height;

@end
