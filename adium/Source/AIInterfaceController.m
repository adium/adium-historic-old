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
#import "AIDualWindowInterface.h"

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
    errorTitleArray = [[NSMutableArray alloc] init];
    errorDescArray =  [[NSMutableArray alloc] init];
}

//dealloc
- (void)dealloc
{
    [contactListViewArray release]; contactListViewArray = nil;
    [messageViewArray release]; messageViewArray = nil;
    [errorTitleArray release]; errorTitleArray = nil;
    [errorDescArray release]; errorDescArray = nil;
    
    [interfaceNotificationCenter release]; interfaceNotificationCenter = nil;
    
    [super dealloc];
}

//Called by the 'new message' menu, initiates a message
- (IBAction)initiateMessage:(id)sender
{
    //initiate message with a nil Handle, the interface should prompt for a handle
    [[self interfaceNotificationCenter] postNotificationName:Interface_InitiateMessage object:nil userInfo:nil];
}

//Hard coded for now
- (void)loadDualInterface
{
    //Load the interface
    NSString	*interfacePath;
    NSBundle	*interfaceBundle;

    //Get the plugin path
    interfacePath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath];

    //Load the plugin
    interfaceBundle = [NSBundle bundleWithPath:[interfacePath stringByAppendingPathComponent:@"Dual Window.AdiumInterface"]];
    if(interfaceBundle != nil){
        //Create an instance of the plugin
        [[[interfaceBundle principalClass] newInstanceOfInterfaceWithOwner:owner] retain];

    }else{
        NSLog(@"Failed to open Interface \"%@\"!",@"temp");
    }    
}

//Notification center for interface notifications
- (NSNotificationCenter *)interfaceNotificationCenter
{
    if(interfaceNotificationCenter == nil){
        interfaceNotificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return(interfaceNotificationCenter);
}

// Registers a view to handle the contact list.  The user may chose from the available views
// The view only needs to be added to the interface, it is entirely self sufficient
- (void)registerContactListViewController:(id <AIContactListViewController>)inController
{
    [contactListViewArray addObject:inController];
}
- (NSView *)contactListView
{
    return([[contactListViewArray objectAtIndex:0] contactListView]);
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

- (void)handleErrorMessage:(NSString *)errorTitle withDescription:(NSString *)errorDesc
{
    if([errorTitleArray count] >= 20){//Only allow error arrays to hold 20 error messages.. we don't want them to grow huge, and everything should be handled for logging already anyway
        [errorTitleArray removeObjectAtIndex:[errorTitleArray count]-1];
        [errorDescArray removeObjectAtIndex:[errorDescArray count]-1];
    }
    [errorTitleArray insertObject:errorTitle atIndex:0];
    [errorDescArray insertObject:errorDesc atIndex:0];
    
    //Post a notification that the error array changed
    [[self interfaceNotificationCenter] postNotificationName:Interface_ErrorArrayChanged object:nil userInfo:nil];
}


- (NSMutableArray *)errorTitleArray
{
    return(errorTitleArray);
};

- (NSMutableArray *)errorDescArray
{
    return(errorDescArray);
};

@end









