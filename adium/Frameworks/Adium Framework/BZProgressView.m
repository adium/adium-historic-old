//
//  BZProgressView.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sat May 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BZProgressView.h"

#define NAME_AND_TYPE_FORMAT @"%2$@: %1$@"
#define STATUS_FORMAT        @"%1$@: %2$@ - %3$.2hf %7$@/%4$.2hf %7$@, %5$.1hf%%, %6$@"
//example: DummyTracker: Money transfer - 50 zorkmids/100 zorkmids, 50.0%, 50 zorkmids/second
#define SPEED_FORMAT         @"%.2hf %@/second"

@implementation BZProgressView

- initWithTracker:(id <BZProgressTracker>)tracker inFrame:(NSRect)frame
{
	self = [self initWithFrame:frame];
	[self setTracker:tracker];

	//create subviews.
	if(self) {
		NSRect ctlFrame = frame;
		ctlFrame.origin.x = ctlFrame.origin.y = PROGRESS_VIEW_GUTTER;
		ctlFrame.size.width  -= PROGRESS_VIEW_GUTTER * 2;
		ctlFrame.size.height  = PROGRESS_VIEW_BAR_HEIGHT;

		progressBar = [[NSProgressIndicator alloc] initWithFrame:ctlFrame];
		[progressBar setControlSize:NSSmallControlSize];
		[progressBar setAutoresizingMask:NSViewWidthSizable];
		[self addSubview:progressBar];

		ctlFrame.size.width  = [progressBar frame].size.width;
		ctlFrame.size.height = PROGRESS_VIEW_FIELD_HEIGHT;
		ctlFrame.origin.y += PROGRESS_VIEW_GUTTER + ctlFrame.size.height;
		float fontSize;
		if([NSApp isOnPantherOrBetter]) {
			fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
		} else {
			fontSize = [NSFont smallSystemFontSize];
		}
		NSFont *font = [NSFont systemFontOfSize:fontSize];
		statusField = [[NSTextField alloc] initWithFrame:ctlFrame];
		[[statusField cell] setControlSize:NSSmallControlSize];
		[statusField setFont:font];
		[statusField setEditable:NO];
		[statusField setDrawsBackground:NO];
		[statusField setBezeled:NO];
		[statusField setBordered:NO];
		[statusField setAutoresizingMask:NSViewWidthSizable];
		[self addSubview:statusField];
		
		[self setAutoresizingMask:NSViewWidthSizable];
	}

	return self;
}
- copyWithZone:(NSZone *)zone
{
	return [self retain];
}
- (void)dealloc
{
	[statusField release];
	[progressBar release];
	[myTracker   release];
	[super dealloc];
}

- (void)setTracker:(id <BZProgressTracker>)tracker
{
	if(tracker == myTracker) return;
	if(myTracker) [myTracker release];
	myTracker = [tracker retain];
}
- (id <BZProgressTracker>)tracker
{
	return myTracker;
}

- (void)update
{
	[self updateWithTracker:myTracker];
}
- (void)updateWithTracker:(id <BZProgressTracker>)tracker
{
	float percent;
	float current = [tracker current];
	float maximum = [tracker maximum];
	percent = 100.0 / (maximum / current);
	NSString *unit = [tracker unit];
	NSString *status = nil;
	NSString *speed = nil;
	enum ProgressState state = [tracker progressState];

	switch(state) {
		case ProgressState_Stopped:
			speed = @"stopped";
			[progressBar stopAnimation:self];
			[progressBar setIndeterminate:NO];
			break;

		case ProgressState_Starting:
			[progressBar startAnimation:self];
		case ProgressState_Stopping:
			status = (state == ProgressState_Starting ? @"Starting" : @"Stopping");
			[progressBar setIndeterminate:YES];
			break;

		case ProgressState_Paused:
			speed = @"paused";
			[progressBar stopAnimation:self];
			goto working_common;
		case ProgressState_Stalled:
			speed = @"stalled";
		case ProgressState_Working:
			[progressBar startAnimation:self];
		working_common:
			if(!speed) speed = [NSString stringWithFormat:SPEED_FORMAT, [tracker speed], unit];
			[progressBar setIndeterminate:NO];
			break;

		default:
			status = @"Unknown status";
			[progressBar setIndeterminate:YES];
			[progressBar startAnimation:self];
	}


	if(!status) {
		status = [NSString stringWithFormat:STATUS_FORMAT, [tracker type], [tracker name], (double)current, (double)maximum, (double)percent, speed, unit];
	}

	[statusField setStringValue:status];
	[progressBar setDoubleValue:percent];
}

+ (float)height
{
	return (PROGRESS_VIEW_GUTTER * 3) + PROGRESS_VIEW_BAR_HEIGHT + PROGRESS_VIEW_FIELD_HEIGHT;
}

@end
