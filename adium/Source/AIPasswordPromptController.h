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

@interface AIPasswordPromptController : AIWindowController {

    IBOutlet	NSTextField	*textField_password;
    IBOutlet	NSButton	*checkBox_savePassword;

    SEL 		selector;
    id			target;

}

- (id)initWithWindowNibName:(NSString *)windowNibName notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)windowDidLoad;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)togglePasswordSaved:(id)sender;
- (NSString *)savedPasswordKey;
- (void)savePassword:(NSString *)password;
- (BOOL)windowShouldClose:(id)sender;
@end
