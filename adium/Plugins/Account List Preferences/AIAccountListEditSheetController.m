/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAccountListEditSheetController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define		ACCOUNT_EDIT_SHEET_NIB		@"AccountPrefEditSheet"

@interface AIAccountListEditSheetController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount owner:(id)inOwner;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)configureStandardOptions;
- (void)configureAccountOptionsView;
@end

@implementation AIAccountListEditSheetController

+ (void)showAccountListEditSheetForAccount:(AIAccount *)inAccount onWindow:(NSWindow *)inWindow owner:(id)inOwner
{
    AIAccountListEditSheetController	*controller = [[self alloc] initWithWindowNibName:ACCOUNT_EDIT_SHEET_NIB forAccount:inAccount owner:inOwner];

    [NSApp beginSheet:[controller window] modalForWindow:inWindow modalDelegate:controller didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)toggleAutoConnect:(id)sender
{
    //Change the account's value
    [[account properties] setObject:[NSNumber numberWithBool:(BOOL)[button_autoConnect intValue]] forKey:@"AutoConnect"];
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_PropertiesChanged
                                                    object:account
                                                userInfo:nil];    
}

- (IBAction)togglePasswordStorage:(id)sender
{
    if([button_savePassword state] != NSOnState){
        //remove password from keychain
        [[owner accountController] forgetPasswordForAccount:account];
    }

    //Change the account's value
    [[account properties] setObject:[NSNumber numberWithBool:(BOOL)[button_savePassword intValue]] forKey:@"SavedPassword"];
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_PropertiesChanged
                                                    object:account
                                                userInfo:nil];
}

// User selected a service type from the menu
- (IBAction)selectServiceType:(id)sender
{
    id <AIServiceController>	service = [sender representedObject];

    //Switch it
    [account autorelease];
    account = [[[owner accountController] switchAccount:account toService:service] retain];

    //reconfigure
    [self configureAccountOptionsView];
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


// Private ------------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName];

    owner = [inOwner retain];
    account = [inAccount retain];

    //observe
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(configureStandardOptions) name:Account_PropertiesChanged object:nil];

    return(self);
}

- (void)dealloc
{
    [[[owner accountController] accountNotificationCenter] removeObserver:self];
    [account release];
    [owner release];

    [super dealloc];
}

- (void)windowDidLoad
{
    NSEnumerator		*enumerator;
    id <AIServiceController>	service;
    
    //build the service list
    enumerator = [[[owner accountController] availableServiceArray] objectEnumerator];
    [popupMenu_serviceList removeAllItems];
    while((service = [enumerator nextObject])){
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[service description] target:self action:@selector(selectServiceType:) keyEquivalent:@""] autorelease];
    
        [item setRepresentedObject:service];
        [[popupMenu_serviceList menu] addItem:item];
    }

    //Configure
    [self configureAccountOptionsView];
    [self configureStandardOptions];
}

//configure this account's standard options
- (void)configureStandardOptions
{
    BOOL	savedPassword = ([[[account properties] objectForKey:@"SavedPassword"] boolValue]);
    BOOL	autoConnect = ([[[account properties] objectForKey:@"AutoConnect"] boolValue]);

    [button_savePassword setState:savedPassword];
//    [button_autoConnect setEnabled:savedPassword];
    [button_autoConnect setState:autoConnect];
}

//configure the account specific options
- (void)configureAccountOptionsView
{
    NSView		*accountView;
    NSRect		containerFrame;
    NSRect		newFrame;
    NSWindow		*window = [self window];

    //remove the existing account view
    [view_accountDetails removeAllSubviews];

    //select the correct service in the service menu
    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:[account service]]];

    //Correctly size the sheet for the account details view
    accountView = [account accountView];
    containerFrame = [window frame];
    containerFrame.size.height -= [view_accountDetails frame].size.height;
    containerFrame.size.height += [accountView frame].size.height;
//    [window setFrame:[NSWindow frameRectForContentRect:containerFrame styleMask:[window styleMask]] display:NO];            
    
    newFrame = [window frame];
    newFrame.size.height = containerFrame.size.height;
    newFrame.origin.y += ([window frame].size.height - containerFrame.size.height);
    [window setFrame:newFrame display:YES animate:YES];


    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
    [accountView setFrameOrigin:NSMakePoint(0,0)];
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    [NSApp endSheet:[self window]];
    [self autorelease];

    return(YES);
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}
    
@end
