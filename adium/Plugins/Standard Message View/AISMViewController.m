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
#import "AISMViewPlugin.h"

@interface AISMViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_flushPreferenceCache;
- (void)rebuildMessageViewForContent;
- (void)_addContentObject:(AIContentObject *)content;
- (void)_addContentMessage:(AIContentMessage *)content;
- (void)_addContentMessageRow:(AIFlexibleTableRow *)row;
- (void)_addContentStatus:(AIContentStatus *)content;
- (void)_addContentObjectToQueue:(AIContentObject *)content;
- (void)_addQueuedContent;
- (NSArray *)_rowsForAddingContentObject:(AIContentObject *)content;
- (NSArray *)_rowsForAddingContentMessage:(AIContentMessage *)content;
- (AIFlexibleTableRow *)_rowForAddingContentStatus:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content;
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)thePreviousRow header:(BOOL)isHeader;
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content;
- (AIFlexibleTableCell *)_userIconCellForContent:(AIContentMessage *)content span:(BOOL)span;
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow;
- (AIFlexibleTableCell *)_emptyHeadIndentCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow content:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_prefixCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_timeStampCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_messageCellForContent:(AIContentMessage *)content includingPrefixes:(BOOL)includePrefixes shouldPerformHeadIndent:(BOOL)performHeadIndent;
- (NSAttributedString *)_messageStringForContent:(AIContentMessage *)content;
- (NSAttributedString *)_prefixStringForContent:(AIContentMessage *)content performHeadIndent:(BOOL)performHeadIndent;
- (NSAttributedString *)_prefixWithFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (NSString *)_prefixStringByExpandingFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (id)_cellInRow:(AIFlexibleTableRow *)row withClass:(Class)class;
- (id)_lastCellInRow:(AIFlexibleTableRow *)row withClass:(Class)class;
- (NSArray *)_cellsInRow:(AIFlexibleTableRow *)row withClass:(Class)class;
- (NSAttributedString *)_stringByRemovingTextColor:(NSAttributedString *)inString;
- (NSAttributedString *)_stringByFixingTextColor:(NSAttributedString *)inString;
@end

@implementation AISMViewController

//Create a new message view
+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner
{
    return([[[self alloc] initForChat:inChat owner:inOwner] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner
{
    //init
    [super init];
    
    rebuilding = NO;
    
    owner = [inOwner retain];
    chat = [inChat retain];
    contentQueue = [[NSMutableArray alloc] init];
    previousRow = nil;
    
    //Cache our icons (temp?)
    iconIncoming = [[AIImageUtilities imageNamed:@"blue" forClass:[self class]] retain];
    iconOutgoing = [[AIImageUtilities imageNamed:@"green" forClass:[self class]] retain];
    
    //Configure our table view
    messageView = [[AIFlexibleTableView alloc] initWithFrame:NSZeroRect];
    [messageView setForwardsKeyEvents:YES];
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:chat];

    //Observe preferences
    [self preferencesChanged:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //Rebuild our view to include any content already in the chat
    [self rebuildMessageViewForContent];
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    //
    [[owner notificationCenter] removeObserver:self];
    [self _flushPreferenceCache];

    //
    [messageView release];
    [chat release];
    [iconIncoming release];
    [iconOutgoing release];
    
    [super dealloc];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
        //Release the old preference cache
	[self _flushPreferenceCache];

	//Config
        combineMessages = [[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES] boolValue];
	showUserIcons = [[prefDict objectForKey:KEY_SMV_SHOW_USER_ICONS] boolValue];

	//Prefix
        prefixIncoming = [[prefDict objectForKey:KEY_SMV_PREFIX_INCOMING] retain];
        prefixOutgoing = [[prefDict objectForKey:KEY_SMV_PREFIX_OUTGOING] retain];
	inlinePrefixes = ([prefixIncoming rangeOfString:@"%m"].location == NSNotFound);
        
	//Time Stamps
        timeStampFormat = [[prefDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT] retain];
        timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeStampFormat allowNaturalLanguage:NO];

	//Coloring
	colorIncoming = [[NSColor colorWithCalibratedRed:(229.0/255.0) green:(242.0/255.0) blue:(255.0/255.0) alpha:1.0] retain];
	colorIncomingBorder = [[colorIncoming adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorIncomingDivider = [[colorIncoming adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];
	colorOutgoing = [[NSColor colorWithCalibratedRed:(230.0/255.0) green:(255.0/255.0) blue:(234.0/255.0) alpha:1.0] retain];
	colorOutgoingBorder = [[colorOutgoing adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorOutgoingDivider = [[colorOutgoing adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];

	//Ignorance
	ignoreTextColor = [[prefDict objectForKey:KEY_SMV_IGNORE_TEXT_COLOR] boolValue];
	ignoreBackgroundColor = [[prefDict objectForKey:KEY_SMV_IGNORE_BACKGROUND_COLOR] boolValue];
	
	//Force icons off for side prefixes
        if([prefixIncoming rangeOfString:@"%m"].location != NSNotFound) showUserIcons = NO;
	
	//Pad bottom of the message view depending on mode
	[messageView setContentPaddingTop:0 bottom:(inlinePrefixes ? 3 : 0)];

        //Indentation when combining messages in appropriate modes
        headIndent = [[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES_INDENT] floatValue];
        
	
        //Old
	outgoingSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_COLOR] representedColor] retain];
        outgoingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR] representedColor] retain];
        incomingSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_COLOR] representedColor] retain];
        incomingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR] representedColor] retain];
        prefixFont = [[[prefDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] retain];        
        
        //Reset all content objects
        [self rebuildMessageViewForContent];
    }
}

//Release any cached preference values
- (void)_flushPreferenceCache
{
    [prefixIncoming release]; prefixIncoming = nil;
    [prefixOutgoing release]; prefixOutgoing = nil;
    [timeStampFormat release]; timeStampFormat = nil;
    [timeStampFormatter release]; timeStampFormatter = nil;
    [colorIncoming release]; colorIncoming = nil;
    [colorIncomingBorder release]; colorIncomingBorder = nil;
    [colorIncomingDivider release]; colorIncomingDivider = nil;
    [colorOutgoing release]; colorOutgoing = nil;
    [colorOutgoingBorder release]; colorOutgoingBorder = nil;
    [colorOutgoingDivider release]; colorOutgoingDivider = nil;

    //old
    [outgoingSourceColor release]; outgoingSourceColor = nil;
    [outgoingLightSourceColor release]; outgoingLightSourceColor = nil;
    [incomingSourceColor release]; incomingSourceColor = nil;
    [incomingLightSourceColor release]; incomingLightSourceColor = nil;
    [prefixFont release]; prefixFont = nil;
}

//Rebuild our view for any existing content
- (void)rebuildMessageViewForContent
{
    if (rebuilding) {
        restartRebuilding = YES;
    } else {
        restartRebuilding = NO;
        [NSThread detachNewThreadSelector:@selector(_rebuildMessageViewForContentThread) toTarget:self withObject:nil];
    }
}

-(void)_rebuildMessageViewForContentThread
{
    //lock the addition of rows down with rebuilding=YES
    rebuilding = YES;

    AIContentObject    *content;
    AIFlexibleTableRow  *row;
    NSMutableArray      *rowArray = [[NSMutableArray alloc] init];
    
    //The first row has no previous row
    previousRow = nil;
    
    //In a separate thread, so create an autorelease pool for the NSEnumerator objects
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //Re-add all content one row at a time (slooow)
    NSEnumerator        *enumerator_chat = [[chat contentObjectArray] reverseObjectEnumerator]; //(Content is stored in reverse order)
    while((content = [enumerator_chat nextObject]) && !restartRebuilding){
        NSArray *contentRowArray = [[self _rowsForAddingContentObject:content] retain];
        NSEnumerator        *enumerator_two = [contentRowArray objectEnumerator];
        AIFlexibleTableRow  *row;
        
        while (row = [enumerator_two nextObject]) {
            [rowArray addObject:row];
        }
        
        [contentRowArray release];
    }
    
    //Move everything out
    if (!restartRebuilding)
        [messageView removeAllRows];
    
    NSEnumerator *rowArray_enumerator = [rowArray objectEnumerator];
    while ((row = [rowArray_enumerator nextObject]) && !restartRebuilding){
        [messageView addRow:row]; 
    }

    //restart the rebuilding process if necessar
    if (restartRebuilding){
        restartRebuilding = NO;
        
        [self _rebuildMessageViewForContentThread];
    }
    rebuilding = NO;
    
    //catch up
    [self _addQueuedContent];
    
    //Refresh the display
    [messageView display];

    [rowArray release];
    [pool release];
}

//add the queued content in order, then remove it from the contentQueue
- (void)_addQueuedContent
{
    NSEnumerator    *enumerator = [contentQueue objectEnumerator];
    AIContentObject *content;
    while (content = [enumerator nextObject])
        [self _addContentObject:content];
    
    [contentQueue removeAllObjects];
}

//queue a content object for later addition to the view
- (void)_addContentObjectToQueue:(AIContentObject *)content
{
    [contentQueue addObject:content];
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
    
    //If we are not currently rebuilding, add it immediately; if we are, add it to our queue
    if (!rebuilding)
        [self _addContentObject:content];
    else
        [self _addContentObjectToQueue:content];
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

- (NSArray *)_rowsForAddingContentObject:(AIContentObject *)content
{
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        return [self _rowsForAddingContentMessage:(AIContentMessage *)content];
    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
        return [NSArray arrayWithObject:[self _rowForAddingContentStatus:(AIContentStatus *)content]];
    }
    
    //Should never get here
    return nil;
}

//Add rows for a content message object
- (void)_addContentMessage:(AIContentMessage *)content
{
    NSArray             *rowArray = [[self _rowsForAddingContentMessage:content] retain];
    NSEnumerator        *enumerator = [rowArray objectEnumerator];
    AIFlexibleTableRow  *row;
    
    while (row = [enumerator nextObject]) {
        [messageView addRow:row];
    }
    
    [rowArray release];
}
//Add a preconstructed row to the messageView
- (void)_addContentMessageRow:(AIFlexibleTableRow *)row
{
    [messageView addRow:row];   
}
//returns an autoreleased array of the rows which represent content
- (NSArray *)_rowsForAddingContentMessage:(AIContentMessage *)content
{
    //Previous row
    AIContentObject     *previousContent = [previousRow representedObject];
    AIFlexibleTableRow  *prefixRow = nil, *messageRow = nil;
    BOOL                contentIsSimilar = NO;
    
    //We should merge if the previous content is a message and from the same source
    if((!inlinePrefixes || combineMessages) &&
       (previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source])){
        contentIsSimilar = YES;
    }
    
    //If we are using inline prefixes, and this message is different from the previous one, insert a prefix row 
    if(inlinePrefixes && !contentIsSimilar){
        prefixRow = [self _prefixRowForContent:content];
    }
    
    //Add our message
    messageRow = [self _messageRowForContent:content
				 previousRow:(prefixRow ? prefixRow : previousRow)
				      header:(!inlinePrefixes && !contentIsSimilar)];
    
    //Merge our new message with the previous one
    if(contentIsSimilar){  
        NSEnumerator        *enumerator;
        AIFlexibleTableFramedTextCell *cell;
        
        enumerator = [[self _cellsInRow:previousRow withClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawBottom:NO];
        }

        enumerator = [[self _cellsInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawTop:NO];
        }
        
        //draw the between-messages divider in the last framedTextCell in the row, which should be the message
        [[self _lastCellInRow:messageRow withClass:[AIFlexibleTableFramedTextCell class]] setDrawTopDivider:YES];
        
        if(!inlinePrefixes) [[self _cellInRow:previousRow withClass:[AIFlexibleTableImageCell class]] setRowSpan:2];
    }
    
    previousRow = messageRow;
    
    NSArray *returnArray;
    if (prefixRow)
        returnArray = [NSArray arrayWithObjects:prefixRow,messageRow,nil];
    else
        returnArray = [NSArray arrayWithObject:messageRow];
    return (returnArray);
}

//Add rows for a content status object
- (void)_addContentStatus:(AIContentStatus *)content
{
    //Add the status change
    [messageView addRow:[self _rowForAddingContentStatus:content]];
}

- (AIFlexibleTableRow *)_rowForAddingContentStatus:(AIContentStatus *)content
{
    //Add the status change
    AIFlexibleTableRow *row = [self _statusRowForContent:content];
    
    //Add a separatorto our previous row if necessary
    AIFlexibleTableFramedTextCell *cell;
    NSEnumerator * enumerator = [[self _cellsInRow:previousRow withClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
    while (cell = [enumerator nextObject]) {
        [cell setDrawBottom:YES];
    }
    
    return(row);
}
//Rows --------------------------------------------------------------------------------------------------
//Returns a status row for a content object
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content
{
    AIFlexibleTableCell	*statusCell = [self _statusCellForContent:content];
    AIFlexibleTableRow *row = [AIFlexibleTableRow rowWithCells:[NSArray arrayWithObject:statusCell] representedObject:content];
    previousRow = row;
    return(row);
}

//Returns a message prefix row for a content object
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content
{
    NSArray             *cellArray;
    AIFlexibleTableRow  *row;
    
    if(showUserIcons){
	cellArray = [NSArray arrayWithObjects:[self _userIconCellForContent:content span:YES], [self _prefixCellForContent:content], [self _timeStampCellForContent:content], nil];
    }else{
	cellArray = [NSArray arrayWithObjects:[self _prefixCellForContent:content], [self _timeStampCellForContent:content], nil];
    }

    row = [AIFlexibleTableRow rowWithCells:cellArray representedObject:nil];
    [row setHeadIndent:headIndent];
    return(row);
}

//Create a bubbled message row for a content object
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)thePreviousRow header:(BOOL)isHeader
{
    AIFlexibleTableCell     *leftmostCell = nil;
    NSArray		    *cellArray;
    AIFlexibleTableRow      *row;
    //Empty icon span cell
    if(showUserIcons){
	if(isHeader){
	    leftmostCell = [self _userIconCellForContent:content span:NO];
	}else if(thePreviousRow){
	    leftmostCell = [self _emptyImageSpanCellForPreviousRow:thePreviousRow];
	}        
    }
    //Empty spacing cell
    if(!isHeader && !inlinePrefixes && combineMessages) {
        leftmostCell = [self _emptyHeadIndentCellForPreviousRow:thePreviousRow content:content];
    }
    //
    if(leftmostCell){
        cellArray = [NSArray arrayWithObjects:leftmostCell, [self _messageCellForContent:content includingPrefixes:NO shouldPerformHeadIndent:NO], nil];
    }else{
        cellArray = [NSArray arrayWithObjects:[self _messageCellForContent:content includingPrefixes:!inlinePrefixes shouldPerformHeadIndent:(isHeader && !inlinePrefixes && combineMessages)], nil];
    }
    row = [AIFlexibleTableRow rowWithCells:cellArray representedObject:content];
    //set the headIndent
    [row setHeadIndent:headIndent];
    return(row);
}


//Cells --------------------------------------------------------------------------------------------------
//Status cell
//Uses the current time stamp format
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content
{
    NSString		*dateString = [timeStampFormatter stringForObjectValue:[content date]];
    AIFlexibleTableCell	*statusCell;
    
    //Create the status text cell
    statusCell = [AIFlexibleTableTextCell cellWithString:[NSString stringWithFormat:@"%@ (%@)", [content message], dateString]
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
        userImage = [(AIAccount *)[content source] userIcon];
        if (!userImage)
            userImage = iconOutgoing;
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
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow
{
    id  cell;
    
    if(cell = [self _cellInRow:thePreviousRow withClass:[AIFlexibleTableImageCell class]]){
	return([AIFlexibleTableSpanCell spanCellFor:cell]);
    }else if(cell = [self _cellInRow:thePreviousRow withClass:[AIFlexibleTableSpanCell class]]){
	return([AIFlexibleTableSpanCell spanCellFor:[cell masterCell]]);
    }
    
    return(nil);
}

- (AIFlexibleTableCell *)_emptyHeadIndentCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow content:(AIContentMessage *)content
{
    AIFlexibleTableFramedTextCell * cell = [[AIFlexibleTableFramedTextCell alloc] init];

    //size the cell for the previousRow headIndent value
    [cell sizeCellForWidth:[thePreviousRow headIndent]];

    if([content isOutgoing]){
        [cell setFrameBackgroundColor:colorOutgoing borderColor:colorOutgoingBorder dividerColor:colorOutgoingDivider];
    }else{
        [cell setFrameBackgroundColor:colorIncoming borderColor:colorIncomingBorder dividerColor:colorIncomingDivider];
    }
        
    return ([cell autorelease]);
}

//Prefix cell
//Uses the current prefix style and format, and varies padding based on user icon visibility
- (AIFlexibleTableCell *)_prefixCellForContent:(AIContentMessage *)content
{
    AIFlexibleTableCell     *prefixCell;
    
    //Prefix
    prefixCell = [AIFlexibleTableStringCell cellWithAttributedString:[self _prefixStringForContent:content performHeadIndent:NO]];
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
- (AIFlexibleTableCell *)_messageCellForContent:(AIContentMessage *)content includingPrefixes:(BOOL)includePrefixes shouldPerformHeadIndent:(BOOL)performHeadIndent
{
    AIFlexibleTableFramedTextCell   *messageCell;
    NSAttributedString		    *messageString;
    
    //Get the message string
    if(includePrefixes){
	messageString = [self _prefixStringForContent:content performHeadIndent:performHeadIndent];
    }else{
	messageString = [self _messageStringForContent:content];
    }

    //Create the cell for this string
    messageCell = [AIFlexibleTableFramedTextCell cellWithAttributedString:messageString];
    [messageCell setPaddingLeft:0 top:0 right:(showUserIcons ? 4 : 0) bottom:0];
    if(inlinePrefixes){
        [messageCell setInternalPaddingLeft:(showUserIcons ? 7 : 10) top:2 right:5 bottom:2];
    }else{
      [messageCell setInternalPaddingLeft:4 top:2 right:4 bottom:2];
    }
    [messageCell setVariableWidth:YES];
    [messageCell setDrawTop:YES];
    [messageCell setDrawBottom:(inlinePrefixes)];
    [messageCell setDrawSides:(showUserIcons && inlinePrefixes)];
    
    //Background coloring
    NSColor *bodyColor = [[content message] attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil];
    if(![content isOutgoing]){
	if(ignoreBackgroundColor || !bodyColor || [bodyColor equalToRGBColor:[NSColor whiteColor]]){
	    [messageCell setFrameBackgroundColor:colorIncoming borderColor:colorIncomingBorder dividerColor:colorIncomingDivider];
	}else{
	    [messageCell setFrameBackgroundColor:bodyColor
				     borderColor:[bodyColor adjustHue:0.0 saturation:+0.3 brightness:-0.3]
				    dividerColor:[bodyColor adjustHue:0.0 saturation:+0.1 brightness:-0.1]];
	}
    }else{
	if(!bodyColor || [bodyColor equalToRGBColor:[NSColor whiteColor]]){
	    [messageCell setFrameBackgroundColor:colorOutgoing borderColor:colorOutgoingBorder dividerColor:colorOutgoingDivider];
	}else{
	    [messageCell setFrameBackgroundColor:bodyColor
							  borderColor:[bodyColor adjustHue:0.0 saturation:+0.3 brightness:-0.3]
							 dividerColor:[bodyColor adjustHue:0.0 saturation:+0.1 brightness:-0.1]];
	}
    }
    
    return(messageCell);
}
    
//Prefix Creation --------------------------------------------------------------------------------------------------
//Message without a prefix
- (NSAttributedString *)_messageStringForContent:(AIContentMessage *)content
{
    if([content isOutgoing] || (!ignoreTextColor/* && !ignoreBackgroundColor*/)){
        return([content message]);
    /*} else if (!ignoreTextColor && ignoreBackgroundColor){ //incoming message, ignoring the background color but not the text color
        NSLog(@"fixing");
        return([self _stringByFixingTextColor:[content message]]);
*/
    }else{
  //      NSLog(@"removing text color");
	return([self _stringByRemovingTextColor:[content message]]);
    }    
}

//Build and return an attributed string for the content using the current prefix preference
- (NSAttributedString *)_prefixStringForContent:(AIContentMessage *)content performHeadIndent:(BOOL)performHeadIndent
{
    NSString    *prefixFormat = ([content isOutgoing] ? prefixOutgoing : prefixIncoming);
    NSRange     messageRange;
    
    //Does the prefix contain the message ?
    messageRange = [prefixFormat rangeOfString:@"%m"];
    if(messageRange.location != NSNotFound){
        NSMutableAttributedString   *prefixString = [[[NSMutableAttributedString alloc] init] autorelease];

        //If the prefix contains a message, we build it in pieces
        [prefixString appendAttributedString:[self _prefixWithFormat:[prefixFormat substringToIndex:messageRange.location] forContent:content]];
        
        //set the headIndent, the amount subsequent lines will need to indent
        //headIndent = [prefixString size].width;
        //headIndent = 25.0;
        
	if([content isOutgoing] || !ignoreTextColor){
	    [prefixString appendAttributedString:[content message]];
	}else{
	    [prefixString appendAttributedString:[self _stringByRemovingTextColor:[content message]]];
	}
        [prefixString appendAttributedString:[self _prefixWithFormat:[prefixFormat substringFromIndex:messageRange.location] forContent:content]];
        
        if(performHeadIndent) {
            NSMutableParagraphStyle     *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            NSRange                     firstLineRange = [[prefixString string] lineRangeForRange:NSMakeRange(0,0)];
            
            //Set headIndent for the first line
            [paragraphStyle setHeadIndent:headIndent];
            [prefixString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,firstLineRange.length)];
            
            //Indent the remaining lines of the message
            NSMutableParagraphStyle     *paragraphStyleForRest = [paragraphStyle mutableCopy];
            [paragraphStyleForRest setFirstLineHeadIndent:headIndent];
            [prefixString addAttribute:NSParagraphStyleAttributeName value:paragraphStyleForRest range:NSMakeRange(firstLineRange.length, [prefixString length] - firstLineRange.length)];
        }
        
        return(prefixString);
        
    }else{
        //Doesn't contain the message. There is no headIndent.
        headIndent = 0;
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

//Finds the last cell in a row with the specified class
- (id)_lastCellInRow:(AIFlexibleTableRow *)row withClass:(Class)class
{
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    enumerator = [[row cellArray] reverseObjectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:class]) return(cell);
    }
    
    return(nil);
}

//Finds multiple cells in a row with the specified class
- (NSArray *)_cellsInRow:(AIFlexibleTableRow *)row withClass:(Class)class
{
    NSMutableArray      *cellArray = [[NSMutableArray alloc] init];
    NSEnumerator        *enumerator;
    AIFlexibleTableCell *cell;
    
    enumerator = [[row cellArray] objectEnumerator];
    while(cell = [enumerator nextObject]){
        if([cell isKindOfClass:class]) [cellArray addObject:cell];
    }
    
    return([cellArray autorelease]);
}

//Forces an attributed string to the default text color
- (NSAttributedString *)_stringByRemovingTextColor:(NSAttributedString *)inString
{
    NSMutableAttributedString   *mutableTemp = [[inString mutableCopy] autorelease];
    [mutableTemp addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0,[mutableTemp length])];
    return(mutableTemp);
}

//Modifies an attributed string to be visible on the background color
- (NSAttributedString *)_stringByFixingTextColor:(NSAttributedString *)inString
{
    NSMutableAttributedString   *mutableTemp = [[inString mutableCopy] autorelease];
    
    //adjust foreground colors for the incoming message background
    [mutableTemp adjustColorsToShowOnBackground:colorIncoming];
    
    return(mutableTemp);    
}
@end

