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
#define ERROR_MESSAGE_WINDOW_TITLE		@"Adium : Error"

@interface AIInterfaceController (PRIVATE)
- (void)loadDualInterface;
- (void)flashTimer:(NSTimer *)inTimer;
- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object;
- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object;
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
    tooltipTitle = nil;
    tooltipBody = nil;
    tooltipImage = nil;
    flashObserverArray = nil;
    flashTimer = nil;
    flashState = 0;
    
    [owner registerEventNotification:Interface_ErrorMessageReceived displayName:@"Error"];
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


//Interface chat opening and closing
- (IBAction)initiateMessage:(id)sender
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] initiateNewMessage];
}

- (void)openChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] openChat:inChat];
}

- (void)closeChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] closeChat:inChat];
}

- (void)setActiveChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] setActiveChat:inChat];
}

- (void)transferMessageTabContainer:(id)tabViewItem toWindow:(id)newMessageWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] transferMessageTabContainer:tabViewItem toWindow:newMessageWindow atIndex:index withTabBarAtPoint:(NSPoint)screenPoint];
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
    [self handleMessage:inTitle withDescription:inDesc withWindowTitle:ERROR_MESSAGE_WINDOW_TITLE];
}

- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;
{
    NSDictionary	*errorDict;

    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",inWindowTitle,@"Window Title",nil];
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
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle body:tooltipBody image:tooltipImage onWindow:nil atPoint:point orientation:TooltipBelow];

        }else{ //This is a new tooltip
            //Hold onto the new object
            [tooltipListObject release];
            tooltipListObject = [object retain];

            [tooltipTitle release]; tooltipTitle = nil;
            tooltipTitle = [[self _tooltipTitleForObject:object] retain];
            
            //Build a tooltip string for the new object
            [tooltipBody release]; tooltipBody = nil;
            tooltipBody = [[self _tooltipBodyForObject:object] retain];
            
            [tooltipImage release]; tooltipImage = nil;
            //Buddy Icon
            AIMutableOwnerArray *ownerArray = [tooltipListObject statusArrayForKey:@"BuddyImage"];
            if(ownerArray && [ownerArray count]){
                tooltipImage = [[ownerArray objectAtIndex:0] retain];
            }else{
                tooltipImage = [[AIImageUtilities imageNamed:@"DefaultIcon" forClass:[self class]] retain];
            }
            
            //If a body exists, add a blank line to the title to provide white space between the two
            //if ([tooltipBody length])
            //    [tooltipTitle appendAttributedString:[[NSAttributedString alloc] initWithString:@"\r"]];
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle body:tooltipBody image:tooltipImage onWindow:nil atPoint:point orientation:TooltipBelow];
        }

    }else{
        //Hide the existing tooltip
        if(tooltipListObject){
            [AITooltipUtilities showTooltipWithTitle:nil body:nil image:nil onWindow:nil atPoint:point orientation:TooltipBelow];
            [tooltipListObject release]; tooltipListObject = nil;
        }
    }
}

- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object
{
    NSString                    *displayName = [object displayName];
    NSString                    *uid = [object UID];
    
    NSDictionary        *titleDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:1], NSUnderlineStyleAttributeName, [NSFont toolTipsFontOfSize:12], NSFontAttributeName, nil];
    
    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([displayName compare:uid] == 0){
        return [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",displayName] attributes:titleDict] autorelease];
    }else{
        return [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)",displayName,uid] attributes:titleDict] autorelease];
    }
}
- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString	*tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    //NSFontManager       *fontManager = [NSFontManager sharedFontManager];
    NSFont              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    
    NSDictionary        *labelDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont toolTipsFontOfSize:9], NSFontAttributeName, nil];
    NSDictionary        *entryDict =[NSDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    //entries from plugins
    if([contactListTooltipEntryArray count] != 0){
        id <AIContactListTooltipEntry>	tooltipEntry;
        NSEnumerator			*enumerator;
        
        //Calculate the widest label
        enumerator = [contactListTooltipEntryArray objectEnumerator];
        int maxLabelSize = 0;
        int labelSize;
        while (tooltipEntry = [enumerator nextObject]){
            //The largest size should be the label's size plus the distance to the next tab at least a space past its end
            NSAttributedString * labelString = [[NSAttributedString alloc] initWithString:
                 [NSString stringWithFormat:@"%@ \t",[tooltipEntry label]] attributes:labelDict];
            labelSize = [labelString size].width;
            
            if (labelSize > maxLabelSize)
                maxLabelSize = labelSize;
        }
        
        BOOL firstEntry = YES;
        //Add labels plus entires to the toolTip
        enumerator = [contactListTooltipEntryArray objectEnumerator];
        while((tooltipEntry = [enumerator nextObject])){
            NSString	*entryString = [tooltipEntry entryForObject:object];
            if(entryString){
                //Tab over from each label until it has the width of the widest one (plus the widest one's tab)
                NSMutableString * labelString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[tooltipEntry label]]]; 
                while (maxLabelSize >= [[[NSMutableAttributedString alloc] initWithString:labelString attributes:labelDict] size].width) {
                    [labelString appendString:@"\t"];
                }
                
                if (firstEntry) {
                    //Add the label (with its spacing)
                    [tipString appendString:labelString withAttributes:labelDict];
                    firstEntry = NO;
                } else {
                    //Add a carriage return and the label (with its spacing)
                    [tipString appendString:[NSString stringWithFormat:@"\r%@",labelString]
                         withAttributes:labelDict];
                }
                //Add the entry
                [tipString appendString:entryString withAttributes:entryDict];
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