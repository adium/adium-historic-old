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
#define InfoIndentA			75
#define InfoIndentB			80
#define REFRESH_RATE                    300

@implementation AIInfoWindowController

//Open a new info window
static AIInfoWindowController *sharedInstance = nil;
+ (id)showInfoWindowWithOwner:(id)inOwner forContact:(AIListContact *)inContact
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:INFO_WINDOW_NIB owner:inOwner];
    }

    if([inContact isKindOfClass:[AIListContact class]]){ //Only allow this for contacts
        //Let everyone know we want profile information
        [[inOwner notificationCenter] postNotificationName:Contact_UpdateStatus object:inContact userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:@"TextProfile", @"StatusMessage", nil] forKey:@"Keys"]];
    
        //Show the window and configure it for the contact
        [sharedInstance configureWindowForContact:inContact];
        
        [sharedInstance showWindow:nil];
    }
        
    return(sharedInstance);
}

//Close the profile window
+ (void)closeTextProfileWindow
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

- (void)refresh:(NSTimer *)timer
{
    //Show the window and configure it for the contact
    [sharedInstance configureWindowForContact:activeContactObject];
}

//Called as profiles are set on a handle, update our display
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    //If we're currently displaying this handle, and it's profile or other displayed information changed...
    if(inObject == activeContactObject/* && [inModifiedKeys containsObject:@"TextProfile"]*/){
        [self configureWindowForContact:(AIListContact *)inObject];
    }

    return(nil); //We've modified no display attributes, return nil
}

//Configure the profile window for the specified contact
- (void)configureWindowForContact:(AIListContact *)inContact
{
    NSMutableAttributedString	*infoString;
    NSDictionary		*labelAttributes, *valueAttributes, *bigValueAttributes;
    NSMutableParagraphStyle	*paragraphStyle;
    AIMutableOwnerArray		*ownerArray;
    NSTextAttachmentCell 	*imageAttatchment;
    NSTextAttachment 		*attatchment;
    NSImage 			*buddyImage;
    
    //Make sure our window is loaded
    [self window];

    //Remember who we're displaying info for
    [activeContactObject release]; activeContactObject = [inContact retain];

    if (timer) 
        [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_RATE target:self selector:@selector(refresh:) userInfo:nil repeats:NO];
    
    
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
    [paragraphStyle setHeadIndent:InfoIndentB];

    //Prepare the text attributes we will use
    labelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:11], NSFontAttributeName,
        [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], NSForegroundColorAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName, 
        nil];
    valueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:11], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];
    bigValueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:16], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];
    
    //Buddy Icon
    ownerArray = [inContact statusArrayForKey:@"BuddyImage"];
    if(ownerArray && [ownerArray count]){
        buddyImage = [ownerArray objectAtIndex:0];
    }else{
        buddyImage = [AIImageUtilities imageNamed:@"DefaultIcon" forClass:[self class]];
    }
    
    imageAttatchment = [[[NSTextAttachmentCell alloc] initImageCell:buddyImage] autorelease];
    attatchment = [[[NSTextAttachment alloc] init] autorelease];
    [attatchment setAttachmentCell:imageAttatchment];

    [infoString appendString:@"\r\t" withAttributes:labelAttributes];
    [infoString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attatchment]];
    
    //Display Name
    //    ownerArray = [inContact statusArrayForKey:@"Display Name"];
    //    if(ownerArray && [ownerArray count]){
    [infoString appendString:@"\t" withAttributes:labelAttributes];
    [infoString appendString:/*[ownerArray objectAtIndex:0]*/[inContact displayName] withAttributes:bigValueAttributes];
    //    }
    
    //Client
    ownerArray = [inContact statusArrayForKey:@"Client"];
    if(ownerArray && [ownerArray count]){
        [infoString appendString:@"\r\r\tClient:\t" withAttributes:labelAttributes];
        [infoString appendString:[ownerArray objectAtIndex:0] withAttributes:valueAttributes];
    }
    
    //Signon Date
    NSDate *signonDate = [[inContact statusArrayForKey:@"Signon Date"] earliestDate];
    if(signonDate){
        //        [infoString appendString:@"\r\r\tOnline Since:\t" withAttributes:labelAttributes];
        //        [infoString appendString:[signonDate description] withAttributes:valueAttributes];
        [infoString appendString:@"\r\r\tOnline For:\t" withAttributes:labelAttributes];
        double seconds = [[NSDate date] timeIntervalSinceDate:signonDate];
        int days = 0, hours = 0, minutes = 0; 
        days = (int)(seconds / 86400);
        seconds -= days * 86400;
        if (seconds) {
            hours = (int)(seconds / 3600);
            seconds -= hours * 3600;
        }
        if (seconds) {
            minutes = (int)(seconds / 60);
            seconds -= minutes * 60;
        }
        if (days)
            [infoString appendString:[NSString stringWithFormat:@"%i day%@ ",days,days==1 ? @"":@"s"]  withAttributes:valueAttributes];
        if (hours)
            [infoString appendString:[NSString stringWithFormat:@"%i hour%@ ",hours,hours==1 ? @"":@"s"]  withAttributes:valueAttributes];
        if (minutes)
            [infoString appendString:[NSString stringWithFormat:@"%i minute%@ ",minutes,minutes==1 ? @"":@"s"]  withAttributes:valueAttributes];
        if (seconds)
            [infoString appendString:[NSString stringWithFormat:@"%i second%@ ",(int)seconds,seconds==1 ? @"":@"s"]  withAttributes:valueAttributes];
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
            [infoString appendString:@"\r\r\tAway:\t" withAttributes:labelAttributes];
        }else{
            [infoString appendString:@"\r\r\tStatus:\t" withAttributes:labelAttributes];
        }
        
        [infoString appendString:(status != nil ? [status string] : @"Yes") withAttributes:valueAttributes];
    }
    
    //Idle Since
    int idle = (int)[[inContact statusArrayForKey:@"Idle"] greatestDoubleValue];
    if(idle != 0){
        int	hours = (int)(idle / 60);
        int	minutes = (int)(idle % 60);

        [infoString appendString:@"\r\r\tIdle:\t" withAttributes:labelAttributes];

        if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
            [infoString appendString:@"Yes" withAttributes:valueAttributes];

        }else{
            if(hours){
                [infoString appendString:[NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")]
                          withAttributes:valueAttributes];
            }else{
                [infoString appendString:[NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")]
                          withAttributes:valueAttributes];
            }
        }
    }

    //Warning
    int warning = [[inContact statusArrayForKey:@"Warning"] greatestIntegerValue];
    if(warning > 0){
        [infoString appendString:@"\r\r\tWarning:\t" withAttributes:labelAttributes];
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
        [infoString appendString:@"\r\r\tProfile:\t" withAttributes:labelAttributes];
        [infoString appendAttributedString:textProfile];
    }

    //
    [self displayInfo:infoString];
    
}

//Displays the attributed string in the profile view.  Pass nil for no profile
- (void)displayInfo:(NSAttributedString *)infoString
{
    if(infoString && [infoString length]){
        NSColor	*backgroundColor;

        //Display the string
        [[textView_contactProfile textStorage] setAttributedString:infoString];
        [textView_contactProfile resetCursorRects]; //Why must I call this manually?

        //Set the background color
        backgroundColor = [infoString attribute:AIBodyColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0,[infoString length])];
        [textView_contactProfile setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];

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
    timer = nil;
    
    //Register ourself as a handle observer
    [[owner contactController] registerListObjectObserver:self];

    return(self);
}

//
- (void)dealloc
{
    [owner release];
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

    //
    [textView_contactProfile setEditable:NO];
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

    //Stop observing, and release the shared instance
    [[owner contactController] unregisterListObjectObserver:self];
    if (timer) {
        [timer invalidate];
        timer = nil;
    }

    [sharedInstance autorelease]; sharedInstance = nil;
    
    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end
