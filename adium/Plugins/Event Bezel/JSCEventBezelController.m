//
//  JSCEventBezelController.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"

#define EVENT_BEZEL_NIB         @"EventBezel"

BOOL pantherOrLater;

@interface JSCEventBezelController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation JSCEventBezelController

JSCEventBezelController *sharedInstance = nil;

+ (JSCEventBezelController *)eventBezelControllerForOwner:(id)inOwner
{
    if(!sharedInstance) {
        sharedInstance = [[self alloc] initWithWindowNibName:EVENT_BEZEL_NIB owner:inOwner];
    }
    return(sharedInstance);
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];
    
    owner = [inOwner retain];
    
    pantherOrLater = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2);
    
    bezelPosition = -1;
            
    return(self);
}

- (void)dealloc
{
    [owner release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] setBackgroundColor: [NSColor clearColor]];
    [[self window] setLevel: NSStatusWindowLevel];
    [[self window] setIgnoresMouseEvents:YES];
    [[self window] setAlphaValue:1.0];
    [[self window] setOpaque:NO];
    [[self window] setHasShadow:!pantherOrLater];
}

- (BOOL)windowShouldClose:(id)sender
{
    [sharedInstance autorelease];
    sharedInstance = nil;
    
    return(YES);
}

- (void)showBezelWithContact:(NSString *)contactName
withImage:(NSImage *)buddyIcon
forEvent:(NSString *)event
withMessage:(NSString *)message
{
    if ([self window]) {
        [bezelView setBuddyIconImage:buddyIcon];
        
        if ([bezelWindow fadingOut]) {
            [bezelView setQueueField: [NSString stringWithFormat:@"%@ %@\n%@",
                [bezelView mainBuddyName], [bezelView mainBuddyStatus], [bezelView queueField]]];
        } else {
            [bezelView setQueueField: @""];
        }
        
        [bezelView setMainBuddyName: contactName];
        
        if ((!imageBadges) || [event isEqualToString: @"is now online"] || [event isEqualToString: @"is available"] ||
                [event isEqualToString: @"is no longer idle"] || [event isEqualToString: @"says"]) {
            [bezelView setBuddyIconBadgeType: @""];
        } else if ([event isEqualToString: @"has gone offline"]) {
            [bezelView setBuddyIconBadgeType: @"offline"];
        } else if ([event isEqualToString: @"has gone away"]) {
            [bezelView setBuddyIconBadgeType: @"away"];
        } else if ([event isEqualToString: @"is idle"]) {
            [bezelView setBuddyIconBadgeType: @"idle"];
        }
        [bezelView setMainBuddyStatus: event];
        
        if (message) {
            [bezelView setMainBuddyStatus: [NSString stringWithFormat: @"%@: %@",[bezelView mainBuddyStatus], message]];
        }
        [bezelView setUseBuddyIconLabel: useBuddyIconLabel];
        [bezelView setUseBuddyNameLabel: useBuddyNameLabel];
        
        [bezelWindow setDisplayDuration: bezelDuration];
        
        [bezelView setNeedsDisplay:YES];
        
        if (pantherOrLater) {
            [[self window] invalidateShadow];
        }
        [self showWindow:nil];
        [[self window] orderFront:nil];
        
    }
}

- (int)bezelPosition
{
    return bezelPosition;
}

-(void)setBezelPosition:(int)newPosition
{
    bezelPosition = newPosition;
    if ([self window]) {
        NSSize mainScreenSize;
        NSRect windowSize;
        NSPoint mainScreenOrigin, newOrigin;
        
        mainScreenSize = [[NSScreen mainScreen] frame].size;
        mainScreenOrigin = [[NSScreen mainScreen] frame].origin;
        windowSize = [[self window] frame];
        switch (bezelPosition) {
            case 0:
                newOrigin.x = mainScreenOrigin.x + (ceil(mainScreenSize.width / 2.0) - ceil(windowSize.size.width / 2.0));
                newOrigin.y = mainScreenOrigin.y + 140.0;
            break;
            case 1:
                newOrigin.x = mainScreenOrigin.x + mainScreenSize.width - (10 + windowSize.size.width);
                newOrigin.y = mainScreenOrigin.y + mainScreenSize.height - (32 + windowSize.size.height);
            break;
            case 2:
                newOrigin.x = mainScreenOrigin.x + mainScreenSize.width - (10 + windowSize.size.width);
                newOrigin.y = mainScreenOrigin.y + 10;
            break;
            case 3:
                newOrigin.x = mainScreenOrigin.x + 10;
                newOrigin.y = mainScreenOrigin.y + 10;
            break;
            case 4:
                newOrigin.x = mainScreenOrigin.x + 10;
                newOrigin.y = mainScreenOrigin.y + mainScreenSize.height - (32 + windowSize.size.height);
            break;
        }
        [[self window] setFrameOrigin: newOrigin];
    }
}

- (void)setBuddyIconLabelColor:(NSColor *)newColor
{
    [bezelView setBuddyIconLabelColor: newColor];
}

- (void)setBuddyNameLabelColor:(NSColor *)newColor
{
    [bezelView setBuddyNameLabelColor: newColor];
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

@end
