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
	NSData  *autosaveFrame;
    [[self window] setBackgroundColor: [NSColor clearColor]];
    [[self window] setLevel: NSStatusWindowLevel];
	[[self window] setMovableByWindowBackground:YES];
    [[self window] setAlphaValue:1.0];
    [[self window] setOpaque:NO];
	autosaveFrame = [[NSUserDefaults standardUserDefaults] objectForKey: AUTOFRAME_KEY];
	if (!autosaveFrame) {
		NSRect  defaultFrame = [[self window] frame];
		NSSize  mainScreenSize = [[NSScreen mainScreen] frame].size;
		NSPoint mainScreenOrigin = [[NSScreen mainScreen] frame].origin;
		
		defaultFrame.origin.x = mainScreenOrigin.x + (ceil(mainScreenSize.width / 2.0) - ceil(defaultFrame.size.width / 2.0));
		defaultFrame.origin.y = mainScreenOrigin.y + 140.0;
		[[self window] setFrame: defaultFrame display: NO];
	}
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
withMessage:(NSString *)message
ignoringClicks:(BOOL)ignoreClicks
{
    if ([self window]) {
		[bezelWindow setIgnoresMouseEvents:ignoreClicks];
		[bezelView setIgnoringClicks:ignoreClicks];
		if ([bezelWindow onScreen]) {
			[bezelDataQueue addObject: contactName];
			[bezelDataQueue addObject: buddyIcon];
			if (message) {
				[bezelDataQueue addObject: message];
			} else {
				[bezelDataQueue addObject: event];
			}
			[bezelDataQueue addObject: [[self buddyIconLabelColor] copy]];
			[bezelDataQueue addObject: [[self buddyNameLabelColor] copy]];
		} else {
			[bezelView setMainBuddyName: contactName];
			[bezelView setBuddyIconImage: buddyIcon];
			if (message) {
				[bezelView setMainBuddyStatus: message];
			} else {
				[bezelView setMainBuddyStatus: event];
			}
			[bezelView setBuddyIconLabelColor: [self buddyIconLabelColor]];
			[bezelView setBuddyNameLabelColor: [self buddyNameLabelColor]];
			
			[bezelWindow setDisplayDuration: bezelDuration];
			
			[self showWindow:nil];
			[bezelWindow setHasShadow:!ignoreClicks];
			[bezelWindow compatibleInvalidateShadow];
			[bezelWindow setViewsNeedDisplay:YES];
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
