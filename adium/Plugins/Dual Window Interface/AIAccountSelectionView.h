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

@class AIAdium, AIAccount, AIListObject;

@protocol AIAccountSelectionViewDelegate <NSObject>
- (void)setAccount:(AIAccount *)inAccount;
- (AIAccount *)account;
- (AIListObject *)listObject;
@end

@interface AIAccountSelectionView : NSView {
    AIAdium				*owner;
    
    IBOutlet	NSView			*view_contents;
    IBOutlet	NSPopUpButton		*popUp_accounts;

    id <AIAccountSelectionViewDelegate>	delegate;
}

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate owner:(id)inOwner;
- (void)configureView;
- (void)configureAccountMenu;
- (void)updateMenu;
- (void)accountListChanged:(NSNotification *)notification;
- (IBAction)selectNewAccount:(id)sender;

@end
