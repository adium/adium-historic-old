//
//  JSCEventBezelController.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelController.h"
#import "AIContactStatusEventsPlugin.h"

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
    if (pantherOrLater) {
        [[self window] setHasShadow:NO];
    } else {
        [[self window] setHasShadow:YES];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    [sharedInstance autorelease];
    sharedInstance = nil;
    
    return(YES);
}

- (void)awakeFromNib
{
    //NSLog(@"despertando controlador");
}

- (void)showBezelWithContact:(AIListContact *)contact forEvent:(NSString *)event withMessage:(NSString *)message
{
    if ([self window]) {
        AIMutableOwnerArray         *ownerArray;
        NSAttributedString          *status = nil;
        NSMutableAttributedString   *statusString;
        
        ownerArray = [contact statusArrayForKey:@"BuddyImage"];
        if(ownerArray && [ownerArray count]) {
            [bezelView setBuddyIconImage:[ownerArray objectAtIndex:0]];
        }else{
            [bezelView setBuddyIconImage:nil];
        }
        
        if ([bezelWindow fadingOut]) {
            [bezelView setQueueField: [NSString stringWithFormat:@"%@ %@ %@\n%@",
                [bezelView mainBuddyName], [bezelView mainBuddyStatus], [bezelView mainAwayMessage], [bezelView queueField]]];
        } else {
            [bezelView setQueueField: @""];
        }
        
        [bezelView setMainBuddyName: [NSString stringWithFormat: @"%@ (%@)",[contact displayName],[contact UID]]];
        
        if ([event isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
            [bezelView setMainBuddyStatus: @"is now online"];
            [bezelView setBuddyIconBadgeType: @""];
        } else if ([event isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
            [bezelView setMainBuddyStatus: @"has gone offline"];
            [bezelView setBuddyIconBadgeType: @"offline"];
        } else if ([event isEqualToString: CONTACT_STATUS_AWAY_YES]) {
            [bezelView setMainBuddyStatus: @"has gone away"];
            [bezelView setBuddyIconBadgeType: @"away"];
        } else if ([event isEqualToString: CONTACT_STATUS_AWAY_NO]) {
            [bezelView setMainBuddyStatus: @"is available"];
            [bezelView setBuddyIconBadgeType: @""];
        } else if ([event isEqualToString: CONTACT_STATUS_IDLE_YES]) {
            [bezelView setMainBuddyStatus: @"is idle"];
            [bezelView setBuddyIconBadgeType: @"idle"];
        } else if ([event isEqualToString: CONTACT_STATUS_IDLE_NO]) {
            [bezelView setMainBuddyStatus: @"is no longer idle"];
            [bezelView setBuddyIconBadgeType: @""];
        }
        
        // This is not working yet, the Plugin class needs to pass the message
        if (message) {
            [bezelView setMainAwayMessage: message];
        } else {
            ownerArray = [contact statusArrayForKey:@"StatusMessage"];
            if(ownerArray && [ownerArray count]) {
                status = [ownerArray objectAtIndex:0];
            }
            if (status) {
                statusString = [[[owner contentController] filteredAttributedString:status] mutableCopy];
                [bezelView setMainAwayMessage: [statusString string]];
            } else {
                [bezelView setMainAwayMessage: @""];
            }
        }
        
        [bezelView setNeedsDisplay:YES];
        // To do: add more placement options using preferences
        if (true) {
            NSSize mainScreenSize;
            NSRect windowSize;
            NSPoint mainScreenOrigin, newOrigin;
            
            mainScreenSize = [[NSScreen mainScreen] frame].size;
            mainScreenOrigin = [[NSScreen mainScreen] frame].origin;
            windowSize = [[self window] frame];
            newOrigin.x = mainScreenOrigin.x + (ceil(mainScreenSize.width / 2.0) - ceil(windowSize.size.width / 2.0));
            newOrigin.y = mainScreenOrigin.y + 140.0;
            [[self window] setFrameOrigin: newOrigin];
        }
        
        if (pantherOrLater) {
            [[self window] invalidateShadow];
        }
        [self showWindow:nil];
        [[self window] orderFront:nil];
        
    }
}

@end
