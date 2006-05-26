//
//  RAFBlockEditorWindow.h
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AIWindowController.h"
#import "AIUtilities/AIAlternatingRowTableView.h"
@class AIListContact, AIAccount, AICompletingTextField;

@interface RAFBlockEditorWindowController : AIWindowController {
	IBOutlet NSWindow			*window;
	IBOutlet NSTableView		*table;
	IBOutlet NSButton			*doneButton;

	IBOutlet NSWindow			*sheet;
	IBOutlet NSPopUpButton		*accounts;
	IBOutlet AICompletingTextField		*field;
	IBOutlet NSButton			*blockButton;
	IBOutlet NSButton			*cancelButton;
	IBOutlet NSTextField		*accountText;
	IBOutlet NSTextField		*buddyText;
	IBOutlet NSTableColumn		*buddyCol;
	IBOutlet NSTableColumn		*accountCol;
	
	IBOutlet NSPopUpButton		*stateChooser;
	IBOutlet NSPopUpButton		*mainAccounts;
	IBOutlet NSTextField		*accountCaption;
	
	NSMutableArray				*listContents;
	NSMutableArray				*listContentsAllAccounts;
	NSMutableDictionary			*accountStates;
}

+ (void)showWindow;
- (IBAction)configTextField:(id)sender;
- (IBAction)runBlockSheet:(id)sender;
- (IBAction)cancelBlockSheet: (id)sender;
- (IBAction)didBlockSheet: (id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)blockFieldUID:(id)sender;
- (NSMutableArray*)listContents;
- (void)setListContents:(NSArray*)newList;
- (AIListContact *)contactFromTextField;
- (IBAction)setState:(id)sender;
- (IBAction)setAccount:(id)sender;
- (void)recomputeListContents;
@end
