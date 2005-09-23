//
//  ESGaimAuthorizationRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 5/18/05.
//

#import "ESGaimAuthorizationRequestWindowController.h"
#import "GaimCommon.h"
#import "SLGaimCocoaAdapter.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESGaimAuthorizationRequestWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict;
@end

@implementation ESGaimAuthorizationRequestWindowController

+ (ESGaimAuthorizationRequestWindowController *)showAuthorizationRequestWithDict:(NSDictionary *)inInfoDict
{
	ESGaimAuthorizationRequestWindowController	*controller;
	
	if ((controller = [[self alloc] initWithWindowNibName:@"GaimAuthorizationRequestWindow"
												 withDict:inInfoDict])) {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
	
	return controller;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		NSWindow	*window;

		infoDict = [inInfoDict retain];
		window = [self window];
		if (![window setFrameUsingName:[self windowFrameAutosaveName]]) {
			[window center];
		}		
	}
	
    return self;
}

- (void)dealloc
{
	[infoDict release];
	
	[super dealloc];
}

/*!
 * @brief Call the gaim callback to finish up the window
 *
 * @param inCallBackValue The cb to use
 * @param inUserDataValue Original user data
 * @param inFieldsValue The entire GaimRequestFields pointer originally passed
 */
- (oneway void)gaimThreadDoAuthRequestCbValue:(NSValue *)inCallBackValue
							withUserDataValue:(NSValue *)inUserDataValue 
						  callBackIndexNumber:(NSNumber *)inIndexNumber
{	
	GaimRequestActionCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue], [inIndexNumber intValue]);
	}
}

- (void)windowDidLoad
{	
	NSString	*message;
	
	[textField_header setStringValue:AILocalizedString(@"Authorization Requested",nil)];
	
	if ([infoDict objectForKey:@"Reason"]) {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list for the following reason:\n%@",nil),
			[infoDict objectForKey:@"Remote Name"],
			[infoDict objectForKey:@"Account Name"],
			[infoDict objectForKey:@"Reason"]];

	} else {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list.",nil),
			[infoDict objectForKey:@"Remote Name"],
			[infoDict objectForKey:@"Account Name"]];
	}
	
	[textField_message setStringValue:message];
	
	[super windowDidLoad];
}

- (IBAction)authorize:(id)sender
{
	//Do the authorization serverside
	[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
									 performSelector:@selector(gaimThreadDoAuthRequestCbValue:withUserDataValue:callBackIndexNumber:)
										  withObject:[[[infoDict objectForKey:@"authorizeCB"] retain] autorelease]
										  withObject:[[[infoDict objectForKey:@"userData"] retain] autorelease]
										  withObject:[NSNumber numberWithInt:0]];

	//Now handle the Add To Contact List checkbox
	AILog(@"Authorize: (%i) %@",[checkBox_addToList state],infoDict);
	if ([checkBox_addToList state] == NSOnState) {
		/* Add the contact to all appropriate accounts. Gaim doesn't tell us which account this auth request was on,
		 * and I'm not in a mood to fix Gaim silliness so we'll just hack around it for now, adding on all accounts which match
		 * the passed account name. */
		NSString		*UID = [infoDict objectForKey:@"Remote Name"];
		NSString		*accountName = [[infoDict objectForKey:@"Account Name"] compactedString];
		NSEnumerator	*enumerator;
		AIAccount		*account;
		NSMutableSet	*requestedServices = [NSMutableSet set];
		
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if ([account online] &&
			   [[[account UID] compactedString] isEqualToString:accountName] &&
			   ![requestedServices containsObject:[account service]]) {
				AIService	*service = [account service];
				
				[[adium contactController] requestAddContactWithUID:UID
															service:service];
				
				[requestedServices addObject:service];
			}
		}
	}
	
	[infoDict release]; infoDict = nil;
	
	[self closeWindow:nil];
}

- (void)doWindowWillClose
{
	if (infoDict) {
		[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
										 performSelector:@selector(gaimThreadDoAuthRequestCbValue:withUserDataValue:callBackIndexNumber:)
											  withObject:[infoDict objectForKey:@"denyCB"]
											  withObject:[infoDict objectForKey:@"userData"]
											  withObject:[NSNumber numberWithInt:1]];
	}
}

@end
