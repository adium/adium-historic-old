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

#import "AINewGroupWindowController.h"

#define ADD_GROUP_PROMPT_NIB	@"AddGroup"

@implementation AINewGroupWindowController

//Prompt for a new group.  Pass nil for a panel prompt.
+ (void)promptForNewGroupOnWindow:(NSWindow *)parentWindow
{
	AINewGroupWindowController	*newGroupWindow;
	
	newGroupWindow = [[self alloc] initWithWindowNibName:ADD_GROUP_PROMPT_NIB];
	
	if(parentWindow){
		[NSApp beginSheet:[newGroupWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newGroupWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[newGroupWindow showWindow:nil];
	}
	
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[[self window] center];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

//Add the contact
- (IBAction)addGroup:(id)sender
{
	[[adium contactController] groupWithUID:[textField_groupName stringValue]];
	
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

@end
