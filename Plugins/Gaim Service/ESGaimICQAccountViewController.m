//
//  ESGaimICQAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/29/04.
//

#import "ESGaimICQAccountViewController.h"

@implementation ESGaimICQAccountViewController

- (NSString *)nibName{
    return(@"ESGaimICQAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[textField_encoding setStringValue:[account preferenceForKey:KEY_ICQ_ENCODING group:GROUP_ACCOUNT_STATUS]];
}

- (IBAction)changedPreference:(id)sender
{
	if (sender == textField_encoding){
		//Access the encoding so we can redisplay the default value if applicable
		if (![[textField_encoding stringValue] length]){
			NSString *encoding = [[adium preferenceController] preferenceForKey:KEY_ICQ_ENCODING
																		  group:GROUP_ACCOUNT_STATUS];
			if (encoding){
				[textField_encoding setStringValue:encoding];
			}
		}
		
	}else{
		[super changedPreference:sender];		
	}	
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *sender = [notification object];
	if (sender == textField_encoding){
		NSString *encoding = [textField_encoding stringValue];
		[account setPreference:([encoding length] ? encoding : nil)
						forKey:KEY_ICQ_ENCODING
						 group:GROUP_ACCOUNT_STATUS];
		
	}else{
		[super controlTextDidChange:notification];
	}
}


@end
