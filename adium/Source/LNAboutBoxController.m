//
//  LNAboutBoxController.m
//  Adium
//
//  Created by Laura Natcher on Fri Oct 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LNAboutBoxController.h"
#import <AIUtilities/AIUtilities.h>


#define ABOUT_BOX_NIB		@"AboutBox"
#define	ADIUM_SITE_LINK		@"http://adium.sourceforge.net/"


@interface LNAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
@end


@implementation LNAboutBoxController


LNAboutBoxController *sharedInstance = nil;


+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner
{

    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB owner:inOwner];
    }
    return(sharedInstance);
}



- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{

    numberOfDuckClicks = 0;

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

    [textField_buildDate setStringValue:[NSString stringWithFormat:@"Build Date: %s", __DATE__]];
    
    [[self window] center];

}


- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


- (BOOL)windowShouldClose:(id)sender
{
 
    [sharedInstance autorelease];
    sharedInstance = nil;

    return(YES);
}

 
- (IBAction)adiumLinkClicked:(id)sender
{
 
    NSURL	*adiumSiteLink;
 
 
    adiumSiteLink = [NSURL URLWithString:[NSString stringWithFormat:ADIUM_SITE_LINK]];
    
    [[NSWorkspace sharedWorkspace] openURL:adiumSiteLink];

}


- (IBAction)adiumDuckClicked:(id)sender
{

    numberOfDuckClicks++;
    if(numberOfDuckClicks == 10){
        [[owner soundController] playSoundNamed:@"/Adium/Feather Ruffle.aif"];
        numberOfDuckClicks = 0;
    }else{
        [[owner soundController] playSoundNamed:@"/Adium/Quack.aif"];
    }
    
}

@end
