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

#import "AIAccountSetupWindowController.h"
#import "AIAccountSetupView.h"

#define ACCOUNT_SETUP_WINDOW_NIB			@"AccountSetupWindow"

@interface AIAccountSetupWindowController (PRIVATE)

@end

@implementation AIAccountSetupWindowController

AIAccountSetupWindowController *sharedAccountSetupWindowInstance = nil;
+ (AIAccountSetupWindowController *)accountSetupWindowController
{
    if(!sharedAccountSetupWindowInstance){
        sharedAccountSetupWindowInstance = [[self alloc] initWithWindowNibName:ACCOUNT_SETUP_WINDOW_NIB];
    }
    return(sharedAccountSetupWindowInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

	activeView = nil;
	
    return(self);
}

//Dealloc
- (void)dealloc
{    
	[self setActiveSetupView:nil];
    [super dealloc];
}

//Configure the preference view
- (void)windowDidLoad
{	
	//Start on overview
	[self showAccountsOverview];

	//Center this panel
	[[self window] center];
}


//Account overview
- (void)showAccountsOverview
{
	[self setActiveSetupView:view_overview];
}

//New account
- (void)newAccountOnService:(AIService *)service
{
	[view_newAccount configureForService:service];
	[self setActiveSetupView:view_newAccount];
}

//Edit account
- (void)editExistingAccount:(AIAccount *)account
{
	[view_editAccount configureForAccount:account];
	[self setActiveSetupView:view_editAccount];
}






//Close
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//closing
- (BOOL)windowShouldClose:(id)sender
{
	[sharedAccountSetupWindowInstance autorelease]; sharedAccountSetupWindowInstance = nil;
	
	return(YES);
}


//Views ------------------------------------------------------------------------
#pragma mark
//Set the active setup window view, transitions to the new view
- (void)setActiveSetupView:(AIAccountSetupView *)inView
{
	//Remove the current view
	if(activeView){
		[activeView viewWillClose];
		activeView = nil;
	}

	//Insert the new view
	if(inView){
		activeView = inView;//[inView retain];
		[[self window] setContentView:activeView];
		[activeView viewDidLoad];
	}

	//Resize window
	[self sizeWindowForContent];
}

//Resize the window for the displayed content view
- (void)sizeWindowForContent
{
	NSSize size = [activeView desiredSize];
	NSLog(@"sizewindow to %i %i",(int)size.width,(int)size.height);
	[[self window] setContentSize:[activeView desiredSize] display:YES animate:[[self window] isVisible]];
}

@end
