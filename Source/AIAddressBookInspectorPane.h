//
//  AIAddressBookInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <AIContactInfoContentController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIDelayedTextField.h>

@interface AIAddressBookInspectorPane : AIObject <AIContentInspectorPane> {
	IBOutlet	NSView					*inspectorContentView;
				AIListObject			*displayedObject;
	
	IBOutlet	NSTextField				*aliasLabel;
	IBOutlet	AIDelayedTextField		*contactAlias;
	
	IBOutlet	NSTextField				*notesLabel;
	IBOutlet	AIDelayedTextField		*contactNotes;
	
	IBOutlet	NSButton				*addressBookButton;
	IBOutlet	NSPanel					*addressBookPanel;
	IBOutlet	ABPeoplePickerView		*addressBookPicker;
}
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)setAlias:(id)sender;
- (IBAction)setNotes:(id)sender;

//Address Book panel methods.
-(IBAction)runABPanel:(id)sender;
-(IBAction)cardSelected:(id)sender;
-(IBAction)cancelABPanel:(id)sender;

@end
