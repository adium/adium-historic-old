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
	
	IBOutlet	NSTextField				*label_notes;
	IBOutlet	AIDelayedTextField		*contactNotes;

	IBOutlet	NSButton				*button_chooseCard;

	IBOutlet	NSPanel					*addressBookPanel;
	IBOutlet	ABPeoplePickerView		*addressBookPicker;

	IBOutlet	NSTextField				*label_abPeoplePickerChooseAnAddressCard;
	IBOutlet	NSButton				*button_abPeoplePickerOkay;
	IBOutlet	NSButton				*button_abPeoplePickerCancel;
}
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)setNotes:(id)sender;

//Address Book panel methods.
-(IBAction)runABPanel:(id)sender;
-(IBAction)cardSelected:(id)sender;
-(IBAction)cancelABPanel:(id)sender;

@end
