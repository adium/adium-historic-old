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
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount owner:(id)inOwner deleteOnCancel:(BOOL)delo;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)configureStandardOptions;
- (void)configureAccountOptionsView;
@end

@implementation AIAccountListEditSheetController

+ (void)showAccountListEditSheetForAccount:(AIAccount *)inAccount onWindow:(NSWindow *)inWindow owner:(id)inOwner deleteOnCancel:(BOOL)delo
{
    AIAccountListEditSheetController	*controller = [[self alloc] initWithWindowNibName:ACCOUNT_EDIT_SHEET_NIB forAccount:inAccount owner:inOwner deleteOnCancel:delo];

    [NSApp beginSheet:[controller window] modalForWindow:inWindow modalDelegate:controller didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
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

// Save changes and close the sheet
- (IBAction)okay:(id)sender
{
    BOOL	autoConnect = [button_autoConnect intValue];
    BOOL	savePassword = [button_savePassword state];
    
    //Let the account save
    if(accountViewController) [accountViewController saveChanges];

    //Autoconnect
    [[account properties] setObject:[NSNumber numberWithBool:autoConnect] forKey:@"AutoConnect"];

    //Save Password
    //If the user unchecked 'savePassword', we tell Adium to forget it
    if([[[account properties] objectForKey:@"SavedPassword"] boolValue] && !savePassword){
        [[owner accountController] forgetPasswordForAccount:account];
    }
    [[account properties] setObject:[NSNumber numberWithBool:savePassword] forKey:@"SavedPassword"];
    
    //Broadcast a properties changed notification so everyone can update
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_PropertiesChanged object:account userInfo:nil];
    
    [self closeWindow:nil];
}    

// closes this window and delete the account we got here from clicking the "new" button
- (IBAction)closeWindow:(id)sender
{
    if(![[sender title] isEqualToString:@"Cancel"] /*|| [account isEqual:[[owner accountController] defaultAccount]]*/) // if we hit the cancel button, OR if the account is still a blank account (2nd part not implimented)
    {
        del = NO;  // if we hit OK, we only want to close the window!
    }
    
    if(del == NO)
    {
        if([self windowShouldClose:nil])
        {
            [[self window] close];
        }
    }
    else
    {
        if([self windowShouldClose:nil]) 
        {
            [[owner accountController] deleteAccount:account];
            [[self window] close];
        }
    }
}


// Private ------------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount owner:(id)inOwner deleteOnCancel:(BOOL)delo;
{
    [super initWithWindowNibName:windowNibName];

    owner = [inOwner retain];
    account = [inAccount retain];
    del = delo;
    //observe
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(configureStandardOptions) name:Account_PropertiesChanged object:nil];

    return(self);
}

- (void)dealloc
{
    [[[owner accountController] accountNotificationCenter] removeObserver:self];
    [account release];
    [owner release];
    [accountViewController release];
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
    [button_autoConnect setState:autoConnect];
}

//configure the account specific options
- (void)configureAccountOptionsView
{
    NSWindow		*window = [self window];
    NSView		*accountView;
    NSRect		containerFrame;
    NSRect		newFrame;

    //Close any currently open controllers, saving changes(?)
    if(accountViewController){ 
        [accountViewController saveChanges];
        [accountViewController release]; accountViewController = nil;
    }
    [view_accountDetails removeAllSubviews];

    //select the correct service in the service menu
    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:[account service]]];

    //Correctly size the sheet for the account details view
    accountViewController = [[account accountView] retain];
    accountView = [accountViewController view];
    containerFrame = [window frame];
    containerFrame.size.height -= [view_accountDetails frame].size.height;
    containerFrame.size.height += [accountView frame].size.height;
    
    newFrame = [window frame];
    newFrame.size.height = containerFrame.size.height;
    newFrame.origin.y += ([window frame].size.height - containerFrame.size.height);
    [window setFrame:newFrame display:YES animate:YES];

    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
    [accountView setFrameOrigin:NSMakePoint(0,0)];
    if([accountViewController conformsToProtocol:@protocol(AIAccountViewController)])
    {
        [accountViewController configureViewAfterLoad]; //allow the account subview to set itself up after the window has loaded
    }
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
