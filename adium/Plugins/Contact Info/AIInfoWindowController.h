//
//  AITextProfileWindowController.h
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIListContact;
@protocol AIListObjectObserver;

@interface AIInfoWindowController : NSWindowController <AIListObjectObserver> {
    IBOutlet	NSTextView	*textView_contactProfile;

    AIAdium		*owner;

    AIListContact	*activeContactObject;
    
}

+ (id)showInfoWindowWithOwner:(id)inOwner forContact:(AIListContact *)inContact;
+ (void)closeTextProfileWindow;
- (void)configureWindowForContact:(AIListContact *)inContact;
- (void)displayInfo:(NSAttributedString *)infoString;
- (IBAction)closeWindow:(id)sender;

@end
