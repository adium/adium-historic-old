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

@class	AISendingTextView;

@interface AIEnterAwayWindowController : AIWindowController {
    IBOutlet 	NSPopUpButton		*popUp_title;
    IBOutlet	AISendingTextView	*textView_awayMessage;
    IBOutlet	NSButton		*button_setAwayMessage;
    IBOutlet	NSButton		*button_save;
    IBOutlet	NSScrollView		*scrollView_awayMessageContainer;

    IBOutlet	NSPanel			*savePanel;
    IBOutlet	NSButton		*savePanel_saveButton;
    IBOutlet	NSButton		*savePanel_cancelButton;
    IBOutlet	NSTextField		*textField_title;
    
    NSMutableArray			*awayMessageArray;

    BOOL	loaded_message;
}

+ (AIEnterAwayWindowController *)enterAwayWindowController;
- (IBAction)closeWindow:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)setAwayMessage:(id)sender;
- (IBAction)save:(id)sender;

- (IBAction)endSheet:(id)sender;
- (void)saveSheetClosed:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
