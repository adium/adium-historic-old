/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIAccountViewController.h"
#import "AIAccount.h"

@implementation AIAccountViewController

//Create a new account view controller
+ (id)accountViewController
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{
	NSBundle		*ourBundle = [NSBundle bundleForClass:[AIAccountViewController class]];
	NSDictionary	*nameTable = [NSDictionary dictionaryWithObject:self forKey:@"NSOwner"];
	
    [super init];
    account = nil;
    
	//Load custom views for our subclass (If our subclass specifies a nib name)
	if([self nibName]){
		[NSBundle loadNibNamed:[self nibName] owner:self];
	}
	
	//Load our default views if necessary
	if(!view_setup) [ourBundle loadNibFile:@"AccountSetup" externalNameTable:nameTable withZone:nil];
	if(!view_profile) [ourBundle loadNibFile:@"AccountProfile" externalNameTable:nameTable withZone:nil];
	if(!view_options) [ourBundle loadNibFile:@"AccountOptions" externalNameTable:nameTable withZone:nil];

    return(self);
}

//Dealloc
- (void)dealloc
{    
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    
    [super dealloc];
}

//Awake
- (void)awakeFromNib
{
	//Empty
}


//Account specific views -----------------------------------------------------------------------------------------------
#pragma mark Account specific views
//Setup view
- (NSView *)setupView
{
    return(view_setup);
}

//Profile view
- (NSView *)profileView
{
    return(view_profile);
}

//Options view
- (NSView *)optionsView
{
    return(view_options);
}

//Nib containing custom views or tabs (Optional, for subclasses)
- (NSString *)nibName
{
    return(@"");    
}


//Preferences ----------------------------------------------------------------------------------------------------------
#pragma mark Preferences
//Configure the account view
- (void)configureForAccount:(AIAccount *)inAccount
{
	if(account != inAccount){		
		account = inAccount;
		
		//UID Label
		NSString 	*userNameLabel = [[account service] userNameLabel];
		[textField_accountUIDLabel setStringValue:[(userNameLabel ? userNameLabel : @"User Name") stringByAppendingString:@":"]];
		
		//UID
		NSString	*formattedUID = [account preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
		[textField_accountUID setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [account UID])];
		[textField_accountUID setFormatter:
			[AIStringFormatter stringFormatterAllowingCharacters:[[account service] allowedCharactersForAccountName]
														  length:[[account service] allowedLengthForAccountName]
												   caseSensitive:[[account service] caseSensitive]
													errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.",nil)]];
		
		//Password
		[self updatePasswordField];
		
		//User alias (display name)
		NSString *alias = [[[account preferenceForKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS] attributedString] string];
		[textField_alias setStringValue:(alias ? alias : @"")];
		
		//Server Host
		NSString	*host = [account preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
		[textField_connectHost setStringValue:([host length] ? host : @"")];
		
		//Server Port
		NSNumber	*port = [account preferenceForKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];
		if(port){
			[textField_connectPort setIntValue:[port intValue]];
		}else{
			[textField_connectPort setStringValue:@""];
		}
		
		//Check for new mail
		[checkBox_checkMail setState:[[inAccount preferenceForKey:KEY_ACCOUNT_CHECK_MAIL group:GROUP_ACCOUNT_STATUS] boolValue]];

	}
}

#warning XXX - PortKey, HostKey, find it, replace it -ai
//Save all control values
- (void)saveConfiguration
{
	//UID
	if(![[account UID] isEqualToString:[textField_accountUID stringValue]]){
		[[adium accountController] changeUIDOfAccount:account to:[textField_accountUID stringValue]];			
	}
	
	//Password
	NSString		*password = [textField_password stringValue];
	NSString		*oldPassword;
	
	if(password && [password length] != 0){
		oldPassword = [[adium accountController] passwordForAccount:account];
		if (![password isEqualToString:oldPassword]){
			[[adium accountController] setPassword:password forAccount:account];
		}
	}else{
		[[adium accountController] forgetPasswordForAccount:account];
	}
	
	//Connect Host
	[account setPreference:([[textField_connectHost stringValue] length] ? [textField_connectHost stringValue] : nil)
					forKey:KEY_CONNECT_HOST
					 group:GROUP_ACCOUNT_STATUS];	
	
	//Connect Port
	[account setPreference:([textField_connectPort intValue] ? [NSNumber numberWithInt:[textField_connectPort intValue]] : nil)
					forKey:KEY_CONNECT_PORT
					 group:GROUP_ACCOUNT_STATUS];

	//Alias
	[account setPreference:[[NSAttributedString stringWithString:[textField_alias stringValue]] dataRepresentation]
					forKey:@"FullNameAttr"
					 group:GROUP_ACCOUNT_STATUS];
	
	//Check mail	
	[account setPreference:[NSNumber numberWithBool:[checkBox_checkMail state]]
					forKey:KEY_ACCOUNT_CHECK_MAIL
					 group:GROUP_ACCOUNT_STATUS];
	
}


//Update password field as UID changes
- (IBAction)changedPreference:(id)sender
{
	if(sender == textField_accountUID){
		if(![[account UID] isEqualToString:[sender stringValue]]){
			[self updatePasswordField];
		}
	}
}

//Update password field
- (void)updatePasswordField
{
    NSString		*savedPassword = nil;
	NSString		*accountUID = [textField_accountUID stringValue];
	
#warning XXX - This isnt right, we need to passwordForUID-Service, because we dont have an account instance matching the UID that is entered here -ai
	if(accountUID && [accountUID length]){
		savedPassword = [[adium accountController] passwordForAccount:account];
	}
	if(savedPassword && [savedPassword length] != 0){
		[textField_password setStringValue:savedPassword];
	}else{
		[textField_password setStringValue:@""];
	}
}

@end
