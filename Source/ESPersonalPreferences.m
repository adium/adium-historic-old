//
//  ESPersonalPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 12/18/05.
//

#import "ESPersonalPreferences.h"
#import "AIPreferenceController.h"
#import "AIContactController.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIDelayedTextField.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Cocoa/Cocoa.h>

@interface ESPersonalPreferences (PRIVATE)
- (void)fireProfileChangesImmediately;
- (void)configureProfile;
- (void)configureImageView;
- (void)configureTooltips;
@end

@implementation ESPersonalPreferences

/*!
 * @brief Preference pane properties
 */
- (PREFERENCE_CATEGORY)category{
    return AIPref_Personal;
}
- (NSString *)label{
    return AILocalizedString(@"Personal","Personal preferences label");
}
- (NSString *)nibName{
    return @"PersonalPreferences";
}

/*!
 * @brief Configure the view initially
 */
- (void)viewDidLoad
{
	NSString *displayName = [[[[adium preferenceController] preferenceForKey:@"FullNameAttr"
																	   group:GROUP_ACCOUNT_STATUS] attributedString] string];
	[textField_displayName setStringValue:(displayName ? displayName : @"")];
	
	NSString *alias = [[adium preferenceController] preferenceForKey:@"LocalAccountAlias"
															   group:GROUP_ACCOUNT_STATUS];
	[textField_alias setStringValue:(alias ? alias : @"")];
	
	//Set the default local alias (address book name) as the placeholder for the local alias
	NSString *defaultAlias = [[adium preferenceController] preferenceForKey:@"DefaultLocalAccountAlias"
																	  group:GROUP_ACCOUNT_STATUS];
	[[textField_alias cell] setPlaceholderString:(defaultAlias ? defaultAlias : @"")];
	
	[self configureProfile];
	[self configureImageView];
	[self configureTooltips];
	
	if ([[[adium preferenceController] preferenceForKey:KEY_USE_USER_ICON
												  group:GROUP_ACCOUNT_STATUS] boolValue]) {
		[matrix_userIcon selectCellWithTag:1];
	} else {
		[matrix_userIcon selectCellWithTag:0];		
	}

	[self configureControlDimming];

	[super viewDidLoad];
}

- (void)viewWillClose
{
	[self fireProfileChangesImmediately];

	[[NSFontPanel sharedFontPanel] setDelegate:nil];

	[super viewWillClose];
}

- (void)changePreference:(id)sender
{	
	if (sender == textField_alias) {
		[[adium preferenceController] setPreference:[textField_alias stringValue]
											 forKey:@"LocalAccountAlias"
											  group:GROUP_ACCOUNT_STATUS];

	} else if (sender == textField_displayName) {
		[[adium preferenceController] setPreference:[[NSAttributedString stringWithString:[textField_displayName stringValue]] dataRepresentation]
											 forKey:@"FullNameAttr"
											  group:GROUP_ACCOUNT_STATUS];

	} else if (sender == textView_profile) {
		[[adium preferenceController] setPreference:[[textView_profile textStorage] dataRepresentation] 
											 forKey:@"TextProfile"
											  group:GROUP_ACCOUNT_STATUS];

	} else if (sender == matrix_userIcon) {
		BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);

		[[adium preferenceController] setPreference:[NSNumber numberWithBool:enableUserIcon]
											 forKey:KEY_USE_USER_ICON
											  group:GROUP_ACCOUNT_STATUS];	
	}
	
	[super changePreference:nil];
}

- (void)configureControlDimming
{
	BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);

	[button_chooseIcon setEnabled:enableUserIcon];
	[imageView_userIcon setEnabled:enableUserIcon];	
}

#pragma mark Profile
- (void)configureProfile
{
	NSScrollView	*scrollView = [textView_profile enclosingScrollView];
	if (scrollView && [scrollView isKindOfClass:[AIAutoScrollView class]]) {
		[(AIAutoScrollView *)scrollView setAlwaysDrawFocusRingIfFocused:YES];
	}
	
	if ([textView_profile isKindOfClass:[AIMessageEntryTextView class]]) {
		/* We use the AIMessageEntryTextView to get nifty features for our text view, but we don't want to attempt
		* to 'send' to a target on Enter or Return.
		*/
		[(AIMessageEntryTextView *)textView_profile setSendingEnabled:NO];
	}

	[[NSFontPanel sharedFontPanel] setDelegate:textView_profile];

	NSData				*profileData = [[adium preferenceController] preferenceForKey:@"TextProfile"
																				group:GROUP_ACCOUNT_STATUS];
	NSAttributedString	*profile = (profileData ? [NSAttributedString stringWithData:profileData] : nil);
	
	if (profile && [profile length]) {
		[[textView_profile textStorage] setAttributedString:profile];
	} else {
		[textView_profile setString:@""];
	}	
}

- (void)fireProfileChangesImmediately
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(changePreference:)
											   object:textView_profile];	
	[self changePreference:textView_profile];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == textView_profile) {		
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(changePreference:)
												   object:textView_profile];
		[self performSelector:@selector(changePreference:)
				   withObject:textView_profile
				   afterDelay:1.0];
	}
}

// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
#pragma mark AIImageViewWithImagePicker Delegate
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	[[adium preferenceController] setPreference:imageData
										 forKey:KEY_USER_ICON
										  group:GROUP_ACCOUNT_STATUS];
}

- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_USER_ICON
										  group:GROUP_ACCOUNT_STATUS];

	//User icon - restore to the default icon
	[self configureImageView];
}

- (void)configureImageView
{
	NSData *imageData = [[adium preferenceController] preferenceForKey:KEY_USER_ICON
																 group:GROUP_ACCOUNT_STATUS];
	if (!imageData) {
		imageData = [[adium preferenceController] preferenceForKey:KEY_DEFAULT_USER_ICON
															 group:GROUP_ACCOUNT_STATUS];
	}

	[imageView_userIcon setImage:(imageData ? [[[NSImage alloc] initWithData:imageData] autorelease] : nil)];
}

- (void)configureTooltips
{
	[matrix_userIcon setToolTip:AILocalizedString(@"Do not use an icon to represent you.", nil)
						forCell:[matrix_userIcon cellWithTag:0]];
	[matrix_userIcon setToolTip:AILocalizedString(@"Use the icon below represent you.", nil)
						forCell:[matrix_userIcon cellWithTag:1]];
	
#define LOCAL_ALIAS_TOOLTIP AILocalizedString(@"Name to display locally for you in outgoing messages", nil)
	[label_localAlias setToolTip:LOCAL_ALIAS_TOOLTIP];
	[textField_alias setToolTip:LOCAL_ALIAS_TOOLTIP];
	
#define REMOTE_ALIAS_TOOLTIP AILocalizedString(@"Name to display to remote contacts (not supported by all services)", nil)
	[label_remoteAlias  setToolTip:REMOTE_ALIAS_TOOLTIP];
	[textField_displayName setToolTip:REMOTE_ALIAS_TOOLTIP];

#define PROFILE_TOOLTIP AILocalizedString(@"Profile to display when contacts request information about you (not supported by all services). Text may be formatted using the Edit and Format menus.", nil)
	[label_profile setToolTip:PROFILE_TOOLTIP];
	[textView_profile setToolTip:PROFILE_TOOLTIP];
}

@end
