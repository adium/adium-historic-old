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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIInterfaceController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"

@interface AIInterfaceController (PRIVATE)
- (void)loadDualInterface;
- (void)flashTimer:(NSTimer *)inTimer;
- (NSString *)_tooltipStringForObject:(AIListObject *)object;
@end

@implementation AIInterfaceController

//init
- (void)initController
{     
    contactListViewArray = [[NSMutableArray alloc] init];
    messageViewArray = [[NSMutableArray alloc] init];
    interfaceArray = [[NSMutableArray alloc] init];
    contactListTooltipEntryArray = [[NSMutableArray alloc] init];

    tooltipListObject = nil;
    tooltipString = nil;
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

    //Configure our dynamic paste menu item
    [menuItem_paste setDynamic:YES];
    [menuItem_pasteFormatted setDynamic:YES];
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
- (void)registerContactListViewPlugin:(id <AIContactListViewPlugin>)inPlugin
{
    [contactListViewArray addObject:inPlugin];
}
- (id <AIContactListViewController>)contactListViewController
{
    return([[contactListViewArray objectAtIndex:0] contactListViewController]);
}


// Registers a view to handle the contact list.  The user may chose from the available views
// The view only needs to be added to the interface, it is entirely self sufficient
- (void)registerMessageViewPlugin:(id <AIMessageViewPlugin>)inPlugin
{
    [messageViewArray addObject:inPlugin];
}
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([[messageViewArray objectAtIndex:0] messageViewControllerForChat:inChat]);
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



// Registers code to display tooltip info about a contact
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry
{
    [contactListTooltipEntryArray addObject:inEntry];
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atPoint:(NSPoint)point
{
    if(object){
        if(object == tooltipListObject){ //If we already have this tooltip open
            //Move the existing tooltip
            [AITooltipUtilities showTooltipWithString:tooltipString onWindow:nil atPoint:point orientation:TooltipBelow];

        }else{ //This is a new tooltip
            //Hold onto the new object
            [tooltipListObject release];
            tooltipListObject = [object retain];

            //Build a tooltip string for the new object
            [tooltipString release]; tooltipString = nil;
            tooltipString = [[self _tooltipStringForObject:object] retain];
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithString:tooltipString onWindow:nil atPoint:point orientation:TooltipBelow];
        }

    }else{
        //Hide the existing tooltip
        if(tooltipListObject){
            [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:point orientation:TooltipBelow];
            [tooltipListObject release]; tooltipListObject = nil;
        }
    }
}

- (NSString *)_tooltipStringForObject:(AIListObject *)object
{
    NSMutableString	*tipString = [[NSMutableString alloc] init];
    NSString		*displayName = [object displayName];
    NSString		*uid = [object UID];
    BOOL		firstItem = YES;

    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([displayName compare:uid] == 0){
        [tipString appendString:displayName];
    }else{
        [tipString appendString:[NSString stringWithFormat:@"%@ (%@)",displayName,uid]];
    }

    if([contactListTooltipEntryArray count] != 0){
        id <AIContactListTooltipEntry>	tooltipEntry;
        NSEnumerator			*enumerator;
        
        //Additional entries
        enumerator = [contactListTooltipEntryArray objectEnumerator];
        while((tooltipEntry = [enumerator nextObject])){
            NSString	*labelString = [tooltipEntry label];
            NSString	*entryString = [tooltipEntry entryForObject:object];

            if(entryString){
                if(firstItem){ //Add a divider above the first entry
                    [tipString appendString:@"\r"];
                    firstItem = NO;
                }
                [tipString appendString:[NSString stringWithFormat:@"\r%@: %@",labelString,entryString]];
            }
        }
    }

    return([tipString autorelease]);
}



//Custom pasting ----------------------------------------------------------------------------------------------------
@protocol _RESPONDS_TO_PASTE //Just a temp protocol to suppress compiler warnings
- (void)pasteAsPlainText:(id)sender;
- (void)pasteAsRichText:(id)sender;
- (void)paste:(id)sender;
@end

//Paste, stripping formatting
- (IBAction)paste:(id)sender
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

    if([responder respondsToSelector:@selector(pasteAsPlainText:)]){
        [(NSResponder<_RESPONDS_TO_PASTE> *)responder pasteAsPlainText:sender];

    }else if([responder respondsToSelector:@selector(paste:)]){
        [(NSResponder<_RESPONDS_TO_PASTE> *)responder paste:sender];

    }
}

//Paste with formatting
- (IBAction)pasteFormatted:(id)sender
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

    if([responder respondsToSelector:@selector(pasteAsPlainText:)]){
        [(NSResponder<_RESPONDS_TO_PASTE> *)responder pasteAsRichText:sender];

    }else if([responder respondsToSelector:@selector(paste:)]){
        [(NSResponder<_RESPONDS_TO_PASTE> *)responder paste:sender];

    }
}

@end









