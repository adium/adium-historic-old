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
#import <AIUtilities/AIUtilities.h>
#import "AIInterfaceController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"

@interface AIInterfaceController (PRIVATE)
- (void)loadDualInterface;
- (void)flashTimer:(NSTimer *)inTimer;
@end

@implementation AIInterfaceController

//init
- (void)initController
{     
    contactListViewArray = [[NSMutableArray alloc] init];
    messageViewArray = [[NSMutableArray alloc] init];
    interfaceArray = [[NSMutableArray alloc] init];

    flashObserverArray = nil;
    flashTimer = nil;
    flashState = 0;
    
    [owner registerEventNotification:Interface_ErrorMessageReceived displayName:@"Error"];
    [owner registerEventNotification:Interface_InitiateMessage displayName:@"Initiate Message"];
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
    [[owner notificationCenter] postNotificationName:Interface_InitiateMessage object:nil userInfo:nil];
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
- (NSView *)messageViewForContact:(AIListContact *)inContact
{
    return([[messageViewArray objectAtIndex:0] messageViewForContact:inContact]);
}


//Errors
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    NSDictionary	*errorDict;

    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",nil];    
    [[owner notificationCenter] postNotificationName:Interface_ErrorMessageReceived object:nil userInfo:errorDict];
}


//Flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Create a flash observer array and install the flash timer
    if(flashObserverArray == nil){
        flashObserverArray = [[NSMutableArray alloc] init];
        flashTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) target:self selector:@selector(flashTimer:) userInfo:nil repeats:YES] retain];
    }

    //Add the new observer to the array
    [flashObserverArray addObject:inObserver];
}

- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Remove the observer from our array
    [flashObserverArray removeObject:inObserver];

    //Release the observer array and uninstall the timer
    if([flashObserverArray count] == 0){
        [flashObserverArray release]; flashObserverArray = nil;
        [flashTimer invalidate];
        [flashTimer release]; flashTimer = nil;
    }
}

- (void)flashTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    id<AIFlashObserver>	observer;

    flashState++;

    enumerator = [flashObserverArray objectEnumerator];
    while((observer = [enumerator nextObject])){
        [observer flash:flashState];
    }
}

- (int)flashState
{
    return(flashState);
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atPoint:(NSPoint)point
{
    if(object){
        [AITooltipUtilities showTooltipWithString:[NSString stringWithFormat:@"%@ (%@)",[object displayName],[object UID]] onWindow:nil atPoint:point];
    }else{
        [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:point];
    }
}




@end









