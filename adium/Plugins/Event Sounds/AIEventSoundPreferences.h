//
//  AIEventSoundPrefs.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAlternatingRowTableView, AIEventSoundsPlugin;

@interface AIEventSoundPreferences : NSObject {
    AIAdium				*owner;
    AIEventSoundsPlugin			*plugin;

    IBOutlet	NSView				*view_prefView;
    IBOutlet	AIAlternatingRowTableView	*tableView_sounds;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSPopUpButton			*popUp_soundSet;
    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	NSTextField			*textField_creator;

    IBOutlet	NSButton			*button_soundSetInfo;
    
    NSMutableArray			*eventSoundArray;
    BOOL				usingCustomSoundSet;
}

+ (AIEventSoundPreferences *)eventSoundPreferencesWithOwner:(id)inOwner forPlugin:(id)inPlugin;
- (IBAction)selectSoundSet:(id)sender;
- (IBAction)deleteEventSound:(id)sender;
- (IBAction)playSelectedSound:(id)sender;
- (IBAction)selectSound:(id)sender;
- (IBAction)newEventSound:(id)sender;
- (IBAction)showSoundSetInfo:(id)sender;

@end
