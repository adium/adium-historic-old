//
//  ESGaimOTRFingerprintDetailsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 5/11/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimOTRFingerprintDetailsWindowController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/AIImageAdditions.h>

/* libotr headers */
#import <libotr/proto.h>
#import <libotr/context.h>
#import <libotr/message.h>

/* gaim-otr headers */
#import <Libgaim/ui.h>
#import <Libgaim/dialogs.h>
#import <Libgaim/otr-plugin.h>

@interface ESGaimOTRFingerprintDetailsWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forFingerprintDict:(NSDictionary *)inFingerprintDict;
@end

@implementation ESGaimOTRFingerprintDetailsWindowController

+ (void)showDetailsForFingerprintDict:(NSDictionary *)inFingerprintDict
{
	ESGaimOTRFingerprintDetailsWindowController	*controller;
	
	if ((controller = [[self alloc] initWithWindowNibName:@"GaimOTRFingerprintDetailsWindow" 
									   forFingerprintDict:inFingerprintDict])) {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
	}
}

- (id)initWithWindowNibName:(NSString *)windowNibName forFingerprintDict:(NSDictionary *)inFingerprintDict
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		fingerprintDict = [inFingerprintDict retain];
	}
	
	return self;
}

- (void)dealloc
{
	[fingerprintDict release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	AIAccount	*account = [fingerprintDict objectForKey:@"AIAccount"];

	[textField_UID setStringValue:[fingerprintDict objectForKey:@"UID"]];
	[textField_fingerprint setStringValue:[fingerprintDict objectForKey:@"FingerprintString"]];
	
	[imageView_service setImage:[AIServiceIcons serviceIconForObject:account
																type:AIServiceIconLarge
														   direction:AIIconNormal]];
	[imageView_lock setImage:[NSImage imageNamed:@"Lock_Locked State" forClass:[adium class]]];	
	
	[[self window] setTitle:AILocalizedString(@"OTR Fingerprint",nil)];
	[button_OK setLocalizedString:AILocalizedString(@"OK",nil)];
	[button_forgetFingerprint setLocalizedString:AILocalizedString(@"Forget Fingerprint","Button title to make Adium no longer know a user's encryption fingerprint")];
	
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[self autorelease];
}

/*!
* @brief Auto-saving window frame key
 *
 * This is the string used for saving this window's frame.  It should be unique to this window.
 */
- (NSString *)adiumFrameAutosaveName
{
	return @"OTR Fingerprint Details Window";
}

- (void)gaimThreadForgetFingerprint:(NSValue *)fingerprintValue
{
	Fingerprint	*fingerprint = [fingerprintValue pointerValue];
	
	if (fingerprint) {
		otrg_ui_forget_fingerprint(fingerprint);
	}
}

- (IBAction)forgetFingerprint:(id)sender
{
	[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
									 performSelector:@selector(gaimThreadForgetFingerprint:)
										  withObject:[fingerprintDict objectForKey:@"FingerprintValue"]];
	
	[self closeWindow:nil];
}


@end
