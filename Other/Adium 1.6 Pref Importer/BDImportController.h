/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

@class BDProteusImporter, BDFireImporter, BDiChatImporter, BDGaimImporter, BDAdiumImporter;

@interface BDImportController : NSObject
{
    IBOutlet NSButton		*button_Cancel;
    IBOutlet NSButton		*button_Import;
    IBOutlet NSButton		*button_proteusAddAccount;
    IBOutlet NSButton		*button_proteusDelAccount;
    IBOutlet NSImageView	*image_clientImage;
    IBOutlet NSTableView	*table_proteusAccounts;
    IBOutlet NSTabView		*tabView_ClientTab;
    IBOutlet NSPanel		*panel_importPanel;
	
    BDProteusImporter		*proteus;
    BDFireImporter		*fire;
    BDiChatImporter		*iChat;
    BDGaimImporter		*gaim;
    BDAdiumImporter		*adium;

    NSMutableArray		*accountList;
}

#pragma mark -
#pragma mark Importer Configuration

- (void)configureProteusTab;
- (void)configureiChatTab;
- (void)configureFireTab;
- (void)configureGaimTab;
@end
