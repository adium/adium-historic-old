//
//  JSCEventBezelController.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"

#define EVENT_BEZEL_NIB         @"EventBezel"

@interface JSCEventBezelController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (BOOL)windowShouldClose:(id)sender;
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
    [super initWithWindowNibName:windowNibName];

    bezelPosition = -1;
            
    return(self);
}

- (void)dealloc
{
    [buddyIconLabelColor release];
    [buddyNameLabelColor release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] setBackgroundColor: [NSColor clearColor]];
    [[self window] setLevel: NSStatusWindowLevel];
    [[self window] setIgnoresMouseEvents:YES];
    [[self window] setAlphaValue:1.0];
    [[self window] setOpaque:NO];
    [[self window] setHasShadow:![NSApp isOnPantherOrBetter]];
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
{
    if ([self window]) {
        
        [bezelWindow setDoFadeIn: [self doFadeIn]];
        [bezelWindow setDoFadeOut: [self doFadeOut]];
        
        [bezelView setBackdropImage: [self backdropImage]];
        
        [bezelView setBuddyIconImage:buddyIcon];
        
        if ([bezelWindow fadingOut] || [bezelWindow fadingIn]) {
            [bezelView setQueueField: [NSString stringWithFormat:@"%@ %@\n%@",
                [bezelView mainBuddyName], [bezelView mainBuddyStatus], [bezelView queueField]]];
            [bezelView setNeedsDisplay:YES];
        } else {
            [bezelView setQueueField: @""];
        }
        
        [bezelView setMainBuddyName: contactName];
        
        BOOL isMessageEvent = [event isEqualToString: AILocalizedString(@"says",nil)];
        if ((!imageBadges) || [event isEqualToString: AILocalizedString(@"is now online",nil)] ||
                [event isEqualToString: AILocalizedString(@"is available",nil)] ||
                [event isEqualToString: AILocalizedString(@"is no longer idle",nil)] || isMessageEvent) {
            [bezelView setBuddyIconBadgeType: @""];
        } else if ([event isEqualToString: AILocalizedString(@"has gone offline",nil)]) {
            [bezelView setBuddyIconBadgeType: @"offline"];
        } else if ([event isEqualToString: AILocalizedString(@"has gone away",nil)]) {
            [bezelView setBuddyIconBadgeType: @"away"];
        } else if ([event isEqualToString: AILocalizedString(@"is idle",nil)]) {
            [bezelView setBuddyIconBadgeType: @"idle"];
        }
        
        if  (isMessageEvent && [self includeText] && message) {
            [bezelView setMainBuddyStatus: [NSString stringWithFormat: @"%@: %@",event, message]];
        } else if (isMessageEvent && ![self includeText] && message) {
            [bezelView setMainBuddyStatus: AILocalizedString(@"new message",nil)];
        } else if (!isMessageEvent && message) {
            [bezelView setMainBuddyStatus: [NSString stringWithFormat: @"%@ \"%@\"",event, message]];
        } else {
            [bezelView setMainBuddyStatus: event];
        }
        
        [bezelView setUseBuddyIconLabel: useBuddyIconLabel];
        [bezelView setUseBuddyNameLabel: useBuddyNameLabel];
        
        [bezelView setBuddyIconLabelColor: [self buddyIconLabelColor]];
        [bezelView setBuddyNameLabelColor: [self buddyNameLabelColor]];
        
        [bezelView setBezelSize: [self bezelSize]];
        
        [bezelWindow setDisplayDuration: bezelDuration];
                
        if ([NSApp isOnPantherOrBetter]) {
            [[self window] invalidateShadow];
        }
        
        if ([NSApp isHidden]) {
            [bezelWindow setAppWasHidden:YES];
            [NSApp unhideWithoutActivation];
        } else {
            [bezelWindow setAppWasHidden:NO];
        }
        
        [[self window] setFrame: bezelFrame display:NO];
        [self showWindow:nil];
        if (![bezelWindow fadingIn]) {
            [bezelWindow showBezelWindow];
        }
        
    }
}

- (int)bezelPosition
{
    return bezelPosition;
}

-(void)setBezelPosition:(int)newPosition
{
    NSSize mainScreenSize;
    NSPoint mainScreenOrigin, newOrigin;
    
    bezelPosition = newPosition;
    mainScreenSize = [[NSScreen mainScreen] frame].size;
    mainScreenOrigin = [[NSScreen mainScreen] frame].origin;
    switch (bezelPosition) {
        case 0: // Default system position
            newOrigin.x = mainScreenOrigin.x + (ceil(mainScreenSize.width / 2.0) - ceil(bezelSize.width / 2.0));
            newOrigin.y = mainScreenOrigin.y + 140.0;
        break;
        case 1: // Top right
            newOrigin.x = mainScreenOrigin.x + mainScreenSize.width - (10 + bezelSize.width);
            newOrigin.y = mainScreenOrigin.y + mainScreenSize.height - (32 + bezelSize.height);
        break; // Bottom right
        case 2:
            newOrigin.x = mainScreenOrigin.x + mainScreenSize.width - (10 + bezelSize.width);
            newOrigin.y = mainScreenOrigin.y + 10;
        break;
        case 3: // Bottom left
            newOrigin.x = mainScreenOrigin.x + 10;
            newOrigin.y = mainScreenOrigin.y + 10;
        break;
        case 4: // Top left
            newOrigin.x = mainScreenOrigin.x + 10;
            newOrigin.y = mainScreenOrigin.y + mainScreenSize.height - (32 + bezelSize.height);
        break;
    }
    bezelFrame.origin = newOrigin;
    bezelFrame.size = bezelSize;
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

- (BOOL)imageBadges
{
    return imageBadges;
}

- (void)setImageBadges:(BOOL)b
{
    imageBadges = b;
}

- (int)bezelDuration
{
    return bezelDuration;
}

- (void)setBezelDuration:(int)newDuration
{
    bezelDuration = newDuration;
}

- (BOOL)useBuddyIconLabel
{
    return useBuddyIconLabel;
}

- (void)setUseBuddyIconLabel:(BOOL)b
{
    useBuddyIconLabel = b;
}

- (BOOL)useBuddyNameLabel
{
    return useBuddyNameLabel;
}

- (void)setUseBuddyNameLabel:(BOOL)b
{
    useBuddyNameLabel = b;
}

- (NSSize)bezelSize
{
    return bezelSize;
}

- (void)setBezelSize:(NSSize)newSize
{
    bezelSize = newSize;
}

- (NSImage *)backdropImage
{
    return backdropImage;
}

- (void)setBackdropImage:(NSImage *)newImage
{
    [newImage retain];
    [backdropImage release];
    backdropImage = newImage;
}

- (BOOL)doFadeOut
{
    return doFadeOut;
}

- (void)setDoFadeOut:(BOOL)b
{
    doFadeOut = b;
}

- (BOOL)doFadeIn
{
    return doFadeIn;
}

- (void)setDoFadeIn:(BOOL)b
{
    doFadeIn = b;
}

- (BOOL)includeText
{
    return includeText;
}

- (void)setIncludeText:(BOOL)b
{
    includeText = b;
}

@end
