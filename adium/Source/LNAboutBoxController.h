//
//  LNAboutBoxController.h
//  Adium
//
//  Created by Laura Natcher on Fri Oct 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>


@interface LNAboutBoxController : NSWindowController {

    IBOutlet	NSButton	*button_duckIcon;
    IBOutlet	NSTextField	*textField_buildDate;
    IBOutlet	NSButton	*button_siteLink;


    AIAdium		*owner;
    int			numberOfDuckClicks;

}


+ (LNAboutBoxController *)aboutBoxControllerForOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;
- (IBAction)adiumLinkClicked:(id)sender;
- (IBAction)adiumDuckClicked:(id)sender;


@end
