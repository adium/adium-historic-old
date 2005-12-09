//
//  AIScriptPreviewView.m
//  Adium
//
//  Created by Colin Barrett on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIScriptPreviewView.h"

@implementation AIScriptPreviewView

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		readMeView = [[NSTextView alloc] initWithFrame:frame];
		[readMeView setEditable:NO];
		[self addSubview:readMeView];
    }
    return self;
}

- (void)setXtra:(AIXtraInfo *)xtraInfo
{
	//Load the readme and set it.
	NSAttributedString *readMeString = [[NSAttributedString alloc] initWithPath:[xtraInfo readMePath] documentAttributes:NULL];
	[[readMeView textStorage] setAttributedString:readMeString];
	
	//Clean up
	[readMeString release];
}

- (void)dealloc
{
	[readMeView release];
	[super dealloc];
}

@end
