//
//  AITextProfileWindowController.h
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class AIListContact;
@protocol AIListObjectObserver;

@interface AIInfoWindowController : AIWindowController <AIListObjectObserver> {
    IBOutlet	NSTextView	*textView_contactProfile;

    AIListContact	*activeContactObject;
    NSTimer             *timer;
}

+ (id)showInfoWindowForContact:(AIListObject *)inContact;
+ (void)closeTextProfileWindow;
- (void)configureWindowForContact:(AIListContact *)inContact;
- (void)displayInfo:(NSAttributedString *)infoString;
- (IBAction)closeWindow:(id)sender;

@end
