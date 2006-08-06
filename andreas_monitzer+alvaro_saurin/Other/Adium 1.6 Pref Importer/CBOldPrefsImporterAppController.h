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

#import "BDImportController.h"

@interface CBOldPrefsImporterAppController : NSObject 
{
    IBOutlet	NSWindow				*window_main;
    IBOutlet	NSPopUpButton			*popUpButton_account;
    IBOutlet	NSProgressIndicator		*progressIndicator;
    IBOutlet	NSTextField				*currentTask;
    IBOutlet    NSImageView				*image_AdiumImage;
	IBOutlet	NSImageView				*image_Backdrop;
    IBOutlet	NSWindow				*theSheet;
    IBOutlet	NSPanel					*importListSheet;
    IBOutlet	NSPopUpButton			*popUpButton_user;
    IBOutlet	NSButton				*button_OK;
    IBOutlet	NSButton				*button_Cancel;
    IBOutlet    NSButton                *button_ImportAwayMessages;
	IBOutlet	NSButton				*button_Adium_Logs;
	IBOutlet	NSButton				*button_Adium_Aliases;
	IBOutlet	NSButton				*button_Adium_Contacts;
    IBOutlet    NSPopUpButton           *popUpButton_Clients;
    IBOutlet    NSButton                *button_Import;
    IBOutlet    NSProgressIndicator     *spinner_importProgress;
	IBOutlet	NSProgressIndicator		*spinner_ClientProgress;
    IBOutlet    NSTabView               *tabView_ClientTabs;
    IBOutlet    NSTabView               *tabView_optionsTab;
    IBOutlet	AIContentController     *contentController;
    IBOutlet    NSButton                *button_importAllProteusAways;
	IBOutlet	BDImportController		*importer;

	
	NSMutableDictionary		*iconDict;
    
    
}
- (AIContentController *)contentController;
- (IBAction)importLogs:(id)sender;
- (IBAction)importAliases:(id)sender;
- (IBAction)importContacts:(id)sender;
- (IBAction)sheetButton:(id)sender;
- (IBAction)importAwayMessages:(id)sender;
- (IBAction)changeClientSelection:(id)sender;

- (BOOL)ensureAdiumIsClosed;
- (void)importiChatAways;
- (void)importProteusAways;
- (void)importFireAways;

//NSApplication delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;


@end
