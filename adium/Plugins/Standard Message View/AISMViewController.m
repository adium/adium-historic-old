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
    lastMasterCell = nil;

    //Get pref values
    [self preferencesChanged:nil];

    //Cache our icons (temp?)
    iconIncoming = [[AIImageUtilities imageNamed:@"blue" forClass:[self class]] retain];
    iconOutgoing = [[AIImageUtilities imageNamed:@"green" forClass:[self class]] retain];
    
    //Configure our table view
    messageView = [[AIFlexibleTableView alloc] init];
    [messageView setForwardsKeyEvents:YES];
    
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

    //
    [iconIncoming release];
    [iconOutgoing release];

    //
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
        hideDuplicateTimeStamps = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS] boolValue];
        hideDuplicatePrefixes = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_PREFIX] boolValue]; 

        gridDarkness = [[prefDict objectForKey:KEY_SMV_GRID_DARKNESS] floatValue];

        //[messageView reloadData];
        //redraw on preferences changed
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

//
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage	*content = [[notification userInfo] objectForKey:@"Object"];

    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIFlexibleTableSpanCell		*emptyCell;
        AIFlexibleTableFramedTextCell	*messageCell;
        AIContentObject			*previousContent = nil;
        NSArray				*contentArray;
        NSColor 			*color;
        id				messageSource;
        BOOL				outgoing;
        
        //Get chat and content info
        contentArray = [chat contentObjectArray];
        messageSource = [content source];
        outgoing = ([messageSource isKindOfClass:[AIAccount class]]);
        if([contentArray count] > 1) previousContent = [contentArray objectAtIndex:1];

        //If this content is different, add a sender/icon row
        if(!previousContent || ([[previousContent type] compare:[content type]] != 0 || [content source] != [previousContent source])){
            AIFlexibleTableStringCell	*senderCell, *timeCell;
            AIFlexibleTableImageCell	*imageCell;

            //
            if(lastMessageCell){
                lastMessageCell = nil;
            }

            //User Image
            imageCell = [AIFlexibleTableImageCell cellWithImage:(outgoing ? iconOutgoing : iconIncoming)];
            [imageCell setPaddingLeft:1 top:6 right:1 bottom:1];
            [imageCell setBackgroundColor:[NSColor whiteColor]];
            [imageCell setRowSpan:2];
            lastMasterCell = imageCell;

            //Sender Name
            senderCell = [AIFlexibleTableStringCell cellWithString:[messageSource displayName] color:(outgoing ? outgoingSourceColor : incomingSourceColor) font:prefixFont alignment:NSLeftTextAlignment];
            [senderCell setPaddingLeft:1 top:3 right:1 bottom:0];
            [senderCell setVariableWidth:YES];

            //Time Stamp
            NSDateFormatter	*dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO] autorelease];
            NSString		*dateString = [dateFormatter stringForObjectValue:[(AIContentMessage *)content date]];
            timeCell = [AIFlexibleTableStringCell cellWithString:dateString color:[NSColor grayColor] font:[NSFont cachedFontWithName:@"Helvetica" size:10] alignment:NSLeftTextAlignment];
            [timeCell setPaddingLeft:1 top:4 right:4 bottom:0];

            //
            [messageView addRow:[AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:imageCell,senderCell,timeCell,nil]]];
        }

        //Empty icon span cell
        emptyCell = [AIFlexibleTableSpanCell spanCellFor:lastMasterCell];

        //Message cell
        messageCell = (AIFlexibleTableFramedTextCell *)[AIFlexibleTableFramedTextCell cellWithAttributedString:[content message]];
        [messageCell setPaddingLeft:0 top:0 right:4 bottom:0];
        [messageCell setVariableWidth:YES];

        //
        if(!outgoing){
            color = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(242.0/255.0) blue:(255.0/255.0) alpha:1.0];
        }else{
            color = [NSColor colorWithCalibratedRed:(230.0/255.0) green:(255.0/255.0) blue:(234.0/255.0) alpha:1.0];
        }
        [messageCell setFrameBackgroundColor:color borderColor:[color darkenBy:0.2]];

        //
        if(lastMessageCell){
            [lastMessageCell setDrawBottom:NO];
            lastMessageCell = nil;
        }else{
            [messageCell setDrawTop:YES];
        }

        //
        [messageCell setDrawBottom:YES];
        lastMessageCell = messageCell;

        //
        [messageView addRow:[AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:emptyCell,messageCell,nil]]];

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
        AIFlexibleTableCell	*statusCell;

        //
        if(lastMessageCell){
            lastMessageCell = nil;
        }

        //
        statusCell = [AIFlexibleTableStringCell cellWithString:[(AIContentStatus *)content message] color:[NSColor lightGrayColor] font:[NSFont cachedFontWithName:@"Helvetica" size:11] alignment:NSCenterTextAlignment];
        [statusCell setPaddingLeft:1 top:0 right:1 bottom:0];
        [statusCell setVariableWidth:YES];

        //
        [messageView addRow:[AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:statusCell,nil]]];
    }
}

@end
