//
//  AIEventSoundCustom.h
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAlternatingRowTableView;

@interface AIEventSoundCustom : NSWindowController {
    AIAdium		*owner;

    IBOutlet	AIAlternatingRowTableView	*tableView_sounds;
    IBOutlet	NSPopUpButton			*popUp_addEvent;

    NSMutableArray			*eventSoundArray;
    NSString				*firstSound;
    NSMenu                              *soundMenu_cached;
    int                                 setRow;
}

+ (id)showEventSoundCustomPanelWithOwner:(id)inOwner;
+ (void)closeEventSoundCustomPanel;
- (IBAction)closeWindow:(id)sender;
- (IBAction)newEventSound:(id)sender;

@end
