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
    [[NSNotificationCenter defaultCenter] addObserver:textView_textProfile selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textView_textProfile];
}

//Profile text was changed
- (void)textDidEndEditing:(NSNotification *)notification
{
    [account setPreference:[[textView_textProfile textStorage] dataRepresentation] forKey:@"TextProfile" group:GROUP_ACCOUNT_STATUS];
}

@end
