/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIGaimOscarAccountViewController.h"
#import "CBGaimAccount.h"

@implementation AIGaimOscarAccountViewController

- (NSString *)nibName{
    return(@"ESGaimOscarAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
    
    //Full name
    NSString	*fullName = [account preferenceForKey:@"FullName" group:GROUP_ACCOUNT_STATUS];
    if(fullName){
        [textField_fullName setStringValue:fullName];
    }
    
    //Profile
    NSData		*profileData = [account preferenceForKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
    if(profileData){
        NSAttributedString	*profile = [NSAttributedString stringWithData:profileData];
        if(profile && [profile length]){
            [[textView_textProfile textStorage] setAttributedString:profile];
        }else{
            [textView_textProfile setString:@""];
		}
    }
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    [super changedPreference:sender];
    
    //Our custom preferences
    if(sender == textField_fullName){
        [account setPreference:[sender stringValue] forKey:@"FullName" group:GROUP_ACCOUNT_STATUS];    
    }
}

//Profile text was changed
- (void)textDidEndEditing:(NSNotification *)notification
{
    [account setPreference:[[textView_textProfile textStorage] dataRepresentation] forKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
}

@end
