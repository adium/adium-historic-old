//
//  RAFBlockEditorWindow.h
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AIWindowController.h"
#import "AIUtilities/AIAlternatingRowTableView.h"
@class AIListContact, AIAccount, AICompletingTextField, AIAccountMenu;

@interface RAFBlockEditorWindowController : AIWindowController {
	IBOutlet NSWindow			*window;
	IBOutlet NSTableView		*table;

	IBOutlet NSWindow			*sheet;
	IBOutlet NSPopUpButton		*popUp_sheetAccounts;
	IBOutlet AICompletingTextField		*field;
	IBOutlet NSButton			*blockButton;
	IBOutlet NSButton			*cancelButton;
	IBOutlet NSTextField		*accountText;
	IBOutlet NSTextField		*buddyText;
	IBOutlet NSTableColumn		*buddyCol;
	IBOutlet NSTableColumn		*accountCol;
	BOOL						accountColumnsVisible;
	
	IBOutlet NSPopUpButton		*stateChooser;
	IBOutlet NSPopUpButton		*popUp_accounts;
	IBOutlet NSTextField		*accountCaption;
	
	IBOutlet NSTabView			*tabView_contactList;
	
	NSMutableArray				*listContents;
	NSMutableArray				*listContentsAllAccounts;
	NSMutableDictionary			*accountStates;
	
	AIAccountMenu				*accountMenu;
	AIAccountMenu				*sheetAccountMenu;
}

+ (void)showWindow;

- (IBAction)removeSelection:(id)sender;

- (IBAction)runBlockSheet:(id)sender;
- (IBAction)cancelBlockSheet: (id)sender;
- (IBAction)didBlockSheet: (id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSMutableArray*)listContents;
- (void)setListContents:(NSArray*)newList;
- (IBAction)setPrivacyOption:(id)sender;

@end
