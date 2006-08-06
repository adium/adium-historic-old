//
//  ESShowContactInfoPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on 1/8/06.
//

#import "ESShowContactInfoPromptController.h"
#import "AIContactInfoWindowController.h"
#import <Adium/AIListContact.h>

#define SHOW_CONTACT_INFO_PROMPT_NIB	@"ShowContactInfoPrompt"
#define GET_INFO						AILocalizedString(@"Get Info",nil)

static ESShowContactInfoPromptController *sharedShowInfoPromptInstance = nil;

/*!
 * @class ESShowContactInfoPromptController
 * @brief Controller for the Show Contact Info prompt, which allows one to get info on an arbitrary contact
 */
@implementation ESShowContactInfoPromptController

/*!
 * @brief Return our shared instance
 * @result The shared instance
 */
+ (id)sharedInstance 
{
	return sharedShowInfoPromptInstance;
}

/*!
 * @brief Create the shared instance
 * @result The shared instance
 */
+ (id)createSharedInstance 
{
	sharedShowInfoPromptInstance = [[self alloc] initWithWindowNibName:SHOW_CONTACT_INFO_PROMPT_NIB];
	
	return sharedShowInfoPromptInstance;
}

/*!
 * @brief Destroy the shared instance
 */
+ (void)destroySharedInstance 
{
	[sharedShowInfoPromptInstance autorelease]; sharedShowInfoPromptInstance = nil;
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[label_using setLocalizedString:AILocalizedString(@"Using:",nil)];
	[label_contact setLocalizedString:AILocalizedString(@"Contact:",nil)];

	[button_okay setLocalizedString:GET_INFO];
	[[self window] setTitle:GET_INFO];
}

/*!
 * @brief Show info for the desired contact
 */
- (IBAction)okay:(id)sender
{
	AIListContact	*contact;

	if ((contact = [self contactFromTextField])) {
		[AIContactInfoWindowController showInfoWindowForListObject:contact];

		//Close the prompt
        [[self class] closeSharedInstance];
    }
}

@end
