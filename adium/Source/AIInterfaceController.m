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

// $Id: AIInterfaceController.m,v 1.64 2004/05/20 09:37:29 evands Exp $

#import "AIInterfaceController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"
#define ERROR_MESSAGE_WINDOW_TITLE		AILocalizedString(@"Adium : Error","Error message window title")
#define LABEL_ENTRY_SPACING				4.0
#define DISPLAY_IMAGE_ON_RIGHT			NO

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT				@"Default Font"


@interface AIInterfaceController (PRIVATE)
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

- (void)finishIniting
{
    //Load the interface
    [[interfaceArray objectAtIndex:0] openInterface];
    
    //Configure our dynamic paste menu item
    [menuItem_paste setDynamic:YES];
    [menuItem_pasteFormatted setDynamic:YES];
}

- (void)closeController
{
    [[interfaceArray objectAtIndex:0] closeInterface]; //Close the interface
}

// Dealloc
- (void)dealloc
{
    [contactListViewArray release]; contactListViewArray = nil;
    [messageViewArray release]; messageViewArray = nil;
    [interfaceArray release]; interfaceArray = nil;
	
    [tooltipListObject release]; tooltipListObject = nil;
	[tooltipTitle release]; tooltipTitle = nil;
	[tooltipBody release]; tooltipBody = nil;
	[tooltipImage release]; tooltipImage = nil;
	
    [super dealloc];
}

- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
    return([(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] handleReopenWithVisibleWindows:visibleWindows]);    
}

// Registers code to handle the interface
- (void)registerInterfaceController:(id <AIInterfaceController>)inController
{
    [interfaceArray addObject:inController];
}

//Contact List -----------------------------------
#pragma mark Contact list
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

//Messaging & Chats -----------------------------------
#pragma mark Messaging & Chats
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

//Interface chat opening and closing
- (IBAction)initiateMessage:(id)sender
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] initiateNewMessage];
}

- (void)setActiveChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] setActiveChat:inChat];
}

- (void)openChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] openChat:inChat];
}

- (void)closeChat:(AIChat *)inChat
{
    [(id <AIInterfaceController>)[interfaceArray objectAtIndex:0] closeChat:inChat];
}

//Errors
#pragma mark Errors
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
#pragma mark Flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Create a flash observer array and install the flash timer
    if(flashObserverArray == nil){
        flashObserverArray = [[NSMutableArray alloc] init];
        flashTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) 
                                                       target:self 
                                                     selector:@selector(flashTimer:) 
                                                     userInfo:nil
                                                      repeats:YES] retain];
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

//Tooltips -----------------------------------
#pragma mark Tooltips

// Registers code to display tooltip info about a contact
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray addObject:inEntry];
    else
        [contactListTooltipEntryArray addObject:inEntry];
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow 
{
    if(object){
        if(object == tooltipListObject){ //If we already have this tooltip open
                                         //Move the existing tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
												body:tooltipBody
											   image:tooltipImage 
										imageOnRight:DISPLAY_IMAGE_ON_RIGHT 
											onWindow:inWindow
											 atPoint:point 
										 orientation:TooltipBelow];
            
        }else{ //This is a new tooltip
            NSArray                     *tabArray;
            NSMutableParagraphStyle     *paragraphStyleTitle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            NSMutableParagraphStyle     *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            
            //Hold onto the new object
            [tooltipListObject release]; tooltipListObject = [object retain];
            
            //Buddy Icon
            [tooltipImage release];
			tooltipImage = [[[tooltipListObject displayArrayForKey:@"UserIcon"] objectValue] retain];
            
            //Reset the maxLabelWidth for the tooltip generation
            maxLabelWidth = 0;
            
            //Build a tooltip string for the primary information
            [tooltipTitle release]; tooltipTitle = [[self _tooltipTitleForObject:object] retain];
            
            //If there is an image, set the title tab and indentation settings independently
            if (tooltipImage) {
                //Set a right-align tab at the maximum label width and a left-align just past it
                tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                   location:maxLabelWidth]
                                                            ,[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                   location:maxLabelWidth + LABEL_ENTRY_SPACING]
                                                            ,nil];
                
                [paragraphStyleTitle setTabStops:tabArray];
                [tabArray release];
                tabArray = nil;
                [paragraphStyleTitle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
                
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName 
                                     value:paragraphStyleTitle
                                     range:NSMakeRange(0,[tooltipTitle length])];
                
                //Reset the max label width since the body will be independent
                maxLabelWidth = 0;
            }
            
            //Build a tooltip string for the secondary information
            [tooltipBody release]; tooltipBody = nil;
            tooltipBody = [[self _tooltipBodyForObject:object] retain];
            
            //Set a right-align tab at the maximum label width for the body and a left-align just past it
            tabArray = [[NSArray alloc] initWithObjects:[[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                 location:maxLabelWidth] autorelease]
                                                        ,[[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                location:maxLabelWidth + LABEL_ENTRY_SPACING] autorelease]
                                                        ,nil];
            [paragraphStyle setTabStops:tabArray];
            [tabArray release];
            [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
            
            [tooltipBody addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipBody length])];
            //If there is no image, also use these settings for the top part
            if (!tooltipImage) {
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipTitle length])];
            }
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
                                                body:tooltipBody 
                                               image:tooltipImage
                                        imageOnRight:DISPLAY_IMAGE_ON_RIGHT
                                            onWindow:inWindow
                                             atPoint:point 
                                         orientation:TooltipBelow];
        }
        
    }else{
        //Hide the existing tooltip
        if(tooltipListObject){
            [AITooltipUtilities showTooltipWithTitle:nil 
                                                body:nil
                                               image:nil 
                                            onWindow:nil
                                             atPoint:point
                                         orientation:TooltipBelow];
            [tooltipListObject release]; tooltipListObject = nil;
			
			[tooltipTitle release]; tooltipTitle = nil;
			[tooltipBody release]; tooltipBody = nil;
			[tooltipImage release]; tooltipImage = nil;
        }
    }
}

- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object
{
    NSMutableAttributedString           *titleString = [[NSMutableAttributedString alloc] init];
    
    id <AIContactListTooltipEntry>		tooltipEntry;
    NSEnumerator						*enumerator;
    NSEnumerator                        *labelEnumerator;
    NSMutableArray                      *labelArray = [NSMutableArray array];
    NSMutableArray                      *entryArray = [NSMutableArray array];
    NSMutableAttributedString           *entryString;
    float                               labelWidth;
    BOOL                                isFirst = YES;
    
    NSString                            *displayName = [object displayName];
    NSString                            *formattedUID = [object formattedUID];
    
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
    
    //"<DisplayName>" (or) "<DisplayName> (<UID>)"
    if([displayName compare:formattedUID] == 0){
        [titleString appendString:[NSString stringWithFormat:@"%@", displayName] withAttributes:titleDict];
    }else{
        [titleString appendString:[NSString stringWithFormat:@"%@ (%@)", displayName, formattedUID] withAttributes:titleDict];
    }
    
    //Add the serviceID, three spaces away
    if ([object isKindOfClass:[AIListContact class]]){
        [titleString appendString:[NSString stringWithFormat:@"   %@",[object displayServiceID]]
                   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                       [fontManager convertFont:[NSFont toolTipsFontOfSize:9] 
                                    toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil]];
    }
    
    if ([object isKindOfClass:[AIListGroup class]]){
        [titleString appendString:[NSString stringWithFormat:@" (%i/%i)",[(AIListGroup *)object visibleCount],[(AIListGroup *)object count]] 
                   withAttributes:titleDict];
    }
    
    //Entries from plugins
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						 attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                [labelAttribString release];
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
        [entryString release];
    }
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    
    while((entryString = [enumerator nextObject])){        
        NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																				 attributes:labelDict];
        
        //Add a carriage return
        [titleString appendString:@"\r" withAttributes:labelEndLineDict];
        
        if (isFirst) {
            //skip a line
            [titleString appendString:@"\r" withAttributes:labelEndLineDict];
            isFirst = NO;
        }
        
        //Add the label (with its spacing)
        [titleString appendAttributedString:labelAttribString];
		[labelAttribString release];
        [titleString appendAttributedString:[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])]];
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
    NSMutableDictionary             *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:1], NSFontAttributeName, nil];
    NSMutableDictionary             *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    //Entries from plugins
    id <AIContactListTooltipEntry>  tooltipEntry;
    NSEnumerator                    *enumerator;
    NSEnumerator                    *labelEnumerator; 
    NSMutableArray                  *labelArray = [NSMutableArray array];
    NSMutableArray                  *entryArray = [NSMutableArray array];    
    NSMutableAttributedString       *entryString;
    float                           labelWidth;
    BOOL                            firstEntry = YES;
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipSecondaryEntryArray objectEnumerator];
    
    while (tooltipEntry = [enumerator nextObject]){
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
                                                                                         attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                [labelAttribString release];
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
        [entryString release];
    }
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    while((entryString = [enumerator nextObject])){
        NSMutableAttributedString *labelString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
                                                                                         attributes:labelDict] autorelease];
        
        if (firstEntry) {
            firstEntry = NO;
        } else {
            //Add a carriage return and skip a line
            [tipString appendString:@"\r\r" withAttributes:labelEndLineDict];
        }
        
        //Add the label (with its spacing)
        [tipString appendAttributedString:labelString];
        
        NSRange fullLength = NSMakeRange(0, [entryString length]);
        
        //remove any background coloration
        [entryString removeAttribute:NSBackgroundColorAttributeName range:fullLength];
        
        //adjust foreground colors for the tooltip background
        [entryString adjustColorsToShowOnBackground:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.800 alpha:1.0]];
#warning should copy get info window behavior instead?
        //headIndent doesn't apply to the first line of a paragraph... so when new lines are in the entry, we need to tab over to the proper location
        if ([entryString replaceOccurrencesOfString:@"\r" withString:@"\r\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
        if ([entryString replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
		
        //Run the entry through the filters and add it to tipString
		entryString = [[[[owner contentController] filterAttributedString:entryString
														usingFilterType:AIFilterDisplay
															  direction:AIFilterIncoming
																context:object] mutableCopy] autorelease];

		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];

        [tipString appendAttributedString:entryString];
    }

    return([tipString autorelease]);
}

//Custom pasting ----------------------------------------------------------------------------------------------------
#pragma mark Custom Pasting
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


//Custom Dimming menu items --------------------------------------------------------------------------------------------
#pragma mark Custom Dimming menu items
//The standard ones do not dim correctly when unavailable
- (IBAction)toggleFontTrait:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    
    if([fontManager traitsOfFont:[fontManager selectedFont]] & [sender tag]){
        [fontManager removeFontTrait:sender];
    }else{
        [fontManager addFontTrait:sender];
    }
}

- (void)toggleToolbarShown:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window toggleToolbarShown:sender];
}

- (void)runToolbarCustomizationPalette:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window runToolbarCustomizationPalette:sender];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [window firstResponder]; 

    if(menuItem == menuItem_bold || menuItem == menuItem_italic){
		NSFont			*selectedFont = [[NSFontManager sharedFontManager] selectedFont];
		
		//We must be in a text view, have text on the pasteboard, and have a font that supports bold or italic
		if([responder isKindOfClass:[NSTextView class]]){
#warning Evan: This should be cached by the font manager additions.
			return (menuItem == menuItem_bold ? [selectedFont supportsBold] : [selectedFont supportsItalics]);
		}
		return(NO);
		
	}else if(menuItem == menuItem_paste || menuItem == menuItem_pasteFormatted){
		return([[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]] != nil);
	
	}else if(menuItem == menuItem_showToolbar){
		[menuItem_showToolbar setTitle:([[window toolbar] isVisible] ? @"Hide Toolbar" : @"Show Toolbar")];
		return([window toolbar] != nil);
	
	}else if(menuItem == menuItem_customizeToolbar){
		return([window toolbar] != nil && [[window toolbar] isVisible]);

	}else{
		return(YES);
	}
}

@end


