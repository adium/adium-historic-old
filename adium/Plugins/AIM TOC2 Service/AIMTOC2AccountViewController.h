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

@class AIAdium, AIMTOC2Account;

@interface AIMTOC2AccountViewController : NSObject <AIAccountViewController> {
    AIAdium		*owner;
    AIMTOC2Account	*account;

    NSArray		*auxilaryTabs;

    IBOutlet		NSView			*view_accountView;
    IBOutlet		NSTextField		*textField_handle;
    IBOutlet		NSTextField		*textField_password;
    IBOutlet		NSTextField		*textField_fullName;
    IBOutlet		NSTabView		*view_auxilaryTabView;
    IBOutlet		NSTextField		*textField_host;
    IBOutlet		NSTextField		*textField_port;
    IBOutlet		NSTextView		*textView_textProfile;
}

+ (id)accountViewForOwner:(id)inOwner account:(id)inAccount;
- (NSView *)view;
- (void)configureViewAfterLoad;
- (IBAction)userNameChanged:(id)sender;
- (IBAction)preferenceChanged:(id)sender;

@end
