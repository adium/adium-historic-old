//
//  JSCEventBezelController.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"

#define EVENT_BEZEL_NIB         @"EventBezel"

@interface JSCEventBezelController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (BOOL)windowShouldClose:(id)sender;
- (void)bezelWillFadeOut:(NSNotification *)note;
@end

@implementation JSCEventBezelController

JSCEventBezelController *sharedEventBezelInstance = nil;

+ (JSCEventBezelController *)eventBezelController
{
    if(!sharedEventBezelInstance) {
        sharedEventBezelInstance = [[self alloc] initWithWindowNibName:EVENT_BEZEL_NIB];
    }
    return(sharedEventBezelInstance);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	NSNotificationCenter	*nc;
    if ([super initWithWindowNibName:windowNibName]) {
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector:@selector(bezelWillFadeOut:)
				   name:@"JSCEventBezelWindowEndTimer"
				object:nil];
		bezelDataQueue = [[NSMutableArray array] retain];
	}
            
    return(self);
}

- (void)dealloc
{
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver: self];
	[bezelDataQueue release];
    [buddyIconLabelColor release];
    [buddyNameLabelColor release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] setBackgroundColor: [NSColor clearColor]];
    [[self window] setLevel: NSStatusWindowLevel];
    [[self window] setIgnoresMouseEvents:NO];
	[[self window] setMovableByWindowBackground:YES];
    [[self window] setAlphaValue:1.0];
    [[self window] setOpaque:NO];
    [[self window] setHasShadow:YES];
	[[self window] setFrameAutosaveName:AUTOFRAME_NAME];
}

- (BOOL)windowShouldClose:(id)sender
{
    [sharedEventBezelInstance autorelease];
    sharedEventBezelInstance = nil;
    
    return(YES);
}

- (void)showBezelWithContact:(NSString *)contactName
withImage:(NSImage *)buddyIcon
forEvent:(NSString *)event
{
    if ([self window]) {
		if ([bezelWindow onScreen]) {
			[bezelDataQueue addObject: contactName];
			[bezelDataQueue addObject: buddyIcon];
			[bezelDataQueue addObject: event];
			[bezelDataQueue addObject: [[self buddyIconLabelColor] copy]];
			[bezelDataQueue addObject: [[self buddyNameLabelColor] copy]];
		} else {
			[bezelView setMainBuddyName: contactName];
			[bezelView setBuddyIconImage: buddyIcon];
			[bezelView setMainBuddyStatus: event];
			[bezelView setBuddyIconLabelColor: [self buddyIconLabelColor]];
			[bezelView setBuddyNameLabelColor: [self buddyNameLabelColor]];
			
			[bezelWindow setDisplayDuration: bezelDuration];
			
			[self showWindow:nil];
			[bezelView setNeedsDisplay: YES];
			[bezelWindow showBezelWindow];
		}
    }
}

- (NSColor *)buddyIconLabelColor
{
    return buddyIconLabelColor;
}

- (void)setBuddyIconLabelColor:(NSColor *)newColor
{
    [newColor retain];
    [buddyIconLabelColor release];
    buddyIconLabelColor = newColor;
}

- (NSColor *)buddyNameLabelColor
{
    return buddyNameLabelColor;
}

- (void)setBuddyNameLabelColor:(NSColor *)newColor
{
    [newColor retain];
    [buddyNameLabelColor release];
    buddyNameLabelColor = newColor;
}

- (int)bezelDuration
{
    return bezelDuration;
}

- (void)setBezelDuration:(int)newDuration
{
    bezelDuration = newDuration;
}

- (void)bezelWillFadeOut:(NSNotification *)note
{
	if ([bezelDataQueue count] > 0) {
		[bezelView setMainBuddyName: [bezelDataQueue objectAtIndex: 0]];
		[bezelView setBuddyIconImage: [bezelDataQueue objectAtIndex: 1]];
		[bezelView setMainBuddyStatus: [bezelDataQueue objectAtIndex: 2]];
		[bezelView setBuddyIconLabelColor: [bezelDataQueue objectAtIndex: 3]];
		[bezelView setBuddyNameLabelColor: [bezelDataQueue objectAtIndex: 4]];
		
		[bezelDataQueue removeObjectsInRange: NSMakeRange(0,5)];
		[bezelView setNeedsDisplay: YES];
		[bezelWindow showBezelWindow];
	} else {
		[bezelWindow endDisplay];
	}
}

@end
