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

#import <Adium/Adium.h>
#import "AIInterfaceController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"

@interface AIInterfaceController (PRIVATE)
- (void)loadDualInterface;
@end

@implementation AIInterfaceController

//init
- (void)initController
{     
    contactListViewArray = [[NSMutableArray alloc] init];
    messageViewArray = [[NSMutableArray alloc] init];
    interfaceArray = [[NSMutableArray alloc] init];
}

- (void)closeController
{
    [[interfaceArray objectAtIndex:0] closeInterface]; //Close the interface
}

//dealloc
- (void)dealloc
{
    [contactListViewArray release]; contactListViewArray = nil;
    [messageViewArray release]; messageViewArray = nil;
    [interfaceArray release]; interfaceArray = nil;
    
    [interfaceNotificationCenter release]; interfaceNotificationCenter = nil;
    
    [super dealloc];
}

- (void)finishIniting
{
    //Load the interface
    [[interfaceArray objectAtIndex:0] openInterface];
}


//Called by the 'new message' menu, initiates a message
- (IBAction)initiateMessage:(id)sender
{
    //initiate message with a nil Handle, the interface should prompt for a handle
    [[self interfaceNotificationCenter] postNotificationName:Interface_InitiateMessage object:nil userInfo:nil];
}

//Notification center for interface notifications
- (NSNotificationCenter *)interfaceNotificationCenter
{
    if(interfaceNotificationCenter == nil){
        interfaceNotificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return(interfaceNotificationCenter);
}


// Registers code to handle the interface
- (void)registerInterfaceController:(id <AIInterfaceController>)inController
{
    [interfaceArray addObject:inController];
}


// Registers a view to handle the contact list.  The user may chose from the available views
// The view only needs to be added to the interface, it is entirely self sufficient
- (void)registerContactListViewController:(id <AIContactListViewController>)inController
{
    [contactListViewArray addObject:inController];
}
- (id <AIContactListViewController>)contactListViewController
{
    return([contactListViewArray objectAtIndex:0]);
}


// Registers a view to handle the contact list.  The user may chose from the available views
// The view only needs to be added to the interface, it is entirely self sufficient
- (void)registerMessageViewController:(id <AIMessageViewController>)inController
{
    [messageViewArray addObject:inController];
}
- (NSView *)messageViewForHandle:(AIContactHandle *)inHandle
{
    return([[messageViewArray objectAtIndex:0] messageViewForHandle:inHandle]);
}


//Errors
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    NSDictionary	*errorDict;

    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",nil];    
    [[self interfaceNotificationCenter] postNotificationName:Interface_ErrorMessageRecieved object:nil userInfo:errorDict];
}


@end









