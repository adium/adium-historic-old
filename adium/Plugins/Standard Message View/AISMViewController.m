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

#import <Cocoa/Cocoa.h>

#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#import "AISMViewController.h"
#import "AISMViewPlugin.h"

#define DARKEN_LIGHTEN_MODIFIER		0.2

@interface AISMViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)rebuildMessageViewForContent;
- (void)_addContentObject:(AIContentObject *)content;
- (void)_addContentMessage:(AIContentMessage *)content;
- (void)_addContentStatus:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content;
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)previousRow;
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content;
- (id)_cellInRow:(AIFlexibleTableRow *)row withClass:(Class)class;
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
    messageView = [[AIFlexibleTableView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Arbitrary frame
    [messageView setForwardsKeyEvents:YES];
    
    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:chat];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //Rebuild out view to include any content already in the chat
    [self rebuildMessageViewForContent];
    
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
    [timeStampFormatter release];
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
        [timeStampFormatter release];
        [prefixIncoming release];
        [prefixOutgoing release];
        
        //Cache the new preferences
        outgoingSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_COLOR] representedColor] retain];
        outgoingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR] representedColor] retain];
        incomingSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_COLOR] representedColor] retain];
        incomingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR] representedColor] retain];
        
        prefixFont = [[[prefDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] retain];
        
        
        timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT] retain];
        timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO];

        combineMessages = [[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES] boolValue];
        
        
        
        
        
        prefixIncoming = [[prefDict objectForKey:KEY_SMV_PREFIX_INCOMING] retain];
        prefixOutgoing = [[prefDict objectForKey:KEY_SMV_PREFIX_OUTGOING] retain];
        
        displayPrefix = [[prefDict objectForKey:KEY_SMV_SHOW_PREFIX] boolValue];
        displayTimeStamps = [[prefDict objectForKey:KEY_SMV_SHOW_TIME_STAMPS] boolValue];
        displayGridLines = [[prefDict objectForKey:KEY_SMV_DISPLAY_GRID_LINES] boolValue];
        hideDuplicateTimeStamps = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS] boolValue];
        hideDuplicatePrefixes = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_PREFIX] boolValue]; 
        
        
        
        showUserIcons = [[prefDict objectForKey:KEY_SMV_SHOW_USER_ICONS] boolValue];
        
        
        
        
        gridDarkness = [[prefDict objectForKey:KEY_SMV_GRID_DARKNESS] floatValue];
        
        //Reset all content objects
        [self rebuildMessageViewForContent];
    }
}

//Rebuild our view for any existing content
- (void)rebuildMessageViewForContent
{
    NSEnumerator    *enumerator;
    AIContentObject *content;

    //Move everything out
    [messageView removeAllRows];

    //Re-add all content one row at a time (slooow)
    enumerator = [[chat contentObjectArray] reverseObjectEnumerator]; //(Content is stored in reverse order)
    while(content = [enumerator nextObject]){
        [self _addContentObject:content];
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

//Add a new content object
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentObject	*content = [[notification userInfo] objectForKey:@"Object"];

    [self _addContentObject:content];
}

//Add rows for a content object
- (void)_addContentObject:(AIContentObject *)content
{
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        [self _addContentMessage:(AIContentMessage *)content];

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
        [self _addContentStatus:(AIContentStatus *)content];
        
    }
}

//Add rows for a content message object
- (void)_addContentMessage:(AIContentMessage *)content
{
    //Previous row
    AIFlexibleTableRow  *previousRow = [messageView rowAtIndex:0];
    AIContentObject     *previousContent = [previousRow representedObject];
    AIFlexibleTableRow  *prefixRow = nil, *messageRow = nil;
    BOOL                contentIsSimilar = NO;
    
    //We should merge if the previous content is a message and from the same source
    if(combineMessages && previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source]){
        contentIsSimilar = YES;
    }
    
    //Add a message header/prefix (If this message is different from the previous one)
    if(!contentIsSimilar){
        prefixRow = [self _prefixRowForContent:content];
        [messageView addRow:prefixRow];
    }
    
    //Add our message
    messageRow = [self _messageRowForContent:content previousRow:(prefixRow ? prefixRow : previousRow)];
    [messageView addRow:messageRow];

    //Merge our new message with the previous one
    if(contentIsSimilar){
        [[self _cellInRow:previousRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawBottom:NO];
        [[self _cellInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawTop:NO];
        [[self _cellInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawTopDivider:YES];
    }
}

//Add rows for a content status object
- (void)_addContentStatus:(AIContentStatus *)content
{
    //Add the status change
    [messageView addRow:[self _statusRowForContent:content]];
}

//Create a status row for a content object
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content
{
    NSString            *theMessage = [content message];
    AIFlexibleTableCell	*statusCell;
    
    //Insert a time stamp
    if(displayTimeStamps){
        NSString    *dateString = [timeStampFormatter stringForObjectValue:[content date]];
        theMessage = [NSString stringWithFormat:@"%@ (%@)", theMessage, dateString];
    }

    //Create the status text cell
    statusCell = [AIFlexibleTableStringCell cellWithString:theMessage
                                                     color:[NSColor grayColor]
                                                      font:[NSFont cachedFontWithName:@"Helvetica" size:11]
                                                 alignment:NSCenterTextAlignment];
    [statusCell setPaddingLeft:1 top:0 right:1 bottom:0];
    [statusCell setVariableWidth:YES];
    
    //
    return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:statusCell,nil] representedObject:content]);
}

//Creates a message prefix row for a content object
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content
{
    BOOL                        outgoing = ([[content source] isKindOfClass:[AIAccount class]]);
    AIFlexibleTableStringCell	*senderCell, *timeCell;
    AIFlexibleTableImageCell	*imageCell = nil;
    NSImage                     *userIcon;

    //User icon
    if(showUserIcons){
        //Get the user icon
        if(outgoing){
            userIcon = iconOutgoing; //messageImage = [(AIAccount *)messageSource userIcon];

        }else{
            AIMutableOwnerArray *ownerArray = [[chat listObject] statusArrayForKey:@"BuddyImage"];
    
            if(ownerArray && [ownerArray count]){
                userIcon = [ownerArray objectAtIndex:0];
            }else{
                userIcon = iconIncoming;
            }
        }

        //Create a spanning image cell for it
        imageCell = [AIFlexibleTableImageCell cellWithImage:userIcon];
        [imageCell setPaddingLeft:1 top:6 right:2 bottom:1];
        [imageCell setBackgroundColor:[NSColor whiteColor]];
        [imageCell setDesiredFrameSize:NSMakeSize(28.0,28.0)];
        [imageCell setRowSpan:2];
    }
    
    //Prefix
    senderCell = [AIFlexibleTableStringCell cellWithString:[[content source] displayName]
                                                     color:(outgoing ? outgoingSourceColor : incomingSourceColor)
                                                      font:prefixFont
                                                 alignment:NSLeftTextAlignment];
    [senderCell setPaddingLeft:(showUserIcons ? 1 : 4) top:3 right:1 bottom:0];
    [senderCell setVariableWidth:YES];

    //Time Stamp
    timeCell = [AIFlexibleTableStringCell cellWithString:[timeStampFormatter stringForObjectValue:[(AIContentMessage *)content date]]
                                                   color:[NSColor grayColor]
                                                    font:[NSFont cachedFontWithName:@"Helvetica" size:10]
                                               alignment:NSLeftTextAlignment];
    [timeCell setPaddingLeft:1 top:4 right:4 bottom:0];
    
    //Build and return the row
    if(imageCell){
        return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:imageCell, senderCell, timeCell, nil] representedObject:nil]);
    }else{
        return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:senderCell, timeCell, nil] representedObject:nil]);
    }    
}

//Create a bubbled message row for a content object
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)previousRow
{
    BOOL                            outgoing = ([[content source] isKindOfClass:[AIAccount class]]);
    AIFlexibleTableSpanCell         *emptyCell = nil;
    AIFlexibleTableFramedTextCell   *messageCell;
    NSColor                         *color;
    
    //Empty icon span cell
    if(showUserIcons && previousRow){
        id  cell;
        
        //Create a span cell with the last image cell as it's master
        if(cell = [self _cellInRow:previousRow withClass:[AIFlexibleTableImageCell class]]){
            emptyCell = [AIFlexibleTableSpanCell spanCellFor:cell];
            
        }else if(cell = [self _cellInRow:previousRow withClass:[AIFlexibleTableSpanCell class]]){
            emptyCell = [AIFlexibleTableSpanCell spanCellFor:[cell masterCell]];

        }
    }

    //Get our backgound color
    if(!outgoing){
        color = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(242.0/255.0) blue:(255.0/255.0) alpha:1.0];
    }else{
        color = [NSColor colorWithCalibratedRed:(230.0/255.0) green:(255.0/255.0) blue:(234.0/255.0) alpha:1.0];
    }
    
    
    float hue, sat, brit, alpha;
    [color getHue:&hue saturation:&sat brightness:&brit alpha:&alpha];
    sat += 0.3; if(sat > 1.0) sat = 1.0;
    brit -= 0.3; if(brit < 0.0) sat = 0.0;
    NSColor *borderColor = [NSColor colorWithCalibratedHue:hue saturation:sat brightness:brit alpha:alpha];

    [color getHue:&hue saturation:&sat brightness:&brit alpha:&alpha];
    sat += 0.1; if(sat > 1.0) sat = 1.0;
    brit -= 0.1; if(brit < 0.0) sat = 0.0;
    NSColor *dividerColor = [NSColor colorWithCalibratedHue:hue saturation:sat brightness:brit alpha:alpha];
    
    
    
    //Message cell
    messageCell = [AIFlexibleTableFramedTextCell cellWithAttributedString:[content message]];
    [messageCell setPaddingLeft:0 top:0 right:(showUserIcons ? 4 : 0) bottom:0];
    [messageCell setVariableWidth:YES];
    [messageCell setFrameBackgroundColor:color borderColor:/*[color darkenBy:0.2]*/borderColor dividerColor:dividerColor];
    [messageCell setDrawTop:YES];
    [messageCell setDrawBottom:YES];
    [messageCell setDrawSides:showUserIcons];
    
    //
    if(emptyCell){
        return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObjects:emptyCell,messageCell,nil] representedObject:content]);
    }else{
        return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObject:messageCell] representedObject:content]);
    }
}

//Finds a cell in a row with the specified class
- (id)_cellInRow:(AIFlexibleTableRow *)row withClass:(Class)class
{
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    
    enumerator = [[row cellArray] objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:class]) return(cell);
    }
    
    return(nil);
}

@end
