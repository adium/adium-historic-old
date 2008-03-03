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

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		//Any additional setup goes here.
	}
	return self;
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
	NSString	*currentAlias;

	//Be sure we've set the last changes before changing which object we are editing
	[contactAlias fireImmediately];
	
	//Hold onto the object, using the highest-up metacontact if necessary
	[displayedObject release];
	displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
				  [(AIListContact *)inObject parentContact] :
				  inObject);
	[displayedObject retain];

	//Fill in the current alias
	if ((currentAlias = [displayedObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES])) {
		[contactAlias setStringValue:currentAlias];
	} else {
		[contactAlias setStringValue:@""];
	}
	
	//Current note
    if ((currentNotes = [displayedObject notes])) {
        [contactNotes setStringValue:currentNotes];
    } else {
        [contactNotes setStringValue:@""];
    }
}

- (IBAction)setAlias:(id)sender
{
	if(!displayedObject)
		return;
	
	NSString *currentAlias = [contactAlias stringValue];
	[displayedObject setDisplayName:currentAlias];
}

- (IBAction)setNotes:(id)sender
{
	if(!displayedObject)
		return;
	
	NSString *currentNote = [contactNotes stringValue];
	[displayedObject setNotes:currentNote];
}

- (void)localizeTitles
{
	[aliasLabel setLocalizedString:AILocalizedString(@"Alias:","Label beside the field for a contact's alias in the settings tab of the Get Infow indow")];
	[notesLabel setLocalizedString:AILocalizedString(@"Notes:","Label beside the field for contact notes in the Settings tab of the Get Info window")];
	//Address book buttons and such go here.
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
