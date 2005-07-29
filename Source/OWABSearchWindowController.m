//
//  OWABSearchWindowController.m
//  Adium
//
//  Created by Ofri Wolfus on 19/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "OWABSearchWindowController.h"
#import <Adium/AIAccountController.h>
#import <Adium/AIService.h>
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABPeoplePickerView.h>
#import <AddressBook/ABPerson.h>

#define AB_SEARCH_NIB	@"ABSearch"

#define AIMServiceUniqueID		@"libgaim-oscar-AIM"
#define ICQServiceUniqueID		@"libgaim-oscar-ICQ"
#define MSNServiceUniqueID		@"libgaim-MSN"
#define DotMacServiceUniqueID	@"libgaim-oscar-Mac"
#define JabberServiceUniqueID	@"libgaim-Jabber"
#define YahooServiceUniqueID	@"libgaim-Yahoo!"

@interface OWABSearchWindowController (private)
- (void)_configurePeoplePicker;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (AIService *)serviceFromProperty:(NSString *)property;
- (NSString *)propertyFromService:(AIService *)service;
@end


/*!
* @class OWABSearchWindowController
 * @brief Window controller for searching people in the Address Book database.
 */
@implementation OWABSearchWindowController

/*!
* @brief Prompt for searching a person within the AB database.
 *
 * @param parentWindow Window on which to show the prompt as a sheet. Pass nil for a panel prompt.
 */
+ (id)promptForNewPersonSearchOnWindow:(NSWindow *)parentWindow
{
	OWABSearchWindowController *newABSearchWindow;
	
	newABSearchWindow = [[self alloc] initWithWindowNibName:AB_SEARCH_NIB];
	
	if (parentWindow) {
		[NSApp beginSheet:[newABSearchWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newABSearchWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[newABSearchWindow showWindow:nil];
	}
	
	return [newABSearchWindow autorelease];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[self setDelegate:nil];
	[super dealloc];
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	[[self window] center];
	[self _configurePeoplePicker];
}

/*!
 * @brief Setup our ABPeoplePickerView
 */
- (void)_configurePeoplePicker
{
	NSTextField		*accessoryView = [[[NSTextField alloc] init] autorelease];
	NSEnumerator	*servicesEnumerator = [[[adium accountController] activeServices] objectEnumerator];
	AIService		*service;
	
	//Create a small explanation text
	[accessoryView setStringValue:AILocalizedString(@"Select an entry from your address book, or add a new person.",
													nil)];
	[accessoryView setFont:[NSFont systemFontOfSize:10.0]];
	[accessoryView setDrawsBackground:NO];
	[accessoryView setEnabled:NO];
	[accessoryView setBezeled:NO];
	[accessoryView sizeToFit];
	//And attach it to our people picker view
	[peoplePicker setAccessoryView:accessoryView];
	
	//Configure our people picker
	[peoplePicker setAllowsGroupSelection:NO];
	[peoplePicker setAllowsMultipleSelection:NO];
	[peoplePicker setValueSelectionBehavior:ABSingleValueSelection];
	[peoplePicker setTarget:self];
	[peoplePicker setNameDoubleAction:@selector(select:)];
	
	//We show only the active services
	while ((service = [servicesEnumerator nextObject])) {
		NSString *property = [self propertyFromService:service];
		if (property && ![[peoplePicker properties] containsObject:property])
			[peoplePicker addProperty:property];
	}
}

/*!
 * @brief Hide ourself and inform our delegate
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (delegate && returnCode == NSOKButton)
		[delegate absearchWindowControllerDidSelectPerson:self];
	
	[sheet orderOut:nil];
}

/*!
 * @brief Cancel
 */
- (IBAction)cancel:(id)sender
{
	if ([self windowShouldClose:nil]) {
		if ([[self window] isSheet]) {
			[NSApp endSheet:[self window] returnCode:NSCancelButton];
		} else {
			[[self window] close];
		}
	}
}

/*!
 * @brief Select a person
 */
- (IBAction)select:(id)sender
{
	if ([self windowShouldClose:nil]) {
		if ([[self window] isSheet]) {
			[NSApp endSheet:[self window] returnCode:NSOKButton];
		} else {
			[[self window] close];
		}
	}
}

- (IBAction)createNewPerson:(id)sender
{
	//To be implemented...
}

/*!
 * @brief Set our delegat
 */
- (void)setDelegate:(id)newDelegate
{
	NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
	
	if (delegate) {
		[nc removeObserver:delegate
					  name:OWABSearchWindowControllerDidSelectPersonNotification
					object:self];
	}
	
	if (newDelegate) {
		[nc addObserver:newDelegate
			   selector:@selector(OWABSearchWindowControllerDidSelectPerson:)
				   name:OWABSearchWindowControllerDidSelectPersonNotification
				 object:self];
	}
	
	delegate = newDelegate;
}

/*!
 * @brief Returns our delegate
 */
- (id)delegate
{
	return delegate;
}

#pragma mark -

/*!
 * @brief Returns the selected person.
 */
- (ABPerson *)selectedPerson
{
	return [[peoplePicker selectedRecords] objectAtIndex:0];
}

/*!
 * @brief Returns the selected person's screen name/number.
 */
- (NSString *)selectedScreenName
{
	NSString *result = nil;
	NSArray *selectedValues = [peoplePicker selectedValues];
	
	if ([selectedValues count] > 0)
		result = [selectedValues objectAtIndex:0];

	return result;
}

/*!
 * @brief Returns the selected person's name like it's displayed in AB.
 */
- (NSString *)selectedName
{
	ABPerson *selectedPerson = [self selectedPerson];
	NSString *result = nil;
	NSString *firstName = [selectedPerson valueForProperty:kABFirstNameProperty];
	NSString *lastName = [selectedPerson valueForProperty:kABLastNameProperty];
	
	//Make sure we don't get "(null)" in our result
	if (firstName && lastName) {
		if ([[ABAddressBook sharedAddressBook] defaultNameOrdering] == kABFirstNameFirst)
			result = [firstName stringByAppendingFormat:@" %@", lastName];
		else
			result = [lastName stringByAppendingFormat:@" %@", firstName];
	}
	else if (firstName)
		result = firstName;
	else if (lastName)
		result = lastName;
	
	return result;
}

/*!
 * @brief Returns the selected person's nickname.
 */
- (NSString *)selectedAlias
{
	return [[self selectedPerson] valueForProperty:kABNicknameProperty];
}

/*!
 * @brief Returns the service of the selected screen name/number.
 */
- (AIService *)selectedService
{
	return [self serviceFromProperty:[peoplePicker displayedProperty]];
}

#pragma mark -
#pragma mark Private

/*!
 * @brief Returns the appropriate service for the property.
 *
 * @param property - an ABPerson property.
 */
- (AIService *)serviceFromProperty:(NSString *)property
{
	AIService *result = nil;
	
	if ([property isEqualToString:kABAIMInstantProperty])
		result = [[adium accountController] serviceWithUniqueID:AIMServiceUniqueID];
	else if ([property isEqualToString:kABICQInstantProperty])
		result = [[adium accountController] serviceWithUniqueID:ICQServiceUniqueID];
	else if ([property isEqualToString:kABMSNInstantProperty])
		result = [[adium accountController] serviceWithUniqueID:MSNServiceUniqueID];
	else if ([property isEqualToString:kABJabberInstantProperty])
		result = [[adium accountController] serviceWithUniqueID:JabberServiceUniqueID];
	else if ([property isEqualToString:kABYahooInstantProperty])
		result = [[adium accountController] serviceWithUniqueID:YahooServiceUniqueID];
	
	return result;
}

/*!
 * @brief Returns the appropriate property for the service.
 */
- (NSString *)propertyFromService:(AIService *)service
{
	NSString *result = nil;
	
	if ([[service serviceCodeUniqueID] isEqualToString:AIMServiceUniqueID])
		result = kABAIMInstantProperty;
	else if ([[service serviceCodeUniqueID] isEqualToString:ICQServiceUniqueID])
		result = kABICQInstantProperty;
	else if ([[service serviceCodeUniqueID] isEqualToString:MSNServiceUniqueID])
		result = kABMSNInstantProperty;
	else if ([[service serviceCodeUniqueID] isEqualToString:DotMacServiceUniqueID])
		result = kABAIMInstantProperty;
	else if ([[service serviceCodeUniqueID] isEqualToString:JabberServiceUniqueID])
		result = kABJabberInstantProperty;
	else if ([[service serviceCodeUniqueID] isEqualToString:YahooServiceUniqueID])
		result = kABYahooInstantProperty;
	
	return result;
}

@end


#pragma mark -
@implementation NSObject (OWABSearchWindowControllerDelegate)

/*!
 * @brief A delegate method that is sent when the user has selected a person/value.
 */
- (void)absearchWindowControllerDidSelectPerson:(OWABSearchWindowController *)controller
{
	//Do nothing by default
}

@end
