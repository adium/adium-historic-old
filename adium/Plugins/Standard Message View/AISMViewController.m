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

#import "AISMViewController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AISMViewPlugin.h"

#define DARKEN_LIGHTEN_MODIFIER		0.2

@interface AISMViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner;
- (void)preferencesChanged:(NSNotification *)notification;
- (AIFlexibleTableCell *)emptyCellForContent:(AIContentObject *)content;
- (AIFlexibleTableCell *)messageCellForContent:(AIContentMessage *)content previousContent:(AIContentObject *)previousContent;
- (AIFlexibleTableCell *)senderCellForContent:(AIContentObject *)content previousContent:(AIContentObject *)previousContent;
- (AIFlexibleTableCell *)timeStampCellForContent:(AIContentObject *)content previousContent:(AIContentObject *)previousContent;
- (NSColor *)backgroundColorOfContent:(AIContentObject *)content;
@end

@implementation AISMViewController

+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner
{
    return([[[self alloc] initForChat:inChat owner:inOwner] autorelease]);
}

- (id)initForChat:(AIChat *)inChat owner:(id)inOwner
{
    //init
    [super init];
    owner = [inOwner retain];
    chat = [inChat retain];
    outgoingAlias = nil;

    //Get pref values
    [self preferencesChanged:nil];

    //Configure our table view
    messageView = [[AIFlexibleTableView alloc] init];
    [messageView setDelegate:self];
    [messageView setForwardsKeyEvents:YES];

    //Configure the columns
    senderCol = [[AIFlexibleTableColumn alloc] init];
    [messageView addColumn:senderCol];
    messageCol = [[AIFlexibleTableColumn alloc] init];
    [messageCol setFlexibleWidth:YES];
    [messageView addColumn:messageCol];
    timeCol = [[AIFlexibleTableColumn alloc] init];
    [messageView addColumn:timeCol];

    //Load any existing messages
    [messageView reloadData];
    
    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:chat];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    return(self);
}

- (void)dealloc
{
    //
    [[owner notificationCenter] removeObserver:self];
    
    //Release the old preference cache
    [outgoingSourceColor release];
    [outgoingLightSourceColor release];
    [incomingSourceColor release];
    [incomingLightSourceColor release];
    [prefixFont release];
    [timeStampFormat release];
    [prefixIncoming release];
    [prefixOutgoing release];
    [outgoingAlias release];

    //
    [senderCol release];
    [messageCol release];
    [timeCol release];
    [messageView release];
    [chat release];
    
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

        //Release the old preference cache
        [outgoingSourceColor release];
        [outgoingLightSourceColor release];
        [incomingSourceColor release];
        [incomingLightSourceColor release];
        [prefixFont release];
        [timeStampFormat release];
        [prefixIncoming release];
        [prefixOutgoing release];
        [outgoingAlias release];
        
        //Cache the new preferences
        outgoingSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_COLOR] representedColor] retain];
        outgoingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR] representedColor] retain];
        incomingSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_COLOR] representedColor] retain];
        incomingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR] representedColor] retain];

        prefixFont = [[[prefDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] retain];

        if([[prefDict objectForKey:KEY_SMV_SHOW_TIME_SECONDS] boolValue]){
            timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT_SECONDS] retain];
        }else{
            timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT] retain];
        }
        
        prefixIncoming = [[prefDict objectForKey:KEY_SMV_PREFIX_INCOMING] retain];
        prefixOutgoing = [[prefDict objectForKey:KEY_SMV_PREFIX_OUTGOING] retain];
        
        displayPrefix = [[prefDict objectForKey:KEY_SMV_SHOW_PREFIX] boolValue];
        displayTimeStamps = [[prefDict objectForKey:KEY_SMV_SHOW_TIME_STAMPS] boolValue];
        displayGridLines = [[prefDict objectForKey:KEY_SMV_DISPLAY_GRID_LINES] boolValue];
        displaySenderGradient = [[prefDict objectForKey:KEY_SMV_DISPLAY_SENDER_GRADIENT] boolValue];
        hideDuplicateTimeStamps = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS] boolValue];
        hideDuplicatePrefixes = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_PREFIX] boolValue]; 

        gridDarkness = [[prefDict objectForKey:KEY_SMV_GRID_DARKNESS] floatValue];
        senderGradientDarkness = [[prefDict objectForKey:KEY_SMV_SENDER_GRADIENT_DARKNESS] floatValue];
//        senderGradientLightness = [[prefDict objectForKey:KEY_SMV_SENDER_GRADIENT_LIGHTNESS] floatValue];

        outgoingAlias = [[prefDict objectForKey:KEY_SMV_OUTGOING_ALIAS] retain];
        
        [messageView reloadData];
    }
}



//Return our message view
- (NSView *)messageView
{
    return(messageView);
}

//Return our chat
- (AIChat *)chat
{
    return(chat);
}


- (void)contentObjectAdded:(NSNotification *)notification
{
    [messageView loadNewRow]; //Inform our view of the new row
}

- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    NSArray		*contentArray = [chat contentObjectArray];
    AIContentObject	*content;
    AIContentObject	*previousContent = nil;
    AIFlexibleTableCell	*cell = nil;

    //Get the content objects
    content = [contentArray objectAtIndex:([contentArray count] - 1) - inRow]; //Content is stored in reverse order
    if(inRow > 0) previousContent = [contentArray objectAtIndex:[contentArray count] - inRow];

    
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
        //Create and return a cell
        if(inCol == senderCol){
            cell = [self senderCellForContent:content previousContent:previousContent];
                
        }else if(inCol == messageCol){
            cell = [self messageCellForContent:(AIContentMessage *)content previousContent:previousContent];

        }else if(inCol == timeCol){
            cell = [self timeStampCellForContent:content previousContent:previousContent];

        }

        //Set up the gridlines.  We draw a gridline above this cell if (Gridlines are enabled) and (there is previous content) and (that content is not the same type as us or content's source is not the same as previous content's source)
        if(displayGridLines && previousContent && ([[previousContent type] compare:[content type]] != 0 || [content source] != [previousContent source])){
            BOOL		backgroundIsDark;
            NSColor		*backgroundColor;

            //Set a divider
            backgroundColor = [self backgroundColorOfContent:content];
            backgroundIsDark = [backgroundColor colorIsDark];
            [cell setDividerColor:[backgroundColor darkenBy:(backgroundIsDark ? - (gridDarkness + DARKEN_LIGHTEN_MODIFIER) : gridDarkness)]];
        }

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){ //Status
        if(inCol == senderCol){
            cell = [self emptyCellForContent:content];

        }else if(inCol == messageCol){
            cell = [AIFlexibleTableTextCell cellWithString:[(AIContentStatus *)content message]
                                                     color:/*(backgroundIsDark ? [NSColor lightGrayColor] : */[NSColor grayColor]/*)*/
                                                      font:[NSFont cachedFontWithName:@"Helvetica" size:10]
                                                 alignment:NSLeftTextAlignment
                                                background:[NSColor whiteColor]
                                                  gradient:nil];
            [cell setPaddingLeft:1 top:0 right:1 bottom:0];


        }else if(inCol == timeCol){
            cell = [self timeStampCellForContent:content previousContent:previousContent];
        }

        //Set up the gridlines.  We draw a gridline above this cell if (Gridlines are enabled) and (there is previous content) and (that content is not the same type as us)
        if(displayGridLines && previousContent && [[previousContent type] compare:[content type]] != 0){
            BOOL		backgroundIsDark;
            NSColor		*backgroundColor;

            //Set a divider
            backgroundColor = [self backgroundColorOfContent:content];
            backgroundIsDark = [backgroundColor colorIsDark];
            [cell setDividerColor:[backgroundColor darkenBy:(backgroundIsDark ? - (gridDarkness + DARKEN_LIGHTEN_MODIFIER) : gridDarkness)]];
        }
    }

    return(cell);
}

//Returns an empty cell
- (AIFlexibleTableCell *)emptyCellForContent:(AIContentObject *)content
{
    AIFlexibleTableCell	*cell;

    //Create the cell
    cell = [AIFlexibleTableTextCell cellWithString:nil
                                             color:nil
                                              font:nil
                                         alignment:NSLeftTextAlignment
                                        background:[self backgroundColorOfContent:content]
                                          gradient:nil];
    [cell setDrawContents:NO];

    return(cell);
}

//Returns a message cell
- (AIFlexibleTableCell *)messageCellForContent:(AIContentMessage *)content previousContent:(AIContentObject *)previousContent
{
    AIFlexibleTableCell	*cell;

    //Create the cell
    cell = [AIFlexibleTableTextCell cellWithAttributedString:[content message]];
    [cell setBackgroundColor:[self backgroundColorOfContent:content]];

    //Padding
    [cell setPaddingLeft:2 top:1 right:2 bottom:1];

    return(cell);
}

//Returns a sender cell
- (AIFlexibleTableCell *)senderCellForContent:(AIContentObject *)content previousContent:(AIContentObject *)previousContent
{
    id			messageSource = [content source];
    NSColor		*gradientColor, *prefixColor, *backgroundColor;
    NSString		*senderString = nil;
    AIFlexibleTableCell	*cell;
    BOOL		outgoing, duplicateSource, backgroundIsDark;
    
    //Determine some basic info about the content
    outgoing = ([messageSource isKindOfClass:[AIAccount class]]);
    duplicateSource = (previousContent && [[previousContent type] compare:CONTENT_MESSAGE_TYPE] == 0 && [previousContent source] == messageSource);

    //Get the background color
    backgroundColor = [self backgroundColorOfContent:content];
    backgroundIsDark = [backgroundColor colorIsDark];

    //Determine the correct prefix color
    if(outgoing){
        prefixColor = (backgroundIsDark ? outgoingLightSourceColor : outgoingSourceColor);
    }else{
        prefixColor = (backgroundIsDark ? incomingLightSourceColor : incomingSourceColor);
    }

    //Determine the correct gradient color (if enabled)
    if(displaySenderGradient){
        gradientColor = (backgroundIsDark ? [backgroundColor darkenBy:-(senderGradientDarkness + DARKEN_LIGHTEN_MODIFIER)] : [backgroundColor darkenBy:senderGradientDarkness]);
    }else{
        gradientColor = nil;
    }

    //Get the sender string
    if(outgoing && outgoingAlias != nil && [outgoingAlias length] != 0){
        senderString = outgoingAlias;
    }
    if(!senderString){
        if(outgoing){
            senderString = [(AIAccount *)messageSource accountDescription];
        }else{
            senderString = [(AIListContact *)messageSource displayName];
        }
    }
    
    //Create the cell
    cell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:(outgoing ? prefixOutgoing : prefixIncoming), senderString]
                                             color:prefixColor
                                              font:prefixFont
                                         alignment:NSRightTextAlignment
                                        background:backgroundColor
                                          gradient:gradientColor];

    //Padding
    [cell setPaddingLeft:1 top:1 right:1 bottom:1];

    //Hide duplicate senders
    if(hideDuplicatePrefixes && duplicateSource) [cell setDrawContents:NO];

    return(cell);
}

//Returns a time stamp cell
- (AIFlexibleTableCell *)timeStampCellForContent:(AIContentObject *)content previousContent:(AIContentObject *)previousContent
{
    AIFlexibleTableCell	*cell;
    BOOL		backgroundIsDark;

    //We return a time stamp cell for any content object with a date, and only if time stamps are enabled
    if(displayTimeStamps && [[content type] compare:CONTENT_MESSAGE_TYPE] == 0 || [[content type] compare:CONTENT_STATUS_TYPE] == 0){        
        //Generate the date string
        NSDateFormatter		*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO] autorelease];
        NSString		*dateString = [dateFormatter stringForObjectValue:[(AIContentMessage *)content date]];

        //Create the cell
        cell = [AIFlexibleTableTextCell cellWithString:dateString
                                                 color:(backgroundIsDark ? [NSColor lightGrayColor] : [NSColor grayColor])
                                                  font:[NSFont cachedFontWithName:@"Helvetica" size:10]
                                             alignment:NSRightTextAlignment
                                            background:[self backgroundColorOfContent:content]
                                              gradient:nil];

        //Padding
        [cell setPaddingLeft:1 top:0 right:1 bottom:0];
        
        //Duplicate hiding.  We hide this cell's content if:
        if(hideDuplicateTimeStamps					//Hiding of duplicates is enabled
            && previousContent 						//and There is previous content
            && ([[content type] compare:CONTENT_MESSAGE_TYPE] == 0 || 	//and The previous content has a date
                [[content type] compare:CONTENT_STATUS_TYPE] == 0)
            && [[dateFormatter stringForObjectValue:[(AIContentMessage *)previousContent date]] compare:dateString] == 0){ //and The date is the same as ours
            [cell setDrawContents:NO]; //Hide the time stamp
        }

        return(cell);

    }else{ //For other objects, or if time stamps are not enabled, return an empty cell
        return(nil);
    }
    
}

- (NSColor *)backgroundColorOfContent:(AIContentObject *)content
{
    NSColor	*backgroundColor = nil;

    //Get the background color
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSAttributedString	*message = [(AIContentMessage *)content message];
        backgroundColor = [message attribute:AIBodyColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [message length])];
    }

    //If no color, use white
    if(!backgroundColor) backgroundColor = [NSColor whiteColor];

    return(backgroundColor);
}


- (int)numberOfRows
{
    return([[chat contentObjectArray] count]);
}

@end
