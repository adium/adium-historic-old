/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define ICON_SIZE 32.0
#define QUEUED_MESSAGE_OPACITY 0.5
#define NEW_BUBBLE_TIME 600

@interface AISMViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_flushPreferenceCache;
- (void)rebuildMessageViewForContent;
- (void)_addContentObject:(AIContentObject *)content;
- (void)_addContentMessage:(AIContentMessage *)content;
- (void)_addContentMessageRow:(AIFlexibleTableRow *)row;
- (void)_addContentContext:(AIContentContext *)content;
- (void)_addContentStatus:(AIContentStatus *)content;
- (void)_addContentObjectToThreadQueue:(AIContentObject *)content;
- (void)_addQueuedContent;
- (NSArray *)_rowsForAddingContentObject:(AIContentObject *)content;
- (NSArray *)_rowsForAddingContentMessage:(AIContentMessage *)content;
- (NSArray *)_rowsForAddingContentContext:(AIContentContext *)content;
- (AIFlexibleTableRow *)_rowForAddingContentStatus:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_statusRowForContent:(AIContentStatus *)content;
- (AIFlexibleTableRow *)_prefixRowForContent:(AIContentMessage *)content;
- (AIFlexibleTableRow *)_messageRowForContent:(AIContentMessage *)content previousRow:(AIFlexibleTableRow *)thePreviousRow header:(BOOL)isHeader;
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content;
- (AIFlexibleTableCell *)_userIconCellForContent:(AIContentObject *)content span:(BOOL)span;
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow;
- (AIFlexibleTableCell *)_emptyHeadIndentCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow content:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_prefixCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_timeStampCellForContent:(AIContentMessage *)content;
- (AIFlexibleTableCell *)_messageCellForContent:(AIContentMessage *)content includingPrefixes:(BOOL)includePrefixes shouldPerformHeadIndent:(BOOL)performHeadIndent;
- (NSAttributedString *)_messageStringForContent:(AIContentMessage *)content;
- (NSAttributedString *)_prefixStringForContent:(AIContentMessage *)content performHeadIndent:(BOOL)performHeadIndent;
- (NSAttributedString *)_prefixWithFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (NSString *)_prefixStringByExpandingFormat:(NSString *)format forContent:(AIContentMessage *)content;
- (NSAttributedString *)_stringWithContextStyle:(NSAttributedString *)inString;
- (NSAttributedString *)_stringByRemovingAllStyles:(NSAttributedString *)inString;
- (NSAttributedString *)_stringByFixingTextColor:(NSAttributedString *)inString forColor:(NSColor *)inColor;
@end

@implementation AISMViewController

//Create a new message view
+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat
{
    return([[[self alloc] initForChat:inChat] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat
{
    //init
    [super init];
    
    rebuilding = NO;
    lockContentThreadQueue = NO;
	
    chat = [inChat retain];
    contentThreadQueue = [[NSMutableArray alloc] init];
    previousRow = nil;
    
    //Cache our icons (temp?)
    iconIncoming = [[NSImage imageNamed:@"blue" forClass:[self class]] retain];
    iconOutgoing = [[NSImage imageNamed:@"green" forClass:[self class]] retain];
    
    //Configure our table view
    messageView = [[AIFlexibleTableView alloc] initWithFrame:NSZeroRect];
    [messageView setForwardsKeyEvents:YES];
    [messageView setDelegate:self];
	
	scrollView_messages = [[AIAutoScrollView alloc] init];
	[scrollView_messages setAndSizeDocumentView:messageView];
	[scrollView_messages setAutoScrollToBottom:YES];
	[scrollView_messages setAutoHideScrollBar:NO];
	[scrollView_messages setHasVerticalScroller:YES];
	[scrollView_messages setBorderType:NSBezelBorder];
   	[scrollView_messages setPassKeysToDocumentView:YES];
	
    [[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:chat];

    //Observe preferences
   	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
	
    //Rebuild our view to include any content already in the chat
    [self rebuildMessageViewForContent];
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    //
    abandonRebuilding = YES;
    [[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [self _flushPreferenceCache];

    //
	[contentThreadQueue release];
    [messageView release];
	[scrollView_messages release];
    [chat release];
    [iconIncoming release];
    [iconOutgoing release];
    
    [super dealloc];
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
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
	
	//Old?
	outgoingSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_COLOR] representedColor] retain];
	outgoingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR] representedColor] retain];
	incomingSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_COLOR] representedColor] retain];
	incomingLightSourceColor = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR] representedColor] retain];
	
	prefixFont = [[[prefDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] retain];        
	
	colorOutgoing = [[[prefDict objectForKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR] representedColor] retain];
	colorOutgoingBorder = [[colorOutgoing adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorOutgoingDivider = [[colorOutgoing adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];
	
	colorIncoming = [[[prefDict objectForKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR] representedColor] retain];
	colorIncomingBorder = [[colorIncoming adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	colorIncomingDivider = [[colorIncoming adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];
	
	
	//Coloring
	/*
	 colorIncoming = [[NSColor colorWithCalibratedRed:(229.0/255.0) green:(242.0/255.0) blue:(255.0/255.0) alpha:1.0] retain];
	 colorIncomingBorder = [[colorIncoming adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	 colorIncomingDivider = [[colorIncoming adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];
	 colorOutgoing = [[NSColor colorWithCalibratedRed:(230.0/255.0) green:(255.0/255.0) blue:(234.0/255.0) alpha:1.0] retain];
	 colorOutgoingBorder = [[colorOutgoing adjustHue:0.0 saturation:+0.3 brightness:-0.3] retain];
	 colorOutgoingDivider = [[colorOutgoing adjustHue:0.0 saturation:+0.1 brightness:-0.1] retain];
	 */
	
	//Ignorance
	ignoreTextStyles = [[prefDict objectForKey:KEY_SMV_IGNORE_TEXT_STYLES] boolValue];
	
	//Force icons off for side prefixes
	if([prefixIncoming rangeOfString:@"%m"].location != NSNotFound) showUserIcons = NO;
	
	//Pad bottom of the message view depending on mode
	[messageView setContentPaddingTop:0 bottom:(inlinePrefixes ? 3 : 0)];
	
	//Indentation when combining messages in appropriate modes
	headIndent = [[prefDict objectForKey:KEY_SMV_COMBINE_MESSAGES_INDENT] floatValue];
	
	//Reset all content objects if a preference actually changed
	if(!firstTime) [self rebuildMessageViewForContent];
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
        abandonRebuilding = NO;
        
        //lock the addition of rows down with rebuilding=YES
        rebuilding = YES;
        [NSThread detachNewThreadSelector:@selector(_rebuildMessageViewForContentThread) toTarget:self withObject:nil];
    }
}

-(void)_rebuildMessageViewForContentThread
{
    AIContentObject    *content;
    NSMutableArray      *rowArray = [[NSMutableArray alloc] init];
    AIFlexibleTableRow  *row;
    
    //The first row has no previous row
    previousRow = nil;
    
    //In a separate thread, so create an autorelease pool for the NSEnumerator objects
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //Lock the flexible table view
    [messageView lockTable];
    
    //Re-add all content one row at a time (slooow)
    NSEnumerator        *enumerator_chat = [[chat contentObjectArray] reverseObjectEnumerator]; //(Content is stored in reverse order)
    while((content = [enumerator_chat nextObject]) && !restartRebuilding && !abandonRebuilding){
        NSArray *contentRowArray = [[self _rowsForAddingContentObject:content] retain];
        NSEnumerator        *enumerator_two = [contentRowArray objectEnumerator];

        while (row = [enumerator_two nextObject]) {
            [rowArray addObject:row];
        }
        
        [contentRowArray release];
    }
    
    //Move everything out
    if (!restartRebuilding && !abandonRebuilding) {
        [messageView removeAllRows];
    }
    
    NSEnumerator *rowArray_enumerator = [rowArray objectEnumerator];
    while ((row = [rowArray_enumerator nextObject]) && !restartRebuilding && !abandonRebuilding){
        [self performSelectorOnMainThread:@selector(addRowToMessageView:) withObject:row waitUntilDone:YES];

    }

    //restart the rebuilding process if necessary
    if (restartRebuilding && !abandonRebuilding){
        restartRebuilding = NO;
        
        [self _rebuildMessageViewForContentThread];
    }
    
	
    while ([contentThreadQueue count] && !abandonRebuilding) {

		//Lock the contentThreadQueue, make an array of its objects, clear out contentThreadQueue, then unlock it
		lockContentThreadQueue = YES;
		NSArray *secondaryThreadContentThreadQueue = [NSArray arrayWithArray:contentThreadQueue];
		[contentThreadQueue removeAllObjects];
		lockContentThreadQueue = NO;
		
        NSEnumerator    *enumerator = [secondaryThreadContentThreadQueue objectEnumerator];
        AIContentObject *queuedContent;
        
        while ( (queuedContent = [enumerator nextObject]) && !abandonRebuilding) {
            [self performSelectorOnMainThread:@selector(_addContentObject:) withObject:queuedContent waitUntilDone:YES];
        }
    }
    
    rebuilding = NO;
    
    [self performSelectorOnMainThread:@selector(unlockMessageView) withObject:nil waitUntilDone:YES];
  
    [rowArray release];
    [pool release];
}

- (void)unlockMessageView
{
    [messageView unlockTable];
}

- (void)setNeedsDisplay
{
    [messageView setNeedsDisplay:YES];   
}

- (void)removeAllRows
{
    [messageView removeAllRows];
}

- (void)addRowToMessageView:(AIFlexibleTableRow *)row
{
    [messageView addRow:row]; 
}
                             
//queue a content object for later addition to the view when the thread is done rebuilding
- (void)_addContentObjectToThreadQueue:(AIContentObject *)content
{
	//Pause execution until lockContentThreadQueue=NO... which should be quite soon now.
	while (lockContentThreadQueue);
	
    [contentThreadQueue addObject:content];
}

//Return our message view to be inserted into a message window
- (NSView *)messageView
{
    return(scrollView_messages);
}
//Return our scroll view, which is the same as our message view
- (NSView *)messageScrollView
{
    return(scrollView_messages);	
}

//Return our chat
- (AIChat *)chat
{
    return(chat);
}

//Add a new content object
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentObject	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
    
    //If we are not currently rebuilding, add it immediately; if we are, add it to our queue
    if (!rebuilding)
        [self _addContentObject:content];
    else
        [self _addContentObjectToThreadQueue:content];
}

//Add rows for a content object
- (void)_addContentObject:(AIContentObject *)content
{
    if([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        [self _addContentMessage:(AIContentMessage *)content];
	}else if([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
        [self _addContentContext:(AIContentContext *)content];
    }else if([[content type] isEqualToString:CONTENT_STATUS_TYPE]){
        [self _addContentStatus:(AIContentStatus *)content];
    }
}

- (NSArray *)_rowsForAddingContentObject:(AIContentObject *)content
{
    if([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        return [self _rowsForAddingContentMessage:(AIContentMessage *)content];
	} else if([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]){
        return [self _rowsForAddingContentContext:(AIContentContext *)content];
    }else if([[content type] isEqualToString:CONTENT_STATUS_TYPE]){
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

//Add rows for a context message object
- (void)_addContentContext:(AIContentContext *)content
{
    NSArray             *rowArray = [[self _rowsForAddingContentContext:content] retain];
    
    NSEnumerator        *enumerator = [rowArray objectEnumerator];
    AIFlexibleTableRow  *row;
    
    while (row = [enumerator nextObject]) {
        [messageView addRow:row];
    }
    
    [rowArray release];
}


//Add rows for a queued content message object
- (void)_addQueuedContentMessage:(AIContentMessage *)content
{
    NSArray             *rowArray = [[self _rowsForAddingContentMessage:content] retain];
    
    NSEnumerator        *enumerator = [rowArray objectEnumerator];
    AIFlexibleTableRow  *row;
    
    while (row = [enumerator nextObject]) {
        [row setOpacity:QUEUED_MESSAGE_OPACITY];
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
	
	//Always start a new bubble if enough time has elapsed since the last content
	if(contentIsSimilar && [[content date] timeIntervalSinceDate:[(AIContentMessage*)previousContent date]] >= NEW_BUBBLE_TIME)
		contentIsSimilar = NO;
    
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
        
        enumerator = [[previousRow cellsWithClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawBottom:NO];
        }
		
        enumerator = [[messageRow cellsWithClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawTop:NO];
        }
        
        //draw the between-messages divider in the last framedTextCell in the row, which should be the message
        [[messageRow lastCellWithClass:[AIFlexibleTableFramedTextCell class]] setDrawTopDivider:YES];
        
        if(!inlinePrefixes) [[previousRow cellWithClass:[AIFlexibleTableImageCell class]] setRowSpan:2];
    }
    
    previousRow = messageRow;
    
    NSArray *returnArray;
    if (prefixRow)
        returnArray = [NSArray arrayWithObjects:prefixRow,messageRow,nil];
    else
        returnArray = [NSArray arrayWithObject:messageRow];
    return (returnArray);
}

//returns an autoreleased array of the rows which represent context
- (NSArray *)_rowsForAddingContentContext:(AIContentContext *)content
{
    //Previous row (which WILL be a AIContentMessage or AIContentContext when adding Context
	AIContentStatus		*dateSeparator = nil;
    AIContentMessage	*previousContent = [previousRow representedObject];
    AIFlexibleTableRow  *prefixRow = nil, *messageRow = nil;
    BOOL                contentIsSimilar = NO;

    //We should merge if the previous content is a message and from the same source AND same day
    if((!inlinePrefixes || combineMessages) &&
       (previousContent && [[previousContent type] compare:[content type]] == 0 && [content source] == [previousContent source]) &&
	   ([previousContent isFromSameDayAsContent:content])){
        contentIsSimilar = YES;
    }
	
	//Show a date header if the messages were on different dates
	if( !contentIsSimilar && (![previousContent isFromSameDayAsContent:content])) {
		
		NSString *dateMessage = [[NSDateFormatter localizedDateFormatter] stringForObjectValue:[content date]];
		dateSeparator = [AIContentStatus statusInChat:[content chat]
										   withSource:[[content chat] listObject]
										  destination:[[content chat] account]
												 date:[content date]
											  message:[NSAttributedString stringWithString:dateMessage]
											 withType:@"date_separator"];
		
		//Add the date header
		AIFlexibleTableRow *row = [self _rowForAddingContentStatus:dateSeparator];
		[messageView addRow:row];
	}
	
	//Always start a new bubble if enough time has elapsed since the last content
	if(contentIsSimilar && [[content date] timeIntervalSinceDate:[(AIContentContext *)previousContent date]] >= NEW_BUBBLE_TIME)
		contentIsSimilar = NO;
    
    //If we are using inline prefixes, and this message is different from the previous one, insert a prefix row 
    if(inlinePrefixes && !contentIsSimilar){
        prefixRow = [self _prefixRowForContent:(AIContentMessage *)content];
    }
    
    //Add our message
    messageRow = [self _messageRowForContent:(AIContentMessage *)content
								 previousRow:(prefixRow ? prefixRow : previousRow)
									  header:(!inlinePrefixes && !contentIsSimilar)];
    
    //Merge our new message with the previous one
    if(contentIsSimilar){  
        NSEnumerator        *enumerator;
        AIFlexibleTableFramedTextCell *cell;
        
        enumerator = [[previousRow cellsWithClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawBottom:NO];
        }
		
        enumerator = [[messageRow cellsWithClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
        while (cell = [enumerator nextObject]) {
            [cell setDrawTop:NO];
        }
        
        //draw the between-messages divider in the last framedTextCell in the row, which should be the message
        [[messageRow lastCellWithClass:[AIFlexibleTableFramedTextCell class]] setDrawTopDivider:YES];
        
        if(!inlinePrefixes) [[previousRow cellWithClass:[AIFlexibleTableImageCell class]] setRowSpan:2];
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
    AIFlexibleTableRow *row = [self _rowForAddingContentStatus:content];
    [messageView addRow:row];
}

- (AIFlexibleTableRow *)_rowForAddingContentStatus:(AIContentStatus *)content
{
    //Add the status change
    AIFlexibleTableRow *row = [self _statusRowForContent:content];
    
    //Add a separator to our previous row if necessary
    AIFlexibleTableFramedTextCell *cell;
    NSEnumerator * enumerator = [[previousRow cellsWithClass:[AIFlexibleTableFramedTextCell class]] objectEnumerator];
    while (cell = [enumerator nextObject]) {
        [cell setDrawBottom:YES];
    }
    
    return(row);
}


//Rows -----------------------------------------------------------------------------------------------------------------
#pragma mark Rows
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
    AIFlexibleTableCell     *leftmostCell = nil, *messageCell = nil;
    NSArray					*cellArray;
    AIFlexibleTableRow      *row;
	BOOL					emptyHeadIndentCell;
	
    //Empty icon span cell
    if(showUserIcons){
		if(isHeader){
			leftmostCell = [self _userIconCellForContent:content span:NO];
		}else if(thePreviousRow){
			leftmostCell = [self _emptyImageSpanCellForPreviousRow:thePreviousRow];
		}        
    }
	
    //Empty spacing cell
	emptyHeadIndentCell = (!isHeader && !inlinePrefixes && combineMessages);
    if (emptyHeadIndentCell) {
        leftmostCell = [self _emptyHeadIndentCellForPreviousRow:thePreviousRow content:content];
    }
	
    //
    if(leftmostCell){
		messageCell = [self _messageCellForContent:content includingPrefixes:NO shouldPerformHeadIndent:NO];
		
		if (emptyHeadIndentCell) {
			
			//dchoby98 -- empty indent space
			//NSColor *messageBackgroundColor = [messageCell contentBackgroundColor];
			//if( [[content type] compare:CONTENT_CONTEXT_TYPE] == 0 )
			//	messageBackgroundColor = [messageBackgroundColor darkenAndAdjustSaturationBy:-0.3];
							
			//if (messageBackgroundColor) {
			//	[leftmostCell setBackgroundColor:messageBackgroundColor];
				
			//	if ([leftmostCell isKindOfClass:[AIFlexibleTableFramedTextCell class]])
			//		[(AIFlexibleTableFramedTextCell *)leftmostCell setFrameBackgroundColor:messageBackgroundColor];
			//}
		}
		
        cellArray = [NSArray arrayWithObjects:leftmostCell, messageCell, nil];
    }else{
		messageCell = [self _messageCellForContent:content includingPrefixes:!inlinePrefixes shouldPerformHeadIndent:(isHeader && !inlinePrefixes && combineMessages)];
        cellArray = [NSArray arrayWithObjects:messageCell, nil];
    }
	
    row = [AIFlexibleTableRow rowWithCells:cellArray representedObject:content];
    
	//set the headIndent
    [row setHeadIndent:headIndent];
    
	return(row);
}


//Cells ----------------------------------------------------------------------------------------------------------------
#pragma mark Cells
//Status cell
//Uses the current time stamp format
- (AIFlexibleTableCell *)_statusCellForContent:(AIContentStatus *)content
{
	NSString			*messageString;
    AIFlexibleTableCell	*statusCell;

	// If no date specified, don't show one
	if( [content date] != nil ) {
		NSString *dateString = [timeStampFormatter stringForObjectValue:[content date]];
		messageString = [NSString stringWithFormat:@"%@ (%@)", [[content message] string], dateString];
	} else {
		messageString = [NSString stringWithFormat:@"%@", [[content message] string]];
	}
	
    //Create the status text cell
    statusCell = [AIFlexibleTableTextCell cellWithString:messageString
												   color:[NSColor grayColor]
													font:[NSFont cachedFontWithName:@"Helvetica" size:11]
											   alignment:NSCenterTextAlignment];
    [statusCell setPaddingLeft:1 top:0 right:1 bottom:0];
    [statusCell setVariableWidth:YES];
	
    return(statusCell);
}

//User icon cell
- (AIFlexibleTableCell *)_userIconCellForContent:(AIContentObject *)content span:(BOOL)span
{
    AIFlexibleTableImageCell    *imageCell;
    NSImage			*userImage;
    
    //Get the user icon
    userImage = [[content source] userIcon];
    if(!userImage) userImage = ([content isOutgoing] ? iconOutgoing : iconIncoming);
    
    //Create the spanning image cell
    imageCell = [AIFlexibleTableImageCell cellWithImage:userImage];
    [imageCell setPaddingLeft:3 top:6 right:3 bottom:1];
    [imageCell setBackgroundColor:[NSColor whiteColor]];
    [imageCell setDesiredFrameSize:NSMakeSize(ICON_SIZE,ICON_SIZE)];
	
    return(imageCell);
}

//Span cell with the last image cell as it's master
- (AIFlexibleTableCell *)_emptyImageSpanCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow
{
    id  masterCell;
    
    //Get the master cell
    masterCell = [thePreviousRow cellWithClass:[AIFlexibleTableImageCell class]];
    if(!masterCell) masterCell = [[thePreviousRow cellWithClass:[AIFlexibleTableSpanCell class]] masterCell];
    
    if(masterCell){	
		//Increase it's span height
		[masterCell setRowSpan:[masterCell rowSpan] + 1];
		
		//Create our span cell as one of it's children
		return([AIFlexibleTableSpanCell spanCellFor:masterCell spannedIndex:[masterCell rowSpan]-1]);
		
    }else{
		return(nil);	
    }    
}

- (AIFlexibleTableCell *)_emptyHeadIndentCellForPreviousRow:(AIFlexibleTableRow *)thePreviousRow content:(AIContentMessage *)content
{
    AIFlexibleTableFramedTextCell * cell = [[AIFlexibleTableFramedTextCell alloc] init];
	NSColor *currentOutgoingDividerColor = colorOutgoingDivider;
	NSColor *currentIncomingDividerColor = colorIncomingDivider;
	NSColor *currentIncomingColor = colorIncoming;
	NSColor *currentOutgoingColor = colorOutgoing;
	
	if( [[content type] compare:CONTENT_CONTEXT_TYPE] == 0 ) {
		currentOutgoingDividerColor = [currentOutgoingDividerColor darkenAndAdjustSaturationBy:-0.3];
		currentIncomingDividerColor = [currentIncomingDividerColor darkenAndAdjustSaturationBy:-0.3];
		currentIncomingColor = [currentIncomingColor darkenAndAdjustSaturationBy:-0.3];
		currentOutgoingColor = [currentOutgoingColor darkenAndAdjustSaturationBy:-0.3];
	}
	
	
    //size the cell for the previousRow headIndent value
    [cell sizeCellForWidth:[thePreviousRow headIndent]];
	
    if([content isOutgoing]){
        [cell setFrameBackgroundColor:currentOutgoingColor borderColor:colorOutgoingBorder dividerColor:currentOutgoingDividerColor];
    }else{
        [cell setFrameBackgroundColor:currentIncomingColor borderColor:colorIncomingBorder dividerColor:currentIncomingDividerColor];
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
    NSAttributedString		    	*messageString;
 	NSColor 						*bodyColor = nil;
	NSColor							*backgroundColor;
	
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
	if([[content message] length]){
		bodyColor = [[content message] attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil];
	}
    if(![content isOutgoing]){
		if(ignoreTextStyles || !bodyColor || [bodyColor equalToRGBColor:[NSColor whiteColor]]){
	
			//dchoby98
			if( [[content type] compare:CONTENT_CONTEXT_TYPE] == 0 )
				backgroundColor = [colorIncoming darkenAndAdjustSaturationBy:-0.3];
			else
				backgroundColor = colorIncoming;
			
			[messageCell setFrameBackgroundColor:backgroundColor borderColor:colorIncomingBorder dividerColor:colorIncomingDivider];
		}else{
			[messageCell setFrameBackgroundColor:bodyColor
									 borderColor:[bodyColor darkenAndAdjustSaturationBy:0.3]
									dividerColor:[bodyColor darkenAndAdjustSaturationBy:0.1]];
		}
    }else{
		if(!bodyColor || [bodyColor equalToRGBColor:[NSColor whiteColor]]){
			
			//dchoby98
			if( [[content type] compare:CONTENT_CONTEXT_TYPE] == 0 )
				backgroundColor = [colorOutgoing darkenAndAdjustSaturationBy:-0.3];
			else
				backgroundColor = colorOutgoing;
			
			[messageCell setFrameBackgroundColor:backgroundColor borderColor:colorOutgoingBorder dividerColor:colorOutgoingDivider];
		}else{
			[messageCell setFrameBackgroundColor:bodyColor
									 borderColor:[bodyColor darkenAndAdjustSaturationBy:0.3]
									dividerColor:[bodyColor darkenAndAdjustSaturationBy:0.1]];
		}
    }
    
    return(messageCell);
}


//Prefix Creation ------------------------------------------------------------------------------------------------------
#pragma mark Prefix Creation
//Message without a prefix
- (NSAttributedString *)_messageStringForContent:(AIContentMessage *)content
{
	NSAttributedString * messageString;
	//Strip all coloring and formatting of received messages if desired
	if([[content type] compare:CONTENT_CONTEXT_TYPE] == 0) {
		messageString = [self _stringWithContextStyle:[content message]];
	}else if([content isOutgoing] || !ignoreTextStyles) {
        messageString = [content message];
    }else{
        messageString = [self _stringByRemovingAllStyles:[content message]];
    }    
	return [messageString stringByAddingFormattingForLinks];
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
        
        [prefixString appendAttributedString:[self _messageStringForContent:content]];
		
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
	
	NSColor		*currentOutgoingSourceColor = outgoingSourceColor;
	NSColor		*currentIncomingSourceColor = incomingSourceColor;
	
	if( [[content type] compare:CONTENT_CONTEXT_TYPE] == 0 ) {
		currentOutgoingSourceColor = [currentOutgoingSourceColor darkenAndAdjustSaturationBy:-0.3];
		currentIncomingSourceColor = [currentIncomingSourceColor darkenAndAdjustSaturationBy:-0.3];
	}
	
    //Create an attributed string from it with the prefix font and colors
    NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        ([content isOutgoing] ? currentOutgoingSourceColor : currentIncomingSourceColor), NSForegroundColorAttributeName,
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
					case 'n': [string appendString:[[content source] formattedUID]]; break;
					case 't': [string appendString:[timeStampFormatter stringForObjectValue:[content date]]]; break;
					case 'r': if([content isAutoreply])[string appendString:@" (Autoreply)"]; break;
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
						case 'a': present = ([[[content source] displayName] compare:[[content source] formattedUID]] != 0); break;
						case 'n': present = YES; break;
						case 't': present = YES; break;
						case 'r': present = [content isAutoreply]; break;
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


//Misc -----------------------------------------------------------------------------------------------------------------
#pragma mark Misc
//Remove font, text and background color from an attributed string
- (NSAttributedString *)_stringByRemovingAllStyles:(NSAttributedString *)inString
{
    NSMutableAttributedString   *mutableTemp = [[inString mutableCopy] autorelease];
    NSRange range = NSMakeRange(0,[mutableTemp length]);
    [mutableTemp removeAttribute:NSForegroundColorAttributeName range:range];
    [mutableTemp removeAttribute:NSBackgroundColorAttributeName range:range];
	[mutableTemp removeAttribute:NSFontAttributeName range:range];
    return(mutableTemp);
}

//Lighten a string's text color if it is to be displayed as context
- (NSAttributedString *)_stringWithContextStyle:(NSAttributedString *)inString
{
	NSMutableAttributedString   *mutableTemp;
	
	// Remove all attributes
	//tempString = [self _stringByRemovingAllStyles:inString];
	mutableTemp = [[inString mutableCopy] autorelease];
	NSRange range = NSMakeRange(0,[mutableTemp length]);
	
	// Then make the string gray
	[mutableTemp addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:range];
	return(mutableTemp);

}


//Modifies an attributed string to be visible on the background color
- (NSAttributedString *)_stringByFixingTextColor:(NSAttributedString *)inString forColor:(NSColor *)inColor
{
    NSMutableAttributedString   *mutableTemp = [[inString mutableCopy] autorelease];
    
    //adjust foreground colors for the incoming message background
    [mutableTemp adjustColorsToShowOnBackgroundRelativeToOriginalBackground:inColor];
    
    return(mutableTemp);
}

//Context menu
-(NSMenu *)contextualMenuForFlexibleTableView:(AIFlexibleTableView *)tableView
{
    AIListContact	*selectedObject = [chat listObject];
    
    if(selectedObject){
		NSArray *locations;
		if ([selectedObject isStranger]){
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}else{
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}
		
		return([[adium menuController] contextualMenuWithLocations:locations
													 forListObject:selectedObject]);
    }else{
		return(nil);
	}
}

@end

