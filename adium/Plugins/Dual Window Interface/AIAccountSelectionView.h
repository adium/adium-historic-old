/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class AIAccount, AIListObject;

@protocol AIAccountSelectionViewDelegate <NSObject>
- (void)setAccount:(AIAccount *)inAccount;
- (void)setListObject:(AIListContact *)listObject;
- (AIAccount *)account;
- (AIListContact *)listObject;
@end

@interface AIAccountSelectionView : NSView <AIListObjectObserver> {
    AIAdium						*adium;
	
    IBOutlet	NSView			*view_contents;

	IBOutlet	NSBox			*box_accounts;
	IBOutlet	NSPopUpButton   *popUp_accounts;
	
	IBOutlet	NSBox			*box_contacts;
	IBOutlet	NSPopUpButton   *popUp_contacts;
	
    id <AIAccountSelectionViewDelegate>	delegate;
}

+ (BOOL)optionsAvailableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;
+ (BOOL)multipleAccountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject;
+ (BOOL)multipleContactsForListObject:(AIListObject *)inObject;

- (id)initWithFrame:(NSRect)frameRect delegate:(id <AIAccountSelectionViewDelegate>)inDelegate;
- (void)setDelegate:(id <AIAccountSelectionViewDelegate>)inDelegate;
- (id <AIAccountSelectionViewDelegate>)delegate;
- (void)configureView;
- (void)updateMenu;
- (void)accountListChanged:(NSNotification *)notification;
- (IBAction)selectAccount:(id)sender;

@end
