//
//  AITextProfileWindowController.h
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@protocol AIListObjectObserver;

@interface AIInfoWindowController : AIWindowController <AIListObjectObserver> {
    IBOutlet	NSTextView	*textView_contactProfile;

    AIListObject			*activeListObject;
    NSTimer             	*timer;
}

+ (id)showInfoWindow;
+ (void)closeTextProfileWindow;
- (void)configureWindowForListObject:(AIListObject *)inObject;
- (void)displayInfo:(NSAttributedString *)infoString;
- (IBAction)closeWindow:(id)sender;

@end
