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
            

    //prefetch our colors
/*    backColorIn = [[[[owner preferenceController] preferenceForKey:@"message_incoming_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    backColorOut = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];

    outgoingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    outgoingBrightSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_brightSourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];

    incomingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_incoming_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    incomingBrightSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_incoming_brightSourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];

    lineColorDivider = [[backColorIn darkenBy:0.1] retain];
    lineColorDarkDivider = [[backColorIn darkenBy:0.2] retain];
*/

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
    id <AIContentObject>	object;
    id <AIContentObject>	previousContent = nil;
    AIFlexibleTableCell		*cell = nil;

    //Get the content objects
    object = [contentArray objectAtIndex:([contentArray count] - 1) - inRow]; //Content is stored in reverse order
    if(inRow > 0) previousContent = [contentArray objectAtIndex:[contentArray count] - inRow];
    

    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
        AIContentMessage	*contentMessage = (AIContentMessage *)object;
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

        //        BOOL			displayPrefix;
//        BOOL			displayTimeStamps;

        //Create and return a cell
        if(inCol == senderCol){
            NSColor	*prefixColor;
            NSColor	*gradientColor;
            
            if(outgoing){
                prefixColor = (backgroundIsDark ? outgoingLightSourceColor : outgoingSourceColor);
            }else{
                prefixColor = (backgroundIsDark ? incomingLightSourceColor : incomingSourceColor);
            }

            if(displaySenderGradient){
                gradientColor = (backgroundIsDark ? [backgroundColor darkenBy:-(senderGradientDarkness + DARKEN_LIGHTEN_MODIFIER)] : [backgroundColor darkenBy:senderGradientDarkness]);
            }else{
                gradientColor = nil;
            }            

            cell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:(outgoing ? prefixOutgoing : prefixIncoming),(outgoing ? [(AIAccount *)messageSource accountDescription] : [[(AIHandle *)messageSource containingContact] displayName])]
                                                     color:prefixColor
                                                      font:prefixFont
                                                 alignment:NSRightTextAlignment
                                                background:backgroundColor
                                                  gradient:gradientColor];
            [cell setPaddingLeft:1 top:1 right:1 bottom:1];

            if(displayGridLines && !duplicateSource) [cell setDividerColor:gridColor];//lineColorDarkDivider];
            if(hideDuplicatePrefixes && duplicateSource) [cell setDrawContents:NO];
                
        }else if(inCol == messageCol){
            cell = [AIFlexibleTableTextCell cellWithAttributedString:message];
            [cell setPaddingLeft:2 top:1 right:2 bottom:1];
            [cell setBackgroundColor:backgroundColor];
            if(displayGridLines && !duplicateSource) [cell setDividerColor:gridColor];

        }else if(inCol == timeCol){
            //User's localized date format: [[NSUserDefaults standardUserDefaults] objectForKey:NSTimeFormatString] (w/ seconds)
            NSDateFormatter		*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO] autorelease];
            NSString			*dateString = [dateFormatter stringForObjectValue:[contentMessage date]];

            if(!displayTimeStamps){
                dateString = @"";
            }
            
            cell = [AIFlexibleTableTextCell cellWithString:dateString
                                       color:(backgroundIsDark ? [NSColor lightGrayColor] : [NSColor grayColor])
                                        font:[NSFont cachedFontWithName:@"Helvetica" size:10]/*[[NSFontManager sharedFontManager] fontWithFamily:@"Lucida Grande" traits:0 weight:0 size:10]*/
                                   alignment:NSRightTextAlignment
                                  background:backgroundColor
                                    gradient:nil];
            [cell setPaddingLeft:1 top:0 right:1 bottom:0];
            if(displayGridLines && !duplicateSource) [cell setDividerColor:gridColor];
            if(hideDuplicateTimeStamps && previousContent && [[dateFormatter stringForObjectValue:[(AIContentMessage *)previousContent date]] compare:dateString] == 0){
                [cell setDrawContents:NO]; //We assume that previous content is also a content message... this is not always true!!!
            }
        }
    }

    return(cell);
}

- (int)numberOfRows
{
    return([[contact contentObjectArray] count]);
}

@end
