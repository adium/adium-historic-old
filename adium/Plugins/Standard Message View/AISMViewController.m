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

@interface AISMViewController (PRIVATE)
- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner;

@end

@implementation AISMViewController
+ (AISMViewController *)messageViewControllerForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    return([[[self alloc] initForHandle:inHandle owner:inOwner] autorelease]);
}

- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    //init
    [super init];
    owner = [inOwner retain];
    handle = [inHandle retain];

    //prefetch our colors
    backColorIn = [[[[owner preferenceController] preferenceForKey:@"message_incoming_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    backColorOut = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    outgoingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    incomingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_incoming_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    lineColorDivider = [[backColorIn darkenBy:0.1] retain];
    lineColorDarkDivider = [[backColorIn darkenBy:0.2] retain];


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
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:handle];

    return(self);
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
    NSArray			*contentArray = [handle contentObjectArray];
    id <AIContentObject>	object;
    id <AIContentObject>	previousContent = nil;
    AIFlexibleTableCell			*cell = nil;

    //Get the content objects
    object = [contentArray objectAtIndex:([contentArray count] - 1) - inRow]; //Content is stored in reverse order
    if(inRow > 0) previousContent = [contentArray objectAtIndex:[contentArray count] - inRow];
    
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
        AIContentMessage	*contentMessage = (AIContentMessage *)object;
        id			messageSource = [contentMessage source];
        BOOL			duplicateSource, outgoing;
        
        //Figure our some basic information about this content
        outgoing = ([messageSource isKindOfClass:[AIAccount class]]);
        duplicateSource = (previousContent && [previousContent source] == messageSource);
        
        //Create and return a cell
        if(inCol == senderCol){
            if(outgoing){
                cell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:@"%@:",[(AIAccount *)messageSource accountDescription]]
                                           color:outgoingSourceColor
                                            font:[NSFont systemFontOfSize:11]
                                       alignment:NSRightTextAlignment
                                      background:backColorOut
                                        gradient:[backColorOut darkenBy:0.09]];
            }else{
                cell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:@"%@:",[(AIContactHandle *)messageSource displayName]]
                                           color:incomingSourceColor
                                            font:[NSFont systemFontOfSize:11]
                                       alignment:NSRightTextAlignment
                                      background:backColorIn
                                        gradient:[backColorIn darkenBy:0.09]];
            }
            [cell setPaddingLeft:1 top:0 right:1 bottom:0];
            if(!duplicateSource) [cell setDividerColor:lineColorDarkDivider];
            if(duplicateSource) [cell setDrawContents:NO];
                
        }else if(inCol == messageCol){
            cell = [AIFlexibleTableTextCell cellWithAttributedString:[contentMessage message]];
            [cell setBackgroundColor:(outgoing ? backColorOut : backColorIn)];
            [cell setPaddingLeft:2 top:1 right:2 bottom:1];
            if(!duplicateSource) [cell setDividerColor:lineColorDivider];
            
        }else if(inCol == timeCol){
            //User's localized date format: [[NSUserDefaults standardUserDefaults] objectForKey:NSTimeFormatString] (w/ seconds)
            NSDateFormatter		*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%1I:%M" allowNaturalLanguage:NO] autorelease];
            NSString			*dateString = [dateFormatter stringForObjectValue:[contentMessage date]];
            
            cell = [AIFlexibleTableTextCell cellWithString:dateString
                                       color:[NSColor grayColor]
                                        font:[NSFont fontWithName:@"Helvetica" size:10]
                                   alignment:NSRightTextAlignment
                                  background:(outgoing ? backColorOut : backColorIn)
                                    gradient:nil];
            [cell setPaddingLeft:1 top:0 right:1 bottom:0];
            if(!duplicateSource) [cell setDividerColor:lineColorDivider];
            if(previousContent && [[dateFormatter stringForObjectValue:[previousContent date]] compare:dateString] == 0){
                //We assume that previous content is also a content message... this is not always true.
                [cell setDrawContents:NO];
            }
        }
    }

    return(cell);
}

- (int)numberOfRows
{
    return([[handle contentObjectArray] count]);
}

@end
