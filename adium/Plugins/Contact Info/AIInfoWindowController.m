//
//  AITextProfileWindowController.m
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIInfoWindowController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define KEY_TEXT_PROFILE_WINDOW_FRAME	@"Text Profile Window"
#define INFO_WINDOW_NIB			@"ContactInfo"
#define InfoIndentA	75
#define InfoIndentB	80


@implementation AIInfoWindowController

//Open a new info window
static AIInfoWindowController *sharedInstance = nil;
+ (id)showInfoWindowWithOwner:(id)inOwner forContact:(AIListContact *)inContact
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:INFO_WINDOW_NIB owner:inOwner];
    }

    //Let everyone know we want profile information
    [[inOwner notificationCenter] postNotificationName:Contact_UpdateStatus object:inContact userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"TextProfile"] forKey:@"Keys"]];

    //Show the window and configure it for the contact
    [sharedInstance configureWindowForContact:inContact];
    [sharedInstance showWindow:nil];

    return(sharedInstance);
}

//Close the profile window
+ (void)closeTextProfileWindow
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Called as profiles are set on a handle, update our display
- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    //If we're currently displaying this handle, and it's profile or other displayed information changed...
    if(inContact == activeContactObject/* && [inModifiedKeys containsObject:@"TextProfile"]*/){
        [self configureWindowForContact:inContact];
    }

    return(nil); //We've modified no display attributes, return nil
}

//Configure the profile window for the specified contact
- (void)configureWindowForContact:(AIListContact *)inContact
{
    NSMutableAttributedString	*infoString;
    NSDictionary		*labelAttributes, *valueAttributes;
    NSMutableParagraphStyle	*paragraphStyle;
    AIMutableOwnerArray		*ownerArray;

    //Make sure our window is loaded
    [self window];

    //Remember who we're displaying info for
    [activeContactObject release]; activeContactObject = [inContact retain];

    //Set window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@'s Info",[activeContactObject displayName]]];
    
    //Build the info text
    infoString = [[NSMutableAttributedString alloc] init];

    //Create an paragraph style with the correct tabbing and indents
    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setTabStops:[NSArray arrayWithObjects:
        [[[NSTextTab alloc] initWithType:NSRightTabStopType location:InfoIndentA] autorelease],
        [[[NSTextTab alloc] initWithType:NSLeftTabStopType location:InfoIndentB] autorelease],
        nil]];
    [paragraphStyle setHeadIndent:75];

    //Prepare the text attributes we will use
        labelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:11], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName, 
        nil];
    valueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:11], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];

    //Buddy Icon
    ownerArray = [inContact statusArrayForKey:@"BuddyImage"];
    if(ownerArray && [ownerArray count]){
        NSImage 		*buddyImage = [ownerArray objectAtIndex:0];
        NSTextAttachmentCell 	*imageAttatchment;
        NSTextAttachment 	*attatchment;

        imageAttatchment = [[[NSTextAttachmentCell alloc] initImageCell:buddyImage] autorelease];
        attatchment = [[[NSTextAttachment alloc] init] autorelease];
        [attatchment setAttachmentCell:imageAttatchment];

        [infoString appendString:@"\r\tBuddy Icon:\t" withAttributes:labelAttributes];
        [infoString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attatchment]];
    }

    //Display Name
    ownerArray = [inContact statusArrayForKey:@"Display Name"];
    if(ownerArray && [ownerArray count]){
        [infoString appendString:@"\r\tUser Name:\t" withAttributes:labelAttributes];
        [infoString appendString:[ownerArray objectAtIndex:0] withAttributes:valueAttributes];
    }

    //Client
    ownerArray = [inContact statusArrayForKey:@"Client"];
    if(ownerArray && [ownerArray count]){
        [infoString appendString:@"\r\tClient:\t" withAttributes:labelAttributes];
        [infoString appendString:[ownerArray objectAtIndex:0] withAttributes:valueAttributes];
    }

    //Signon Date
    NSDate *signonDate = [[inContact statusArrayForKey:@"Signon Date"] earliestDate];
    if(signonDate){
        [infoString appendString:@"\r\tOnline Since:\t" withAttributes:labelAttributes];
        [infoString appendString:[signonDate description] withAttributes:valueAttributes];
    }
    
    //Online
/*    int online = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
    [infoString appendString:@"\r\tOnline:\t" withAttributes:labelAttributes];
    [infoString appendString:(online ? @"Yes" : @"No") withAttributes:valueAttributes];*/

    //Away & Status
    NSAttributedString *status = nil;
    int away = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
    ownerArray = [inContact statusArrayForKey:@"StatusMessage"];

    if(ownerArray && [ownerArray count]){
        status = [ownerArray objectAtIndex:0];
    }

    if(status || away){ //If away or w/ status message
        if(away){
            [infoString appendString:@"\r\tAway:\t" withAttributes:labelAttributes];
        }else{
            [infoString appendString:@"\r\tStatus:\t" withAttributes:labelAttributes];
        }

        [infoString appendString:(status != nil ? [status string] : @"Yes") withAttributes:valueAttributes];
    }

    //Idle Since
    int idle = (int)[[inContact statusArrayForKey:@"Idle"] greatestDoubleValue];
    if(idle != 0){
        int	hours = (int)(idle / 60);
        int	minutes = (int)(idle % 60);

        [infoString appendString:@"\r\tIdle:\t" withAttributes:labelAttributes];
        if(hours){
            [infoString appendString:[NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")]
                      withAttributes:valueAttributes];
        }else{
            [infoString appendString:[NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")]
                      withAttributes:valueAttributes];
        }
    }

    //Warning
    int warning = [[inContact statusArrayForKey:@"Warning"] greatestIntegerValue];
    if(warning > 0){
        [infoString appendString:@"\r\tWarning:\t" withAttributes:labelAttributes];
        [infoString appendString:[NSString stringWithFormat:@"%i%%",warning] withAttributes:valueAttributes];
    }

    //Text Profile
    ownerArray = [inContact statusArrayForKey:@"TextProfile"];
    if(ownerArray && [ownerArray count]){
        NSMutableParagraphStyle		*indentStyle;
        NSMutableAttributedString 	*textProfile = [[ownerArray objectAtIndex:0] mutableCopy];
        NSRange				firstLineRange = [[textProfile string] lineRangeForRange:NSMakeRange(0,0)];

        //Set correct indent & tabbing on the first line of the profile
        [textProfile addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,firstLineRange.length)];

        //Indent the remaining lines of profile
        indentStyle = [paragraphStyle mutableCopy];
        [indentStyle setFirstLineHeadIndent:InfoIndentB];
        [textProfile addAttribute:NSParagraphStyleAttributeName value:indentStyle range:NSMakeRange(firstLineRange.length, [textProfile length] - firstLineRange.length)];

        //
        [infoString appendString:@"\r\tProfile:\t" withAttributes:labelAttributes];
        [infoString appendAttributedString:textProfile];
    }

    //
    [self displayInfo:infoString];
}

//Displays the attributed string in the profile view.  Pass nil for no profile
- (void)displayInfo:(NSAttributedString *)infoString
{
    if(infoString){
        NSColor	*backgroundColor;

        //Display the string
        [textView_contactProfile setString:@""];
        [[textView_contactProfile textStorage] setAttributedString:infoString];

        //Set the background color
        backgroundColor = [infoString attribute:AIBodyColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0,[infoString length])];
        [textView_contactProfile setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];

    }else{
        //Remove any existing profile
        [textView_contactProfile setString:@""];

        //Set background back to white
        [textView_contactProfile setBackgroundColor:[NSColor whiteColor]];

    }

    [textView_contactProfile setNeedsDisplay:YES];
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    //init
    owner = [inOwner retain];

    //Register ourself as a handle observer
    [[owner contactController] registerContactObserver:self];

    return(self);
}

//
- (void)dealloc
{
    [owner release];
    [[owner contactController] unregisterContactObserver:self];
    [activeContactObject release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_TEXT_PROFILE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_TEXT_PROFILE_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end
