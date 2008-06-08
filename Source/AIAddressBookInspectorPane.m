//
//  AIAddressBookInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIAddressBookInspectorPane.h"

#define ADDRESS_BOOK_NIB_NAME (@"AIAddressBookInspectorPane")

@implementation AIAddressBookInspectorPane

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		[notesLabel setLocalizedString:AILocalizedString(@"Notes:", "Label beside the field for contact notes in the Settings tab of the Get Info window")];
		[addressBookButton setLocalizedString:AILocalizedStringFromTable(@"Choose Card", @"Buttons", "Button title to choose an Address Book card for a contact")];
	}

	return self;
}

- (void)dealloc
{
	[inspectorContentView release]; inspectorContentView = nil;
	[addressBookPanel release]; addressBookPanel = nil;
	
	[super dealloc];
}

-(NSString *)nibName
{
	return ADDRESS_BOOK_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	NSString	*currentNotes;

	//Hold onto the object, using the highest-up metacontact if necessary
	[displayedObject release];
	displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
				  [(AIListContact *)inObject parentContact] :
				  inObject);
	[displayedObject retain];

	//Current note
    if ((currentNotes = [displayedObject notes])) {
        [contactNotes setStringValue:currentNotes];
    } else {
        [contactNotes setStringValue:@""];
    }
}

- (IBAction)setNotes:(id)sender
{
	if(!displayedObject)
		return;
	
	NSString *currentNote = [contactNotes stringValue];
	[displayedObject setNotes:currentNote];
}

//Address Book Panel methods.
-(IBAction)runABPanel:(id)sender
{
	[NSApp beginSheet:addressBookPanel
	   modalForWindow:[inspectorContentView window]
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) 
		  contextInfo:nil];
}

-(IBAction)cardSelected:(id)sender
{
	//This method will be different during Adium integration, until then we simply print out some details about the ABPerson
	//that has been selected. Pretty simple.
#warning Needs completion before 1.3
	NSArray *selectedCards = [addressBookPicker selectedRecords];
	NSLog(@"%@", selectedCards);
	[NSApp endSheet:addressBookPanel];	
}

-(IBAction)cancelABPanel:(id)sender
{
	//This method simply ends the panel when the user clicks cancel.
	[NSApp endSheet:addressBookPanel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [addressBookPanel orderOut:self];
}


@end
