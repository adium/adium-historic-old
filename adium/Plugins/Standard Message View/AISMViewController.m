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
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content;
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)previousRow header:(BOOL)isHeader;
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content;
- (AIFlexibleTableCell *)_userIconCellForContent:(AIContentMessage *)content span:(BOOL)span;
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)previousRow;
- (AIFlexibleTableCell *)_prefixCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_timeStampCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_messageCellForContent:(AIContentMessage *)content;
- (NSAttributedString *)_prefixStringForContent:(AIContentMessage *)content;
- (NSAttributedString *)_prefixWithFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (NSString *)_prefixStringByExpandingFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (id)_cellInRow:(AIFlexibleTableRow *)row withClass:(Class)class;
@end

@implementation AISMViewController

//
+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner
{
    return([[[self alloc] initForChat:inChat owner:inOwner] autorelease]);
}

//
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner
{
    //init
    [super init];
    owner = [inOwner retain];
    chat = [inChat retain];
    lastMasterCell = nil;
    
    //Cache our icons (temp?)
    iconIncoming = [[AIImageUtilities imageNamed:@"blue" forClass:[self class]] retain];
    iconOutgoing = [[AIImageUtilities imageNamed:@"green" forClass:[self class]] retain];
    
    //Configure our table view
    messageView = [[AIFlexibleTableView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Arbitrary frame
    [messageView setForwardsKeyEvents:YES];
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:chat];

    //Preferences
    [self preferencesChanged:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //Rebuild out view to include any content already in the chat
    [self rebuildMessageViewForContent];
    
    return(self);
}

//
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

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] == 0){
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
        
	inlinePrefixes = ([prefixIncoming rangeOfString:@"%m"].location == NSNotFound);
	
	
	
        
        
        displayPrefix = [[prefDict objectForKey:KEY_SMV_SHOW_PREFIX] boolValue];
        displayTimeStamps = [[prefDict objectForKey:KEY_SMV_SHOW_TIME_STAMPS] boolValue];
        displayGridLines = [[prefDict objectForKey:KEY_SMV_DISPLAY_GRID_LINES] boolValue];
        hideDuplicateTimeStamps = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS] boolValue];
        hideDuplicatePrefixes = [[prefDict objectForKey:KEY_SMV_HIDE_DUPLICATE_PREFIX] boolValue]; 
        
        
        
        showUserIcons = [[prefDict objectForKey:KEY_SMV_SHOW_USER_ICONS] boolValue];
	//Force icons off for side prefixes
        if([prefixIncoming rangeOfString:@"%m"].location != NSNotFound){
	    showUserIcons = NO;
	}

	
	[colorIncoming release];
	[colorIncomingBorder release];
	[colorIncomingDivider release];
	[colorOutgoing release];
	[colorOutgoingBorder release];
	[colorOutgoingDivider release];
	
	colorIncoming = [[NSColor colorWithCalibratedRed:(229.0/255.0) green:(242.0/255.0) blue:(255.0/255.0) alpha:1.0] retain];
	colorIncomingBorder = [[colorIncoming adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorIncomingDivider = [[colorIncoming adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];

	colorOutgoing = [[NSColor colorWithCalibratedRed:(230.0/255.0) green:(255.0/255.0) blue:(234.0/255.0) alpha:1.0] retain];
	colorOutgoingBorder = [[colorOutgoing adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorOutgoingDivider = [[colorOutgoing adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];

	
	//Pad bottom depending on mode
	[messageView setContentPaddingTop:0 bottom:(inlinePrefixes ? 3 : 0)];
        
        
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
    
    //If we are using inline prefixes, and this message is different from the previous one, insert a prefix row 
    if(inlinePrefixes && !contentIsSimilar){
        prefixRow = [self _prefixRowForContent:content];
	[messageView addRow:prefixRow];
    }
    
    //Add our message
    messageRow = [self _messageRowForContent:content
				 previousRow:(prefixRow ? prefixRow : previousRow)
				      header:(!inlinePrefixes && !contentIsSimilar)];
    [messageView addRow:messageRow];
    
    //Merge our new message with the previous one
    if(contentIsSimilar){
        [[self _cellInRow:previousRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawBottom:NO];
        [[self _cellInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawTop:NO];
        [[self _cellInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawTopDivider:YES];
	if(!inlinePrefixes) [[self _cellInRow:previousRow withClass:[AIFlexibleTableImageCell class]] setRowSpan:2];
    }
    
    //
    
}

//Add rows for a content status object
- (void)_addContentStatus:(AIContentStatus *)content
{
    //Add the status change
    [messageView addRow:[self _statusRowForContent:content]];
}


//Rows --------------------------------------------------------------------------------------------------
//Returns a status row for a content object
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content
{
    AIFlexibleTableCell	*statusCell = [self _statusCellForContent:content];

    return([AIFlexibleTableRow rowWithCells:[NSArray arrayWithObject:statusCell] representedObject:content]);
}

//Returns a message prefix row for a content object
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content
{
    NSArray     *cellArray;

    if(showUserIcons){
	cellArray = [NSArray arrayWithObjects:[self _userIconCellForContent:content span:YES], [self _prefixCellForContent:content], [self _timeStampCellForContent:content], nil];
    }else{
	cellArray = [NSArray arrayWithObjects:[self _prefixCellForContent:content], [self _timeStampCellForContent:content], nil];
    }

    return([AIFlexibleTableRow rowWithCells:cellArray representedObject:nil]);
}

//Create a bubbled message row for a content object
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)previousRow header:(BOOL)isHeader
{
    AIFlexibleTableCell     *imageCell = nil;
    NSArray		    *cellArray;
    
    //Empty icon span cell
    if(showUserIcons){
	if(isHeader){
	    imageCell = [self _userIconCellForContent:content span:NO];
	}else if(previousRow){
	    imageCell = [self _emptyImageSpanCellForPreviousRow:previousRow];
	}
    }

    //
    if(imageCell){
	cellArray = [NSArray arrayWithObjects:imageCell, [self _messageCellForContent:content], nil];
    }else{
	cellArray = [NSArray arrayWithObjects:[self _messageCellForContent:content], nil];
    }
    return([AIFlexibleTableRow rowWithCells:cellArray representedObject:content]);
}


//Cells --------------------------------------------------------------------------------------------------
//Status cell
//Uses the current time stamp format
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content
{
    NSString		*dateString = [timeStampFormatter stringForObjectValue:[content date]];
    AIFlexibleTableCell	*statusCell;
    
    //Create the status text cell
    statusCell = [AIFlexibleTableStringCell cellWithString:[NSString stringWithFormat:@"%@ (%@)", [content message], dateString]
                                                     color:[NSColor grayColor]
                                                      font:[NSFont cachedFontWithName:@"Helvetica" size:11]
                                                 alignment:NSCenterTextAlignment];
    [statusCell setPaddingLeft:1 top:0 right:1 bottom:0];
    [statusCell setVariableWidth:YES];

    return(statusCell);
}

//User icon cell
- (AIFlexibleTableCell *)_userIconCellForContent:(AIContentMessage *)content span:(BOOL)span
{
    AIFlexibleTableImageCell    *imageCell;
    NSImage			*userImage;
    
    //Get the user icon
    if([content isOutgoing]){
	userImage = iconOutgoing; //messageImage = [(AIAccount *)messageSource userIcon];
    }else{
	userImage = [[[chat listObject] statusArrayForKey:@"BuddyImage"] firstImage];
	if(!userImage) userImage = iconIncoming;
    }
    
    //Create the spanning image cell
    imageCell = [AIFlexibleTableImageCell cellWithImage:userImage];
    [imageCell setPaddingLeft:1 top:6 right:2 bottom:1];
    [imageCell setBackgroundColor:[NSColor whiteColor]];
    [imageCell setDesiredFrameSize:NSMakeSize(28.0,28.0)];
    if(span) [imageCell setRowSpan:2];

    return(imageCell);
}

//Span cell with the last image cell as it's master
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)previousRow
{
    id  cell;
    
    if(cell = [self _cellInRow:previousRow withClass:[AIFlexibleTableImageCell class]]){
	return([AIFlexibleTableSpanCell spanCellFor:cell]);
    }else if(cell = [self _cellInRow:previousRow withClass:[AIFlexibleTableSpanCell class]]){
	return([AIFlexibleTableSpanCell spanCellFor:[cell masterCell]]);
    }
    
    return(nil);
}

//Prefix cell
//Uses the current prefix style and format, and varies padding based on user icon visibility
- (AIFlexibleTableCell *)_prefixCellForContent:(AIContentMessage *)content
{
    AIFlexibleTableCell     *prefixCell;
    
    //Prefix
    prefixCell = [AIFlexibleTableStringCell cellWithAttributedString:[self _prefixStringForContent:content]];
    [prefixCell setPaddingLeft:(showUserIcons ? 1 : 4) top:3 right:1 bottom:0];
    [prefixCell setVariableWidth:YES];
    
    return(prefixCell);
}

//Time stamp cell
//Uses the current time format
- (AIFlexibleTableCell *)_timeStampCellForContent:(AIContentMessage *)content
{
    AIFlexibleTableCell     *timeCell;

    //Time
    timeCell = [AIFlexibleTableStringCell cellWithString:[timeStampFormatter stringForObjectValue:[(AIContentMessage *)content date]]
                                                   color:[NSColor grayColor]
                                                    font:[NSFont cachedFontWithName:@"Helvetica" size:10]
                                               alignment:NSLeftTextAlignment];
    [timeCell setPaddingLeft:1 top:4 right:4 bottom:0];
    
    return(timeCell);
}

//Message cell (As prefix to filter message to include prefix information)
//Cell content depends on the state of inlinePrefixes, and possibly prefix style and format
//Also depends on current color preferences and user icon visibility.
- (AIFlexibleTableCell *)_messageCellForContent:(AIContentMessage *)content
{
    AIFlexibleTableFramedTextCell     *messageCell;
    
    messageCell = [AIFlexibleTableFramedTextCell cellWithAttributedString:(inlinePrefixes ? [content message] : [self _prefixStringForContent:content])];
    [messageCell setPaddingLeft:0 top:0 right:(showUserIcons ? 4 : 0) bottom:0];
    [messageCell setVariableWidth:YES];
    [messageCell setDrawTop:YES];
    [messageCell setDrawBottom:(inlinePrefixes)];
    [messageCell setDrawSides:(showUserIcons && inlinePrefixes)];
    
    if([content isOutgoing]){
	[messageCell setFrameBackgroundColor:colorOutgoing borderColor:colorOutgoingBorder dividerColor:colorOutgoingDivider];
    }else{
	[messageCell setFrameBackgroundColor:colorIncoming borderColor:colorIncomingBorder dividerColor:colorIncomingDivider];
    }
    
    return(messageCell);
}
    

//Prefix Creation --------------------------------------------------------------------------------------------------
//Build and return an attributed string for the content using the current prefix preference
- (NSAttributedString *)_prefixStringForContent:(AIContentMessage *)content
{
    NSString    *prefixFormat = ([content isOutgoing] ? prefixOutgoing : prefixIncoming);
    NSRange     messageRange;
    
    //Does the prefix contain the message ?
    messageRange = [prefixFormat rangeOfString:@"%m"];
    if(messageRange.location != NSNotFound){
        NSMutableAttributedString   *prefixString = [[[NSMutableAttributedString alloc] init] autorelease];

        //If the prefix contains a message, we build it in pieces
        [prefixString appendAttributedString:[self _prefixWithFormat:[prefixFormat substringToIndex:messageRange.location] forContent:content]];
        [prefixString appendAttributedString:[content message]];
        [prefixString appendAttributedString:[self _prefixWithFormat:[prefixFormat substringFromIndex:messageRange.location] forContent:content]];
        
        return(prefixString);
        
    }else{
        //Doesn't contain the message
        return([self _prefixWithFormat:prefixFormat forContent:content]);
	
    }    
}

//Expand the prefix format for a content object, returning an attributed string formatted according to the current preferences
- (NSAttributedString *)_prefixWithFormat:(NSString *)format forContent:(AIContentMessage *)content
{
    NSString    *string = [self _prefixStringByExpandingFormat:format forContent:content];

    //Create an attributed string from it with the prefix font and colors
    NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        ([content isOutgoing] ? outgoingSourceColor : incomingSourceColor), NSForegroundColorAttributeName,
        prefixFont, NSFontAttributeName,
        nil];
    
    return([[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease]);
}

//Expand the keywords (and filter out any conditional text) in a prefix format NSString for the given content message
- (NSString *)_prefixStringByExpandingFormat:(NSString *)format forContent:(AIContentMessage *)content
{
    NSCharacterSet  *flagSet = [NSCharacterSet characterSetWithCharactersInString:@"%?"];
    NSMutableString *string = [NSMutableString string];
    int             scanLocation = 0;
    int             formatLength = [format length];
    
    while(scanLocation != NSNotFound && scanLocation < formatLength){
	int     flagLocation;
	
	//Find the next flag in our prefix
        flagLocation = [format rangeOfCharacterFromSet:flagSet options:0 range:NSMakeRange(scanLocation, formatLength - scanLocation)].location;
	if(flagLocation == NSNotFound) flagLocation = formatLength;
	
	//Add the string we scanned over
	if(flagLocation - scanLocation){
	    [string appendString:[format substringWithRange:NSMakeRange(scanLocation, flagLocation - scanLocation)]];
	}
	
	//Process the flag
	scanLocation = flagLocation;
	if(scanLocation < formatLength){
	    unichar flagChar = [format characterAtIndex:scanLocation];
	    
	    if(flagChar == '%'){ //Expandable Keyword
		unichar nextChar = [format characterAtIndex:scanLocation + 1];
		
		//Expand the keyword
		switch(nextChar){
		    case '%': [string appendString:@"%"]; break;
		    case 'a': [string appendString:[[content source] displayName]]; break;
		    case 'n': [string appendString:[[content source] serverDisplayName]]; break;
		    case 't': [string appendString:[timeStampFormatter stringForObjectValue:[content date]]]; break;
		    default: break;
		}
		
		scanLocation += 2; //Skip over the flag and value
		
	    }else if(flagChar == '?'){ //Conditional text
		unichar nextChar = [format characterAtIndex:scanLocation + 1];
		
		if(nextChar == '?'){
		    [string appendString:@"?"];
		    
		}else{
		    int     endFlagLocation;
		    BOOL    present;
		    
		    //Find the next occurence of '?X'
		    endFlagLocation = [format rangeOfString:[NSString stringWithFormat:@"?%c",nextChar] options:0 range:NSMakeRange(scanLocation+2, formatLength - (scanLocation+2))].location;
		    
		    //Is this value present?
		    switch(nextChar){
			case 'a': present = ([[[content source] displayName] compare:[[content source] serverDisplayName]] != 0); break;
			case 'n': present = YES; break;
			case 't': present = YES; break;
			default: present = NO; break;
		    }
		    
		    //Scan and insert the conditional text
		    if(present){
			[string appendString:[self _prefixStringByExpandingFormat:[format substringWithRange:NSMakeRange(scanLocation+2, endFlagLocation - (scanLocation + 2))] forContent:content]];
		    }
		    
		    scanLocation = endFlagLocation + 2; //Skip over the conditionals and content
		}
	    }
	}
    }
    
    return(string);
}


//Misc --------------------------------------------------------------------------------------------------
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
