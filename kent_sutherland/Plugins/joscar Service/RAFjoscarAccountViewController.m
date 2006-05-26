//
//  RAFjoscarAccountViewController.m
//  Adium
//
//  Created by Augie Fackler on 11/21/05.
//

#import "RAFjoscarAccountViewController.h"

#import "AIPreferenceController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AITextViewWithPlaceholder.h>
#import <Adium/AIAccount.h>
#import <Adium/AIMessageEntryTextView.h>
#import "AIAdium.h"

@implementation RAFjoscarAccountViewController

/*!
* @brief Nib name
 */
- (NSString *)nibName{
    return @"RAFjoscarAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSScrollView	*scrollView = [textView_textProfile enclosingScrollView];
	if (scrollView && [scrollView isKindOfClass:[AIAutoScrollView class]]) {
		[(AIAutoScrollView *)scrollView setAlwaysDrawFocusRingIfFocused:YES];
	}
	
	if ([textView_textProfile isKindOfClass:[AIMessageEntryTextView class]]) {
		/* We use the AIMessageEntryTextView to get nifty features for our text view, but we don't want to attempt
		* to 'send' to a target on Enter or Return.
		*/
		[(AIMessageEntryTextView *)textView_textProfile setSendingEnabled:NO];
	}
}

/*!
* @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	[[NSFontPanel sharedFontPanel] setDelegate: textView_textProfile];
    
    //Profile
    NSData				*profileData = [account preferenceForKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES];
	NSAttributedString	*profile = (profileData ? [NSAttributedString stringWithData:profileData] : nil);
	
	if (profile && [profile length]) {
		[[textView_textProfile textStorage] setAttributedString:profile];
	} else {
		[textView_textProfile setString:@""];
	}

	if ([textView_textProfile isKindOfClass:[AITextViewWithPlaceholder class]]) {
		NSData				*globalProfileData = [[adium preferenceController] preferenceForKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
		NSAttributedString	*globalProfile = (globalProfileData ? [NSAttributedString stringWithData:globalProfileData] : nil);

		if (globalProfile && [globalProfile length]) {
			[(AITextViewWithPlaceholder *)textView_textProfile setPlaceholder:globalProfile];
		} else {
			[(AITextViewWithPlaceholder *)textView_textProfile setPlaceholder:nil];
		}
	}
}

/*!
* @brief Save controls
 */
- (void)saveConfiguration
{
    [super saveConfiguration];
	[account setPreference:([[textView_textProfile textStorage] length] ? 
							[[textView_textProfile textStorage] dataRepresentation] :
							nil)
					forKey:@"TextProfile"
					 group:GROUP_ACCOUNT_STATUS];	
}

@end
