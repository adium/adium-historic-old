//
//  AISMViewController.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISMViewController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AISMViewPlugin.h"

#define DARKEN_LIGHTEN_MODIFIER		0.2

@interface AISMViewController (PRIVATE)
- (id)initForContact:(AIListContact *)inContact owner:(id)inOwner;
- (void)preferencesChanged:(NSNotification *)notification;
- (AIFlexibleTableCell *)emptyCellForContent:(id <AIContentObject>)content;
- (AIFlexibleTableCell *)messageCellForContent:(AIContentMessage *)content previousContent:(id <AIContentObject>)previousContent;
- (AIFlexibleTableCell *)senderCellForContent:(AIContentMessage *)content previousContent:(id <AIContentObject>)previousContent;
- (AIFlexibleTableCell *)timeStampCellForContent:(id <AIContentObject>)content previousContent:(id <AIContentObject>)previousContent;
- (NSColor *)backgroundColorOfContent:(id <AIContentObject>)content;
@end

@implementation AISMViewController
+ (AISMViewController *)messageViewControllerForContact:(AIListContact *)inContact owner:(id)inOwner
{
    return([[[self alloc] initForContact:inContact owner:inOwner] autorelease]);
}

- (id)initForContact:(AIListContact *)inContact owner:(id)inOwner
{
    //init
    [super init];
    owner = [inOwner retain];
    contact = [inContact retain];

    //observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    [self preferencesChanged:nil];

    //Create our table view
    messageView = [[AIFlexibleTableView alloc] init];
    [messageView setDelegate:self];

    senderCol = [[AIFlexibleTableColumn alloc] init];
    [messageView addColumn:senderCol];
    
    messageCol = [[AIFlexibleTableColumn alloc] init];
    [messageCol setFlexibleWidth:YES];
    [messageView addColumn:messageCol];
    
    timeCol = [[AIFlexibleTableColumn alloc] init];
    [messageView addColumn:timeCol];

    [messageView reloadData];
    
    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:contact];

    return(self);
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
        
        [messageView reloadData];
    }
}



//Return our message view
- (NSView *)messageView
{
    return(messageView);
}

- (void)contentObjectAdded:(NSNotification *)notification
{
    [messageView loadNewRow]; //Inform our view of the new row
}

- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    NSArray			*contentArray = [contact contentObjectArray];
    id <AIContentObject>	content;
    id <AIContentObject>	previousContent = nil;
    AIFlexibleTableCell		*cell = nil;

    //Get the content objects
    content = [contentArray objectAtIndex:([contentArray count] - 1) - inRow]; //Content is stored in reverse order
    if(inRow > 0) previousContent = [contentArray objectAtIndex:[contentArray count] - inRow];
    

    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
/*        AIContentMessage	*contentMessage = (AIContentMessage *)object;
        id			messageSource = [contentMessage source];
        BOOL			duplicateSource, outgoing;
        NSColor			*backgroundColor;
        NSAttributedString	*message;
        BOOL			backgroundIsDark;
        NSColor	*gridColor;
        
        //Figure our some basic information about this content
        outgoing = ([messageSource isKindOfClass:[AIAccount class]]);
        duplicateSource = (previousContent && [previousContent source] == messageSource);

        //Get the background color
        message = [contentMessage message];
        backgroundColor = [message attribute:NSBackgroundColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [message length])];
        if(!backgroundColor) backgroundColor = [NSColor whiteColor];//(outgoing ? backColorOut : backColorIn);
        backgroundIsDark = [backgroundColor colorIsDark];



        gridColor = [backgroundColor darkenBy:(backgroundIsDark ? - (gridDarkness + DARKEN_LIGHTEN_MODIFIER) : gridDarkness)];
*/
        //        BOOL			displayPrefix;
//        BOOL			displayTimeStamps;

        //Create and return a cell
        if(inCol == senderCol){
            cell = [self senderCellForContent:content previousContent:previousContent];
                
        }else if(inCol == messageCol){
            cell = [self messageCellForContent:content previousContent:previousContent];

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

- (AIFlexibleTableCell *)emptyCellForContent:(id <AIContentObject>)content
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

- (AIFlexibleTableCell *)messageCellForContent:(AIContentMessage *)content previousContent:(id <AIContentObject>)previousContent
{
    AIFlexibleTableCell	*cell;

    //Create the cell
    cell = [AIFlexibleTableTextCell cellWithAttributedString:[content message]];
    [cell setBackgroundColor:[self backgroundColorOfContent:content]];

    //Padding
    [cell setPaddingLeft:2 top:1 right:2 bottom:1];

    return(cell);
}

- (AIFlexibleTableCell *)senderCellForContent:(AIContentMessage *)content previousContent:(id <AIContentObject>)previousContent
{
    id			messageSource = [content source];
    NSColor		*gradientColor, *prefixColor, *backgroundColor;
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

    //Create the cell
    cell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:(outgoing ? prefixOutgoing : prefixIncoming),(outgoing ? [(AIAccount *)messageSource accountDescription] : [[(AIHandle *)messageSource containingContact] displayName])]
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
- (AIFlexibleTableCell *)timeStampCellForContent:(id <AIContentObject>)content previousContent:(id <AIContentObject>)previousContent
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

- (NSColor *)backgroundColorOfContent:(id <AIContentObject>)content
{
    NSColor	*backgroundColor = nil;

    //Get the background color
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSAttributedString	*message = [(AIContentMessage *)content message];
        backgroundColor = [message attribute:NSBackgroundColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [message length])];
    }

    //If no color, use white
    if(!backgroundColor) backgroundColor = [NSColor whiteColor];

    return(backgroundColor);
}


- (int)numberOfRows
{
    return([[contact contentObjectArray] count]);
}

@end
