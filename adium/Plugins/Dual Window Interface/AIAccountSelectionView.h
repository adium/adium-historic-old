//
//  AIAccountSelectionView.h
//  Adium
//
//  Created by Adam Iser on Sat Feb 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAccount, AIListContact;

@protocol AIAccountSelectionViewDelegate
- (void)setAccount:(AIAccount *)inAccount;
- (AIAccount *)account;
- (AIListContact *)contact;
@end

@interface AIAccountSelectionView : NSView {
    AIAdium				*owner;
    
    IBOutlet	NSView			*view_contents;
    IBOutlet	NSPopUpButton		*popUp_accounts;

    id <AIAccountSelectionViewDelegate>	delegate;
}

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate owner:(id)inOwner;
- (void)configureView;
- (void)configureAccountMenu;
- (void)accountListChanged:(NSNotification *)notification;
- (IBAction)selectNewAccount:(id)sender;

@end
