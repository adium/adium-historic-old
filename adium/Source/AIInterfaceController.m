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
#define LABEL_ENTRY_SPACING                     4.0
#define DISPLAY_IMAGE_ON_RIGHT                  NO

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
    contactListTooltipSecondaryEntryArray = [[NSMutableArray alloc] init];
    
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
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray addObject:inEntry];
    else
        [contactListTooltipEntryArray addObject:inEntry];
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atPoint:(NSPoint)point
{
    if(object){
        if(object == tooltipListObject){ //If we already have this tooltip open
            //Move the existing tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle body:tooltipBody image:tooltipImage imageOnRight:DISPLAY_IMAGE_ON_RIGHT onWindow:nil atPoint:point orientation:TooltipBelow];

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
                tooltipImage = nil;
            }
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle body:tooltipBody image:tooltipImage imageOnRight:DISPLAY_IMAGE_ON_RIGHT onWindow:nil atPoint:point orientation:TooltipBelow];
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
    NSMutableAttributedString * titleString = [[NSMutableAttributedString alloc] init];
    
    id <AIContactListTooltipEntry>	tooltipEntry;
    NSEnumerator			*enumerator;
    NSEnumerator                        *labelEnumerator;
    NSMutableArray                      *labelArray = [[NSMutableArray alloc] init];
    NSMutableArray                      *entryArray = [[NSMutableArray alloc] init];
    NSArray                             *tabArray;
    NSMutableString                     *entryString;
    float                               maxLabelWidth = 0;
    float                               labelWidth;
    BOOL                                isFirst = YES;
    
    NSString                            *displayName = [object displayName];
    NSString                            *uid = [object UID];
    
    //Configure fonts and attributes
    NSFontManager                       *fontManager = [NSFontManager sharedFontManager];
    NSFont                              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary                 *titleDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil];
    NSMutableDictionary                 *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary                 *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:2] , NSFontAttributeName, nil];
    NSMutableDictionary                 *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    NSMutableParagraphStyle             *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([displayName compare:uid] == 0){
        [titleString appendString:[NSString stringWithFormat:@"%@",displayName] withAttributes:titleDict];
    }else{
        [titleString appendString:[NSString stringWithFormat:@"%@ (%@)",displayName,uid] withAttributes:titleDict];
    }
    
    
    //Add the serviceID, three spaces away
    if ([object isKindOfClass:[AIListContact class]]){
        [titleString appendString:[NSString stringWithFormat:@"   %@",[object serviceID]]
                   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                       [fontManager convertFont:[NSFont toolTipsFontOfSize:9] 
                                    toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil]];
    }
    
    //Entries from plugins
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] attributes:labelDict];
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
    }
    
    //Set a right-align tab at the maximum label width and a left-align just past it
    tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType location:maxLabelWidth],[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxLabelWidth + LABEL_ENTRY_SPACING],nil];
    [paragraphStyle setTabStops:tabArray];
    [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
    [labelDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [labelEndLineDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [entryDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    
    while((entryString = [enumerator nextObject])){        
        NSAttributedString * labelString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t ",[labelEnumerator nextObject]]
                                                                           attributes:labelDict];
        
        //Add a carriage return
        [titleString appendString:@"\r" withAttributes:labelEndLineDict];
        
        if (isFirst) {
            //skip a line
            [titleString appendString:@"\r" withAttributes:labelEndLineDict];
            isFirst = NO;
        }
        
        //Add the label (with its spacing)
        [titleString appendAttributedString:labelString];
        [titleString appendString:entryString withAttributes:entryDict];
    }
    return [titleString autorelease];
}

- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString       *tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    NSFontManager                   *fontManager = [NSFontManager sharedFontManager];
    NSFont                          *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary             *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary             *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:1] , NSFontAttributeName, nil];
    NSMutableDictionary             *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    NSMutableParagraphStyle         *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    //Entries from plugins
    id <AIContactListTooltipEntry>  tooltipEntry;
    NSEnumerator                    *enumerator;
    NSEnumerator                    *labelEnumerator;
    NSMutableAttributedString       *lineBreakAndSpaceToColumnString = nil;     
    NSMutableArray                  *labelArray = [[NSMutableArray alloc] init];
    NSMutableArray                  *entryArray = [[NSMutableArray alloc] init];    
    NSArray                         *tabArray;
    NSMutableString                 *entryString;
    float                           maxLabelWidth = 0;
    float                           labelWidth;
    int                             lineBreakAndSpaceToColumnStringLength;
    BOOL                            firstEntry = YES;
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipSecondaryEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] attributes:labelDict];
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
    }
    
    //Set a right-align tab at the maximum label width and a left-align just past it
    tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType location:maxLabelWidth],[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxLabelWidth + LABEL_ENTRY_SPACING],nil];
    [paragraphStyle setTabStops:tabArray];
    [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
    
    [labelDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [labelEndLineDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [entryDict setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    
    //Used for wrapping text to the tabbed location
    lineBreakAndSpaceToColumnString = [[NSMutableAttributedString alloc] initWithString:@"\r\t\t" attributes:entryDict]; 
    lineBreakAndSpaceToColumnStringLength = [lineBreakAndSpaceToColumnString length];
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    while((entryString = [enumerator nextObject])){
        NSMutableAttributedString * labelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
                                                                                         attributes:labelDict];
        
        if (firstEntry) {
            firstEntry = NO;
        } else {
            //Add a carriage return and skip a line
            [tipString appendString:@"\r\r" withAttributes:labelEndLineDict];
        }
        
        //Add the label (with its spacing)
        [tipString appendAttributedString:labelString];
        
        
       //headIndent doesn't apply to the first line of a paragraph... so when new lines are in the entry, we need to tab over to the proper location
        [entryString replaceOccurrencesOfString:@"\r" withString:@"\r\t\t" options:NSLiteralSearch range:NSMakeRange(0, [entryString length])];
        [entryString replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:NSLiteralSearch range:NSMakeRange(0, [entryString length])];
        
      [tipString appendString:entryString withAttributes:entryDict];
                
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