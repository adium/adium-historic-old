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
#define MAX_TOOLTIP_ENTRY_WIDTH                 200.0
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
    
    NSDictionary        *titleDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil];
    
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
    
    //Entries from plugins
    if([contactListTooltipEntryArray count] != 0){
        id <AIContactListTooltipEntry>	tooltipEntry;
        NSEnumerator			*enumerator;
        NSMutableAttributedString       *lineBreakAndTabToColumnString = nil;     
        int                             lineBreakAndTabToColumnStringLength;
        BOOL                            firstEntry = YES;
        
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
        
        //Add labels plus entires to the toolTip
        enumerator = [contactListTooltipEntryArray objectEnumerator];
        
        while((tooltipEntry = [enumerator nextObject])){
            NSMutableString	*entryString = [[tooltipEntry entryForObject:object] mutableCopy];
            if(entryString && [entryString length]){
                //Tab over from each label until it has the width of the widest one (plus the widest one's tab)
                //  NSMutableAttributedString * labelString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[tooltipEntry label]]]; 
                NSMutableAttributedString * labelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[tooltipEntry label]]
                                                                                                 attributes:labelDict];
                //Add tabs after the label to line the entries up in a column
                while (maxLabelSize >= [labelString size].width) {
                    [labelString appendString:@"\t" withAttributes:labelDict];
                }
                //Generate the tab-to-column string; it's the same for each entry so only generate it once if at all
                if (!lineBreakAndTabToColumnString) {
                    lineBreakAndTabToColumnString = [[NSMutableAttributedString alloc] initWithString:@"\r" attributes:entryDict];                        
                    while (maxLabelSize >= [lineBreakAndTabToColumnString size].width) {
                        [lineBreakAndTabToColumnString appendString:@"\t" withAttributes:entryDict];
                    }
                    lineBreakAndTabToColumnStringLength = [lineBreakAndTabToColumnString length];
                }
                
                if (firstEntry) {
                    //Add the label (with its spacing)
                    [tipString appendAttributedString:labelString];
                    firstEntry = NO;
                } else {
                    //Add a carriage return and the label (with its spacing)
                    [tipString appendString:@"\r" withAttributes:labelDict];
                    [tipString appendAttributedString:labelString];
                }
                
                //convert returns to new lines so return can be used internally without interference
                [entryString replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [entryString length])];
                
                int entryStringLength = [entryString length];
                NSMutableAttributedString * entryAttribString = [[NSMutableAttributedString alloc] initWithString:entryString attributes:entryDict];
                
                int lineBreakIndex = 0; 

                NSRange replacementRange;   replacementRange.length=1;
                                
                NSRange remainingRange = NSMakeRange(0, [entryAttribString length]);
                float currentSizeForRange = [[entryAttribString attributedSubstringFromRange:remainingRange] size].width;
                
                lineBreakAndTabToColumnStringLength--; //because it will be used to replace a character, its effective change-in-length is one less
                
                while (currentSizeForRange > MAX_TOOLTIP_ENTRY_WIDTH) {           
                    //Hone the length down - the amount the length goes down each time is arbitrary and simply an accuracy-speed tradeoff
                    while (currentSizeForRange > MAX_TOOLTIP_ENTRY_WIDTH) {
                        remainingRange.length -= 4;
                        currentSizeForRange = [[entryAttribString attributedSubstringFromRange:remainingRange] size].width;
                    }
                    
                    //Find the first character of the current word
                    lineBreakIndex = [entryAttribString nextWordFromIndex:(lineBreakIndex + remainingRange.length) forward:NO];
                   
                    //Replace the space before it with the line-break plus tabs
                    replacementRange.location = lineBreakIndex-1;
                    [entryAttribString replaceCharactersInRange:replacementRange withAttributedString:lineBreakAndTabToColumnString];
                    
                    //Update lineBreakIndex
                    lineBreakIndex = lineBreakIndex + lineBreakAndTabToColumnStringLength;
                    
                    //Our string is now lineBreakAndTabToColumnStringLength longer after the replacement
                    entryStringLength += lineBreakAndTabToColumnStringLength;
                    
                    //Update the remaining range to scan
                    remainingRange.location = lineBreakIndex;
                    remainingRange.length = entryStringLength-lineBreakIndex;
                    
                    currentSizeForRange = [[entryAttribString attributedSubstringFromRange:remainingRange] size].width;
                }
                
                NSMutableString * finalEntryString = [[entryAttribString string] mutableCopy];
                //convert new lines (and returns which were changed to new lines before the while loop) into new-line-plus-tabs
                [finalEntryString replaceOccurrencesOfString:@"\n" withString:[lineBreakAndTabToColumnString string] options:NSLiteralSearch range:NSMakeRange(0, [finalEntryString length])];
                
                //Add the entry
                [tipString appendString:finalEntryString withAttributes:entryDict];
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