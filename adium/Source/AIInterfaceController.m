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
#define MAX_TOOLTIP_ENTRY_WIDTH                 45.0
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
    NSString                    *displayName = [object displayName];
    NSString                    *uid = [object UID];
    //Configure fonts and attributes
    NSFontManager       *fontManager = [NSFontManager sharedFontManager];
    
    NSFont              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    
    NSDictionary        *labelDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSDictionary        *entryDict =[NSDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    NSMutableDictionary *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:2] , NSFontAttributeName, nil];
    NSDictionary        *titleDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil];
    
    NSMutableAttributedString * titleString = [[NSMutableAttributedString alloc] init];
    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([displayName compare:uid] == 0){
        [titleString appendString:[NSString stringWithFormat:@"%@",displayName] withAttributes:titleDict];
    }else{
        [titleString appendString:[NSString stringWithFormat:@"%@ (%@)",displayName,uid] withAttributes:titleDict];
    }
    
    if ([object isKindOfClass:[AIListContact class]]){
        [titleString appendString:[NSString stringWithFormat:@" \t%@",[object serviceID]]
                   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                       [fontManager convertFont:[NSFont toolTipsFontOfSize:9] 
                                    toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil]];
    }
    
    //Entries from plugins
    id <AIContactListTooltipEntry>	tooltipEntry;
    NSEnumerator			*enumerator;
    enumerator = [contactListTooltipEntryArray objectEnumerator];
    BOOL isFirst = YES;
    while((tooltipEntry = [enumerator nextObject])){
        NSString	*entryString = [tooltipEntry entryForObject:object];
        if (entryString && [entryString length]) {
            if (isFirst) {
                [titleString appendString:@"\r\r" withAttributes:labelEndLineDict];
                [titleString appendString:[NSString stringWithFormat:@"%@: ",[tooltipEntry labelForObject:object]] withAttributes:labelDict];
                isFirst = NO;
            } else {
                //Add a carriage return and the label
                [titleString appendString:[NSString stringWithFormat:@"\r%@: ",[tooltipEntry labelForObject:object]] withAttributes:labelDict];
            }
            [titleString appendString:entryString withAttributes:entryDict];
        }
    }
    return [titleString autorelease];
}

- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString	*tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    NSFontManager       *fontManager = [NSFontManager sharedFontManager];
    NSFont              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    
    NSMutableDictionary        *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary        *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:1] , NSFontAttributeName, nil];
    NSMutableDictionary        *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    //Entries from plugins
    id <AIContactListTooltipEntry>  tooltipEntry;
    NSEnumerator                    *enumerator;
    NSEnumerator                    *labelEnumerator;
    NSMutableAttributedString       *lineBreakAndSpaceToColumnString = nil;     
    NSMutableArray                  *labelArray = [[NSMutableArray alloc] init];
    NSMutableArray                  *entryArray = [[NSMutableArray alloc] init];    
    NSMutableString                 *entryString;
    float                           maxLabelWidth = 0;
    float                           labelWidth;
    int                             lineBreakAndSpaceToColumnStringLength;
    BOOL                            firstEntry = YES;
    BOOL                            keepSearching;
    
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
    NSArray * tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType location:maxLabelWidth],[[NSTextTab alloc] initWithType:NSLeftTabStopType location:maxLabelWidth+1],nil];
    [paragraphStyle setTabStops:tabArray];
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
        NSMutableAttributedString * labelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:",[labelEnumerator nextObject]]
                                                                                         attributes:labelDict];
        
        //Add a tab to the label to make lining up multiple-line entries a whole lot easier
        [labelString appendString:@"\t " withAttributes:labelDict];
        
        if (firstEntry) {
            //Add the label (with its spacing)
            [tipString appendAttributedString:labelString];
            firstEntry = NO;
        } else {
            //Add a carriage return, skip a line, then add the label (with its spacing)
            [tipString appendString:@"\r\r" withAttributes:labelEndLineDict];
            [tipString appendAttributedString:labelString];
        }
        
        //convert returns to new lines so return can be used internally without interference
        [entryString replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [entryString length])];
        
        NSMutableAttributedString * entryAttribString = [[NSMutableAttributedString alloc] initWithString:entryString attributes:entryDict];
        
        int lineBreakIndex = 0; 
        int entryAttribStringLength = [entryAttribString length];
        entryAttribStringLength--; //make the length relative to an index instead of being a count

        NSRange remainingRange = NSMakeRange(0, entryAttribStringLength);
        
        while ((entryAttribStringLength - lineBreakIndex) > MAX_TOOLTIP_ENTRY_WIDTH) {  
            //Jump from line ending to line ending until we find a line which needs wrapping          
            NSString * tempString = [entryAttribString string];
            NSRange nextEndLine = nextEndLine = [tempString rangeOfString:@"\n" options:NSLiteralSearch range:remainingRange];
            if ((nextEndLine.location != NSNotFound)) {
                keepSearching = YES;
                while ( keepSearching && nextEndLine.location < (lineBreakIndex + MAX_TOOLTIP_ENTRY_WIDTH)) {
                    lineBreakIndex = nextEndLine.location + 1;
                    //Update the remaining range to scan
                    remainingRange.location = lineBreakIndex;
                    remainingRange.length = entryAttribStringLength - lineBreakIndex + 1; //length is from 0 instead of 1, so add 1
                    nextEndLine = [tempString rangeOfString:@"\n" options:NSLiteralSearch range:remainingRange];
                    if (nextEndLine.location == NSNotFound) {
                        keepSearching = NO;
                    }
                }
            }
            
            if (lineBreakIndex < (entryAttribStringLength-MAX_TOOLTIP_ENTRY_WIDTH)) {
                lineBreakIndex += MAX_TOOLTIP_ENTRY_WIDTH;
                
                //Find the first character of the current word
                lineBreakIndex = [entryAttribString nextWordFromIndex:lineBreakIndex forward:NO];
                
                //Replace the space before it with the line-break plus tabs
                [entryAttribString insertAttributedString:lineBreakAndSpaceToColumnString atIndex:lineBreakIndex-1];
                entryAttribStringLength += lineBreakAndSpaceToColumnStringLength;

                //Update the remaining range to scan
                remainingRange.location = lineBreakIndex;
                remainingRange.length = entryAttribStringLength - lineBreakIndex;  
            }
        }
        
        NSMutableString * finalEntryString = [[entryAttribString string] mutableCopy];
        
        //convert new lines (and returns which were changed to new lines before the while loop) into new-line-plus-tabs
        [finalEntryString replaceOccurrencesOfString:@"\n" withString:[NSString stringWithFormat:@"%@ ",[lineBreakAndSpaceToColumnString string]] options:NSLiteralSearch range:NSMakeRange(0, [finalEntryString length])];
        
        //Add the entry
        [tipString appendString:finalEntryString withAttributes:entryDict];
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