//
//  RAFBlockEditorWindow.h
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
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
	
	NSMutableArray				*listContents;
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
- (AIListContact *)contactFromText:(NSString *)text onAccount:(AIAccount *)account;
@end
