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
    [[self window] setHasShadow:YES];
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
        NSAttributedString      *tempString;
        AIMutableOwnerArray     *ownerArray;
        
        if ([bezelWindow fadingOut]) {
            [queueField setStringValue: [NSString stringWithFormat:@"%@ %@ %@\n%@",
                [mainName stringValue], [mainStatus stringValue], [mainAwayMessage stringValue], [queueField stringValue]]];
        } else {
            [queueField setStringValue: @""];
        }
        
        tempString = [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@ (%@)",[contact displayName],[contact UID]]
                attributes: [NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager]
                    convertFont:[NSFont systemFontOfSize:0.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, nil]] autorelease];
        [mainName setAttributedStringValue: tempString];
        
        ownerArray = [contact statusArrayForKey:@"BuddyImage"];
        if(ownerArray && [ownerArray count]){
            [bezelView setBuddyIconImage:[ownerArray objectAtIndex:0]];
        }else{
            [bezelView setBuddyIconImage:nil];
        }
        
        if ([event isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
            [mainStatus setStringValue:@"is now online"];
        } else if ([event isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
            [mainStatus setStringValue:@"has gone offline"];
        } else if ([event isEqualToString: CONTACT_STATUS_AWAY_YES]) {
            [mainStatus setStringValue:@"has gone away"];
        } else if ([event isEqualToString: CONTACT_STATUS_AWAY_NO]) {
            [mainStatus setStringValue:@"is available"];
        } else if ([event isEqualToString: CONTACT_STATUS_IDLE_YES]) {
            [mainStatus setStringValue:@"is idle"];
        } else if ([event isEqualToString: CONTACT_STATUS_IDLE_NO]) {
            [mainStatus setStringValue:@"no longer is idle"];
        }
        
        if (message) {
            [mainAwayMessage setStringValue: message];
        } else {
            [mainAwayMessage setStringValue: @""];
        }
        
        // To do: correct bezel position and more options using preferences
        [[self window] center];
        [self showWindow:nil];
        [[self window] invalidateShadow];
        [[self window] orderFront:nil];
        
    }
}

@end
