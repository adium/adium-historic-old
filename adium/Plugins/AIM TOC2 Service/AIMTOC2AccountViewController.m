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

#import "AIMTOC2ServicePlugin.h"
#import "AIMTOC2AccountViewController.h"
#import "AIMTOC2Account.h"

@implementation AIMTOC2AccountViewController

//Nib to load
- (NSString *)nibName{
    return(@"AIMTOCAccountView");    
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
	//Configure the standard controls
	[super configureForAccount:inAccount];
	
    //Fill in our host & port
    [textField_host setStringValue:[account preferenceForKey:AIM_TOC2_KEY_HOST group:GROUP_ACCOUNT_STATUS]];
    [textField_port setStringValue:[account preferenceForKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS]];

    //Full name
    [textField_fullName setStringValue:[account preferenceForKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS]];
    
    //Profile
    NSAttributedString	*profile = [NSAttributedString stringWithData:[account preferenceForKey:AIM_TOC2_KEY_PROFILE group:GROUP_ACCOUNT_STATUS]];
    if(!profile) profile = [[[NSAttributedString alloc] initWithString:@""] autorelease];
    [[textView_textProfile textStorage] setAttributedString:profile];
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    //Handle the standard preferences
    [super changedPreference:sender];
    
    //Our custom preferences
    if(sender == textField_host){
        [account setPreference:[sender stringValue] forKey:AIM_TOC2_KEY_HOST group:GROUP_ACCOUNT_STATUS];
        
    }else if(sender == textField_port){
        [account setPreference:[sender stringValue] forKey:AIM_TOC2_KEY_PORT group:GROUP_ACCOUNT_STATUS];
        
    }else if(sender == textField_fullName){
        [account setPreference:[sender stringValue] forKey:@"FullNameAttr" group:GROUP_ACCOUNT_STATUS];    
        
    }
}

//Profile text was changed
- (void)textDidEndEditing:(NSNotification *)notification
{
    [account setPreference:[[textView_textProfile textStorage] dataRepresentation] forKey:AIM_TOC2_KEY_PROFILE group:GROUP_ACCOUNT_STATUS];
}

@end
