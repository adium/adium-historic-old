//
//  ESGaimOTRPrivateKeyGenerationWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimOTRPrivateKeyGenerationWindowController.h"

@interface ESGaimOTRPrivateKeyGenerationWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forIdentifier:(NSString *)inIdentifier;
@end

@implementation ESGaimOTRPrivateKeyGenerationWindowController

static NSMutableDictionary	*keyGenerationControllerDict = nil;

/*
 * @brief We started generating a private key.
 *
 * Create a window controller for inIdentifier and tell it to display.
 * Has no effect if a window is already open for inIdentifier.
 */
+ (void)startedGeneratingForIdentifier:(NSString *)inIdentifier
{
	if(!keyGenerationControllerDict) keyGenerationControllerDict = [[NSMutableDictionary alloc] init];
	
	if(![keyGenerationControllerDict objectForKey:inIdentifier]){
		ESGaimOTRPrivateKeyGenerationWindowController	*controller;
		
		controller = [[self alloc] initWithWindowNibName:@"GaimOTRPrivateKeyGenerationWindow" forIdentifier:inIdentifier];
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];		
	}	
}

/*
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName forIdentifier:(NSString *)inIdentifier
{
	self = [super initWithWindowNibName:windowNibName];
	identifier = [inIdentifier retain];
	
	return self;
}

/*
 * @brief Window loaded
 *
 * Start our spinning progress indicator and set up our window
 */
- (void)windowDidLoad
{
	[super windowDidLoad];

	[[self window] setTitle:AILocalizedString(@"Please wait...",nil)];

	[progressIndicator startAnimation:nil];
	[textField_message setStringValue:
		[NSString stringWithFormat:AILocalizedString(@"Generating private encryption key for %@",nil),identifier]];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[identifier release];
	[super dealloc];
}

/*
 * @brief Finished generating a private key
 *
 * Closes the window assosiated with inIdentifier, if it is open.
 */
+ (void)finishedGeneratingForIdentifier:(NSString *)inIdentifier
{
	ESGaimOTRPrivateKeyGenerationWindowController	*controller;

	controller = [keyGenerationControllerDict objectForKey:inIdentifier];
	[controller close];
	
	[keyGenerationControllerDict removeObjectForKey:inIdentifier];
}

@end
