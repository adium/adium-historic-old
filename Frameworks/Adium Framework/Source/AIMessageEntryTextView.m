/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIObject.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/ESFileWrapperExtension.h>
#import <Adium/AITextAttachmentExtension.h>

#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContentContext.h>

#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>

#import <AIUtilities/AITigerCompatibility.h>

#import <FriBidi/NSString-FBAdditions.h>

#define MAX_HISTORY					25		//Number of messages to remember in history
#define ENTRY_TEXTVIEW_PADDING		6		//Padding for auto-sizing

#define KEY_DISABLE_TYPING_NOTIFICATIONS		@"Disable Typing Notifications"

#define KEY_SPELL_CHECKING						@"Spell Checking Enabled"
#define KEY_GRAMMAR_CHECKING					@"Grammar Checking Enabled"
#define	PREF_GROUP_DUAL_WINDOW_INTERFACE		@"Dual Window Interface"

#define INDICATOR_RIGHT_PADDING					10		// Padding between right side of the message view and the rightmost indicator
#define INDICATOR_BOTTOM_PADDING				2		// Padding between the bottom of the message view and any indicator

#define PREF_GROUP_CHARACTER_COUNTER			@"Character Counter"
#define KEY_CHARACTER_COUNTER_ENABLED			@"Character Counter Enabled"
#define KEY_MAX_NUMBER_OF_CHARACTERS			@"Maximum Number Of Characters"

#define FILES_AND_IMAGES_TYPES [NSArray arrayWithObjects: \
	NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType, nil]

#define PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY [NSArray arrayWithObjects: \
	NSRTFPboardType, NSStringPboardType, nil]

/**
 * @class AITwitterCharacterCounterView
 * @brief Indicates how many characters you have in your message budget.
 *
 * Some services, such as Twitter, impose a maximum size per message. This view indicates when the user is approaching the maximum.
 *
 * The view is a grid of four by four square-shaped dots, each three points square, with one-point gaps between adjacent dots. Each dot represents one character remaining; thus, if the user has 16 or more characters remaining, then all the dots will be visible, but if the user dips below 16, then dots will go away one by one. If the user runs out, no more dots are visible, and the controller may want to forbid the user from entering any more characters.
 */

@implementation  AITwitterCharacterCounterView
enum {
	TCC_dot_size = 3,
	TCC_dot_spacing = 1,
	TCC_dot_offset = TCC_dot_size + TCC_dot_spacing
};

+ (NSSize) idealSize {
	float sideSize = (TCC_dot_size * 4U + TCC_dot_spacing * 3U);
	return (NSSize){ sideSize, sideSize };
}

- (NSColor *) remainingDotColor {
	return remainingDotColor;
}
- (void) setRemainingDotColor:(NSColor *)newRemainingDotColor {
	if(remainingDotColor != newRemainingDotColor) {
		[remainingDotColor release];
		remainingDotColor = [newRemainingDotColor retain];
	}
}

- (NSColor *) usedDotColor {
	return usedDotColor;
}
- (void) setUsedDotColor:(NSColor *)newUsedDotColor {
	if(usedDotColor != newUsedDotColor) {
		[usedDotColor release];
		usedDotColor = [newUsedDotColor retain];
	}
}

- (NSColor *) noCharactersRemainingDotColor {
	return noCharactersRemainingDotColor;
}
- (void) setNoCharactersRemainingDotColor:(NSColor *)newNoCharactersRemainingDotColor {
	if(noCharactersRemainingDotColor != newNoCharactersRemainingDotColor) {
		[noCharactersRemainingDotColor release];
		noCharactersRemainingDotColor = [newNoCharactersRemainingDotColor retain];
	}
}

- (NSUInteger) numberOfColumns {
	return numberOfColumns;
}
- (void) setNumberOfColumns:(NSUInteger)newNumberOfColumns {
	numberOfColumns = newNumberOfColumns;
}

- (NSUInteger) numberOfRows {
	return numberOfRows;
}
- (void) setNumberOfRows:(NSUInteger)newNumberOfRows {
	numberOfRows = newNumberOfRows;
}

- (void) updateToolTip {
	if (currentMessageSize >= maximumMessageSize) {
		[self setToolTip:[NSString stringWithFormat:AILocalizedString(@"You've used all of the %u characters that you're allowed!", /*comment*/ @"Tooltips for character-counter view"), maximumMessageSize]];
	} else {
		NSUInteger balance = maximumMessageSize - currentMessageSize;
		NSUInteger numberOfDots = numberOfColumns * numberOfRows;

		if (balance >= numberOfDots) {
			[self setToolTip:[NSString stringWithFormat:AILocalizedString(@"%u of %u characters remaining.\n\n"@"These dots will begin to disappear once you have fewer than %u characters remaining. This indicates that you may need to edit your message to fit it into the allowed space.", /*comment*/ @"Tooltips for character-counter view"), balance, maximumMessageSize, numberOfDots]];
		} else {
			//User is running out.
			[self setToolTip:[NSString stringWithFormat:AILocalizedString(@"%u of %u characters remaining.\n\n"@"%u of these dots are gone because you have so few characters remaining. You're running low, and you may need to edit your message to fit it into the allowed space.", /*comment*/ @"Tooltips for character-counter view"), balance, maximumMessageSize, (numberOfDots - balance)]];
		}
	}
}

- (NSUInteger) currentMessageSize {
	return currentMessageSize;
}
- (void) setCurrentMessageSize:(NSUInteger)newCurrentMessageSize {
	currentMessageSize = newCurrentMessageSize;
	[self updateToolTip];
}

- (NSUInteger) maximumMessageSize {
	return maximumMessageSize;
}
- (void) setMaximumMessageSize:(NSUInteger)newMaximumMessageSize {
	maximumMessageSize = newMaximumMessageSize;
	[self updateToolTip];
}

#pragma mark -

- (id) initWithFrame:(NSRect)newFrame
{
	if ((self = [super initWithFrame:newFrame])) {
		remainingDotColor = [[NSColor blackColor] retain];
		usedDotColor = [[[NSColor blackColor] colorWithAlphaComponent:0.1f] retain]; //10% opacity
		noCharactersRemainingDotColor = [[[NSColor redColor] colorWithAlphaComponent:0.75f] retain];

		numberOfRows = numberOfColumns = 4U;
	}
	return self;
}

- (void)dealloc
{
	[remainingDotColor release];
	[usedDotColor release];
	[noCharactersRemainingDotColor release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
	/*Array indices (where numberOfRows = numberOfColumns = 4U):
	 *15 14 13 12
	 *11 10 09 08
	 *07 06 05 04
	 *03 02 01 00
	 *
	 *The reason for this order is so that dots disappear in standard Western reading order (left to right, top to bottom).
	 */

	NSUInteger balance = (maximumMessageSize < currentMessageSize)
		? 0U
		: (maximumMessageSize - currentMessageSize);

	NSUInteger idx;
	NSBezierPath *bezierPath;
	NSUInteger numberOfDots = numberOfColumns * numberOfRows;

	bezierPath = [NSBezierPath bezierPath];
	[remainingDotColor set];
	for (idx = 0U; idx < balance && idx < numberOfDots; ++idx) {
		NSUInteger column = idx % numberOfRows;
		column = (numberOfColumns - column) - 1U; //Invert from 0..3 to 3..0
		NSUInteger row    = idx / numberOfRows;

		NSRect dotRect = { { TCC_dot_offset * column, TCC_dot_offset * row }, { TCC_dot_size, TCC_dot_size } };
		[bezierPath appendBezierPathWithRect:dotRect];
	}
	[bezierPath fill];

	bezierPath = [NSBezierPath bezierPath];
	[(balance > 0U ? usedDotColor : noCharactersRemainingDotColor) set];
	for (idx = balance; idx < numberOfDots; ++idx) {
		NSUInteger column = idx % numberOfRows;
		column = (numberOfColumns - column) - 1U; //Invert from 0..3 to 3..0
		NSUInteger row    = idx / numberOfRows;

		NSRect dotRect = { { TCC_dot_offset * column, TCC_dot_offset * row }, { TCC_dot_size, TCC_dot_size } };
		[bezierPath appendBezierPathWithRect:dotRect];
	}
	[bezierPath fill];
}
@end

@interface AIMessageEntryTextView (PRIVATE)
- (void)_setPushIndicatorVisible:(BOOL)visible;
- (void)positionPushIndicator;
- (void)_resetCacheAndPostSizeChanged;

- (NSAttributedString *)attributedStringWithAITextAttachmentExtensionsFromRTFDData:(NSData *)data;
- (NSAttributedString *)attributedStringWithTextAttachmentExtension:(AITextAttachmentExtension *)attachment;
- (void)addAttachmentOfPath:(NSString *)inPath;
- (void)addAttachmentOfImage:(NSImage *)inImage;
- (void)addAttachmentsFromPasteboard:(NSPasteboard *)pasteboard;

- (void)setCharacterCounterVisible:(BOOL)visible;
- (void)setCharacterCounterMaximum:(int)inMaxCharacters;
- (void)updateCharacterCounter;
- (void)positionCharacterCounter;

- (void)positionIndicators:(NSNotification *)notification;
@end

@interface NSMutableAttributedString (AIMessageEntryTextViewAdditions)
- (void)convertForPasteWithTraitsUsingAttributes:(NSDictionary *)inAttributes;
@end

@implementation AIMessageEntryTextView

- (void)_initMessageEntryTextView
{
	adium = [AIObject sharedAdiumInstance];
	associatedView = nil;
	chat = nil;
	pushIndicator = nil;
	pushPopEnabled = YES;
	historyEnabled = YES;
	clearOnEscape = NO;
	homeToStartOfLine = YES;
	resizing = NO;
	enableTypingNotifications = NO;
	historyArray = [[NSMutableArray alloc] initWithObjects:@"",nil];
	pushArray = [[NSMutableArray alloc] init];
	currentHistoryLocation = 0;
	[self setDrawsBackground:YES];
	_desiredSizeCached = NSMakeSize(0,0);
	characterCounter = nil;
	maxCharacters = 0;
	
	if ([self respondsToSelector:@selector(setAllowsUndo:)]) {
		[self setAllowsUndo:YES];
	}
	if ([self respondsToSelector:@selector(setAllowsDocumentBackgroundColorChange:)]) {
		[self setAllowsDocumentBackgroundColorChange:YES];
	}
	
	[self setImportsGraphics:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(textDidChange:)
												 name:NSTextDidChangeNotification 
											   object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(frameDidChange:) 
												 name:NSViewFrameDidChangeNotification 
											   object:self];
	[[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self
															selector:@selector(toggleMessageSending:)
																name:@"AIChatDidChangeCanSendMessagesNotification"
															  object:chat];
	[[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self 
															selector:@selector(contentObjectAdded:) 
																name:Content_ContentObjectAdded 
															  object:nil];

	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];	
}

//Init the text view
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
	if ((self = [super initWithFrame:frameRect textContainer:aTextContainer])) {
		[self _initMessageEntryTextView];
	}
	
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self _initMessageEntryTextView];
	}
	
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:self];

    [chat release];
    [associatedView release];
    [historyArray release]; historyArray = nil;
    [pushArray release]; pushArray = nil;

    [super dealloc];
}

//
- (void)keyDown:(NSEvent *)inEvent
{
	NSString *charactersIgnoringModifiers = [inEvent charactersIgnoringModifiers];

	if ([charactersIgnoringModifiers length]) {
		unichar		 inChar = [charactersIgnoringModifiers characterAtIndex:0];
		unsigned int flags = [inEvent modifierFlags];
		
		//We have to test ctrl before option, because otherwise we'd miss ctrl-option-* events
		if (pushPopEnabled &&
			(flags & NSControlKeyMask) && !(flags & NSShiftKeyMask)) {
			if (inChar == NSUpArrowFunctionKey) {
				[self popContent];
			} else if (inChar == NSDownArrowFunctionKey) {
				[self pushContent];
			} else if (inChar == 's') {
				[self swapContent];
			} else {
				[super keyDown:inEvent];
			}
			
		} else if (historyEnabled && 
				   (flags & NSAlternateKeyMask) && !(flags & NSShiftKeyMask)) {
			if (inChar == NSUpArrowFunctionKey) {
				[self historyUp];
			} else if (inChar == NSDownArrowFunctionKey) {
				[self historyDown];
			} else {
				[super keyDown:inEvent];
			}
			
		} else if (associatedView &&
				   (flags & NSCommandKeyMask) && !(flags & NSShiftKeyMask)) {
			if ((inChar == NSUpArrowFunctionKey || inChar == NSDownArrowFunctionKey) ||
			   (inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey) ||
			   (inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey)) {
				//Pass the associatedView a keyDown event equivalent equal to inEvent except without the modifier flags
				[associatedView keyDown:[NSEvent keyEventWithType:[inEvent type]
														 location:[inEvent locationInWindow]
													modifierFlags:0
														timestamp:[inEvent timestamp]
													 windowNumber:[inEvent windowNumber]
														  context:[inEvent context]
													   characters:[inEvent characters]
									  charactersIgnoringModifiers:charactersIgnoringModifiers
														isARepeat:[inEvent isARepeat]
														  keyCode:[inEvent keyCode]]];
			} else {
				[super keyDown:inEvent];
			}
			
		} else if (associatedView &&
				   (inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey)) {
			[associatedView keyDown:inEvent];
			
		} else if (inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey) {
			if (homeToStartOfLine) {
				NSRange	newRange;
				
				if (flags & NSShiftKeyMask) {
					//With shift, select to the beginning/end of the line
					NSRange	selectedRange = [self selectedRange];
					if (inChar == NSHomeFunctionKey) {
						//Home: from 0 to the current location
						newRange.location = 0;
						newRange.length = selectedRange.location;
					} else {
						//End: from current location to the end
						newRange.location = selectedRange.location;
						newRange.length = [[self string] length] - newRange.location;
					}
					
				} else {
					newRange.location = ((inChar == NSHomeFunctionKey) ? 0 : [[self string] length]);
					newRange.length = 0;
				}

				[self setSelectedRange:newRange];

			} else {
				//If !homeToStartOfLine, pass the keypress to our associated view.
				if (associatedView) {
					[associatedView keyDown:inEvent];
				} else {
					[super keyDown:inEvent];					
				}
			}

		} else if (inChar == NSTabCharacter) {
			if ([[self delegate] respondsToSelector:@selector(textViewShouldTabComplete:)] &&
				[[self delegate] textViewShouldTabComplete:self]) {
				[self complete:nil];
			} else {
				[super keyDown:inEvent];				
			} 

		} else {
			[super keyDown:inEvent];
		}
	} else {
		[super keyDown:inEvent];
	}
}

//Text changed
- (void)textDidChange:(NSNotification *)notification
{
	//Update typing status
	if (enableTypingNotifications) {
		[[adium contentController] userIsTypingContentForChat:chat hasEnteredText:[[self textStorage] length] > 0];
	}

	//Hide any existing contact list tooltip when we begin typing
	[[adium interfaceController] showTooltipForListObject:nil atScreenPoint:NSZeroPoint onWindow:nil];

    //Reset cache and resize
	[self _resetCacheAndPostSizeChanged]; 
	
	//Update the character counter
	if (characterCounter) {
		[self updateCharacterCounter];
	}
}

/*!
 * @brief Clear any link attribute in the current typing attributes
 *
 * Any link attribute is removed. All other typing attributes are unchanged.
 */
- (void)clearLinkAttribute
{
	NSDictionary *typingAttributes = [self typingAttributes];

	if ([typingAttributes objectForKey:NSLinkAttributeName]) {
		NSMutableDictionary *newTypingAttributes = [typingAttributes mutableCopy];

		[newTypingAttributes removeObjectForKey:NSLinkAttributeName];
		[self setTypingAttributes:newTypingAttributes];

		[newTypingAttributes release];
	}
}

/*!
 * @brief The user pressed escape: clear our text view in response
 */
- (void)cancelOperation:(id)sender
{
	if (clearOnEscape) {
		NSUndoManager	*undoManager = [self undoManager];
		[undoManager registerUndoWithTarget:self
								   selector:@selector(setAttributedString:)
									 object:[[[self textStorage] copy] autorelease]];
		[undoManager setActionName:AILocalizedString(@"Clear", nil)];

		[self setString:@""];
		[self clearLinkAttribute];		
	}

	if ([[self delegate] respondsToSelector:@selector(textViewDidCancel:)]) {
		[[self delegate] textViewDidCancel:self];
	}
}


//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
//Set clears entered text on escape
- (void)setClearOnEscape:(BOOL)inBool
{
	clearOnEscape = inBool;
}

//Set to make home/end go to start/end of line instead of home/end of associated view
- (void)setHomeToStartOfLine:(BOOL)inBool
{
	homeToStartOfLine = inBool;
}

//Associate a view with this text view for key forwarding
- (void)setAssociatedView:(NSView *)inView
{
	if (inView != associatedView) {
		[associatedView release];
		associatedView = [inView retain];
	}
}
- (NSView *)associatedView{
	return associatedView;
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ((!object || (object == [chat account])) &&
		[group isEqualToString:GROUP_ACCOUNT_STATUS] &&
		(!key || [key isEqualToString:KEY_DISABLE_TYPING_NOTIFICATIONS])) {
		enableTypingNotifications = ![[[chat account] preferenceForKey:KEY_DISABLE_TYPING_NOTIFICATIONS
																 group:GROUP_ACCOUNT_STATUS] boolValue];
	}
	
	if (!object &&
		[group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE] &&
		(!key || [key isEqualToString:KEY_SPELL_CHECKING])) {
		[self setContinuousSpellCheckingEnabled:[[prefDict objectForKey:KEY_SPELL_CHECKING] boolValue]];
	}

	if ([NSApp isOnLeopardOrBetter]) {
		if (!object &&
			[group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE] &&
			(!key || [key isEqualToString:KEY_GRAMMAR_CHECKING])) {
			[self setGrammarCheckingEnabled:[[prefDict objectForKey:KEY_GRAMMAR_CHECKING] boolValue]];
		}
	}
	
	if ((object == [chat listObject]) &&
		[group isEqualToString:PREF_GROUP_CHARACTER_COUNTER]) {
		if (!key || [key isEqualToString:KEY_CHARACTER_COUNTER_ENABLED])
			[self setCharacterCounterVisible:[[prefDict objectForKey:KEY_CHARACTER_COUNTER_ENABLED] boolValue]];
		if (!key || [key isEqualToString:KEY_MAX_NUMBER_OF_CHARACTERS])
			[self setCharacterCounterMaximum:[[prefDict objectForKey:KEY_MAX_NUMBER_OF_CHARACTERS] intValue]];
	}
}

//Adium Text Entry -----------------------------------------------------------------------------------------------------
#pragma mark Adium Text Entry

/*!
 * @brief Toggle whether message sending is enabled based on a notification. The notification object is the AIChat of the appropriate message entry view
 */
- (void)toggleMessageSending:(NSNotification *)not
{
	//XXX - We really should query the AIChat about this, but AIChat's "can't send" is really designed for handling offline, not banned. Bringing up the offline messaging dialog when banned would make no sense.
	[self setSendingEnabled:[[[not userInfo] objectForKey:@"TypingEnabled"] boolValue]];
}

/*!
 * @brief Are we available for sending?
 */
- (BOOL)availableForSending
{
	return [self isSendingEnabled];
}

//Set our string, preserving the selected range
- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    int			length = [inAttributedString length];
    NSRange 	oldRange = [self selectedRange];

    //Change our string
    [[self textStorage] setAttributedString:inAttributedString];

    //Restore the old selected range
    if (oldRange.location < length) {
        if (oldRange.location + oldRange.length <= length) {
            [self setSelectedRange:oldRange];
        } else {
            [self setSelectedRange:NSMakeRange(oldRange.location, length - oldRange.location)];       
        }
    }

    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

//Set our string (plain text)
- (void)setString:(NSString *)string
{
    [super setString:string];

    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

//Set our typing format
- (void)setTypingAttributes:(NSDictionary *)attrs
{
	[super setTypingAttributes:attrs];

	[self setInsertionPointColor:[[attrs objectForKey:NSBackgroundColorAttributeName] contrastingColor]];
}

#pragma mark Pasting

- (BOOL)handlePasteAsRichText
{
	NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
	NSEnumerator *enumerator = [[generalPasteboard types] objectEnumerator];
	NSString	 *type;
	BOOL		 handledPaste = NO;
	
	//Types is ordered by the preference for handling of the data; enumerating it lets us allow the sending application's hints to be followed.
	while ((type = [enumerator nextObject]) && !handledPaste) {
		if ([type isEqualToString:NSRTFDPboardType]) {
			NSData *data = [generalPasteboard dataForType:NSRTFDPboardType];
			[self insertText:[self attributedStringWithAITextAttachmentExtensionsFromRTFDData:data]];
			handledPaste = YES;
			
		} else if ([PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY containsObject:type]) {
			//When we hit a type we should let the superclass handle, break without doing anything
			break;
			
		} else if ([FILES_AND_IMAGES_TYPES containsObject:type]) {
			[self addAttachmentsFromPasteboard:generalPasteboard];
			handledPaste = YES;
		}
		
	}
	
	return handledPaste;
}

//Paste as rich text without altering our typing attributes
- (void)pasteAsRichText:(id)sender
{
	NSDictionary	*attributes = [[self typingAttributes] copy];

	if (![self handlePasteAsRichText]) {
		[self paste:sender];
	}

	if (attributes) {
		[self setTypingAttributes:attributes];
	}

	[attributes release];
	
	[self scrollRangeToVisible:[self selectedRange]];
}

- (void)pasteAsPlainTextWithTraits:(id)sender
{
	NSDictionary	*attributes = [[self typingAttributes] copy];
	
	NSPasteboard	*generalPasteboard = [NSPasteboard generalPasteboard];
	NSString		*type;

	NSArray *supportedTypes =
		[NSArray arrayWithObjects:NSURLPboardType, NSRTFDPboardType, NSRTFPboardType, NSHTMLPboardType, NSStringPboardType, 
			NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType, nil];

	type = [[NSPasteboard generalPasteboard] availableTypeFromArray:supportedTypes];
	
	if ([type isEqualToString:NSRTFPboardType] ||
		[type isEqualToString:NSRTFDPboardType] ||
		[type isEqualToString:NSHTMLPboardType] ||
		[type isEqualToString:NSStringPboardType]) {
		NSData *data;
		
		@try {
			data = [generalPasteboard dataForType:type];
		} @catch (NSException *localException) {
			data = nil;
		}
		
		//Failed. Try again with the string type.
		if (!data && ![type isEqualToString:NSStringPboardType]) {
			if ([[[NSPasteboard generalPasteboard] types] containsObject:NSStringPboardType]) {
				type = NSStringPboardType;
				@try {
					data = [generalPasteboard dataForType:type];
				} @catch (NSException *localException) {
					data = nil;
				}
			}
		}
		
		if (!data) {
			//We still didn't get valid data... maybe super can handle it
			@try {
				[self paste:sender];
			} @catch (NSException *localException) {
				NSBeep();
				return;
			}
		}
		
		NSMutableAttributedString *attributedString;
		
		if ([type isEqualToString:NSStringPboardType]) {
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			attributedString = [[NSMutableAttributedString alloc] initWithString:string
																	  attributes:[self typingAttributes]];
			[string release];
			
		} else {
			@try {
				if ([type isEqualToString:NSRTFPboardType]) {
					attributedString = [[NSMutableAttributedString alloc] initWithRTF:data
																   documentAttributes:NULL];
				} else if ([type isEqualToString:NSRTFDPboardType]) {
					attributedString = [[NSMutableAttributedString alloc] initWithRTFD:data
																	documentAttributes:NULL];
				} else /* NSHTMLPboardType */ {
					attributedString = [[NSMutableAttributedString alloc] initWithHTML:data
																	documentAttributes:NULL];
				}
			} @catch (NSException *localException) {
				//Error while reading the RTF or HTML data, which can happen. Fall back on plain text
				if ([[[NSPasteboard generalPasteboard] types] containsObject:NSStringPboardType]) {
					data = [generalPasteboard dataForType:NSStringPboardType];
					NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					attributedString = [[NSMutableAttributedString alloc] initWithString:string
																			  attributes:[self typingAttributes]];
					[string release];
				} else {
					attributedString = nil;
				}
			}

			if (!attributedString) {
				NSBeep();
				return;
			}

			[attributedString convertForPasteWithTraitsUsingAttributes:[self typingAttributes]];
		}
		
		NSRange			selectedRange = [self selectedRange];
		NSTextStorage	*textStorage = [self textStorage];
		
		//Prepare the undo operation
		NSUndoManager	*undoManager = [self undoManager];
		[[undoManager prepareWithInvocationTarget:textStorage]
				replaceCharactersInRange:NSMakeRange(selectedRange.location, [attributedString length])
					withAttributedString:[textStorage attributedSubstringFromRange:selectedRange]];
		[undoManager setActionName:AILocalizedString(@"Paste", nil)];
		
		//Perform the paste
		[textStorage replaceCharactersInRange:selectedRange
						 withAttributedString:attributedString];
		// Align our text properly (only need to if the first character was changed)
		if (selectedRange.location == 0)
			[self setBaseWritingDirection:[[textStorage string] baseWritingDirection]];
		//Notify that we changed our text
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
															object:self];
		[attributedString release];

	} else if ([FILES_AND_IMAGES_TYPES containsObject:type] ||
			   [type isEqualToString:NSURLPboardType]) {
		if (![self handlePasteAsRichText]) {
			[self paste:sender];
		}

	} else {		
		//If we didn't handle it yet, let super try to deal with it
		[self paste:sender];
	}

	if (attributes) {
		[self setTypingAttributes:attributes];
	}

	[attributes release];	
	
	[self scrollRangeToVisible:[self selectedRange]];
}

#pragma mark Deletion

- (void)deleteBackward:(id)sender
{
	//Perform the delete
	[super deleteBackward:sender];
	
	//If we are now an empty string, and we still have a link active, clear the link
	if ([[self textStorage] length] == 0) {
		[self clearLinkAttribute];
	}
}

//Contact menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact menu
//Set and return the selected chat (to auto-configure the contact menu)
- (void)setChat:(AIChat *)inChat
{
    if (chat != inChat) {
        [chat release];
        chat = [inChat retain];
		
		//Observe preferences changes for typing enable/disable
		[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];

		//Grab our initial values for the state of the character counter, since registering as an observer only gives you global state
		[self setCharacterCounterMaximum:[[[chat listObject] preferenceForKey:KEY_MAX_NUMBER_OF_CHARACTERS group:PREF_GROUP_CHARACTER_COUNTER] intValue]];
		[self setCharacterCounterVisible:[[[chat listObject] preferenceForKey:KEY_CHARACTER_COUNTER_ENABLED group:PREF_GROUP_CHARACTER_COUNTER] boolValue]];

		//Observer preference changes for the character counter, just in case
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CHARACTER_COUNTER];
    }
}
- (AIChat *)chat{
    return chat;
}

//Return the selected list object (to auto-configure the contact menu)
- (AIListContact *)listObject
{
	return [chat listObject];
}

- (AIListContact *)preferredListObject
{
	return [chat preferredListObject];
}

//Auto Sizing ----------------------------------------------------------------------------------------------------------
#pragma mark Auto-sizing
//Returns our desired size
- (NSSize)desiredSize
{
    if (_desiredSizeCached.width == 0) {
        float 		textHeight;
        if ([[self textStorage] length] != 0) {
            //If there is text in this view, let the container tell us its height

			//Force glyph generation.  We must do this or usedRectForTextContainer might only return a rect for a
			//portion of our text.
            [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];            

            textHeight = [[self layoutManager] usedRectForTextContainer:[self textContainer]].size.height;
        } else {
            //Otherwise, we use the current typing attributes to guess what the height of a line should be
			textHeight = [NSAttributedString stringHeightForAttributes:[self typingAttributes]];
        }

		/* When we called glyphRangeForTextContainer, we may have triggered re-entry via
		 *		-[self setFrame:] --> -[self frameDidChange:] --> -[self _resetCacheAndPostSizeChanged]
		 * in which case the second entry through the loop (the future relative to our conversation in this comment) got the correct desired size.
		 * In the present, an *old* value is in textHeight.  We don't want to use that. Jumping gigawatts!
		 */
		if (_desiredSizeCached.width == 0) {
			_desiredSizeCached = NSMakeSize([self frame].size.width, textHeight + ENTRY_TEXTVIEW_PADDING);
		}
    }

    return _desiredSizeCached;
}

//Reset the desired size cache when our frame changes
- (void)frameDidChange:(NSNotification *)notification
{
	//resetCacheAndPostSizeChanged can get us right back to here, resulting in an infinite loop if we're not careful
	if (!resizing) {
		resizing = YES;
		[self _resetCacheAndPostSizeChanged];
		resizing = NO;
	}
}

//Reset the desired size cache and post a size changed notification.  Call after the text's dimensions change
- (void)_resetCacheAndPostSizeChanged
{
	//Reset the size cache
	_desiredSizeCached = NSMakeSize(0,0);

	//Post notification if size changed
	if (!NSEqualSizes([self desiredSize], lastPostedSize)) {
		lastPostedSize = [self desiredSize];
		[[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
	}
}

//Paging ---------------------------------------------------------------------------------------------------------------
#pragma mark Paging
//Page up or down in the message view
- (void)scrollPageUp:(id)sender
{
    if (associatedView && [associatedView respondsToSelector:@selector(pageUp:)]) {
		[associatedView pageUp:nil];
    } else {
		[super scrollPageUp:sender];
	}
}
- (void)scrollPageDown:(id)sender
{
    if (associatedView && [associatedView respondsToSelector:@selector(pageDown:)]) {
		[associatedView pageDown:nil];
    } else {
		[super scrollPageDown:sender];
	}
}


//History --------------------------------------------------------------------------------------------------------------
#pragma mark History
- (void)setHistoryEnabled:(BOOL)inHistoryEnabled
{
	historyEnabled = inHistoryEnabled;
}

//Move up through the history
- (void)historyUp
{
    if (currentHistoryLocation == 0) {
		//Store current message
        [historyArray replaceObjectAtIndex:0 withObject:[[[self textStorage] copy] autorelease]];
    }
	
    if (currentHistoryLocation < [historyArray count]-1) {
        //Move up
        currentHistoryLocation++;
		
        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
    }
}

//Move down through history
- (void)historyDown
{
    if (currentHistoryLocation > 0) {
        //Move down
        currentHistoryLocation--;
		
        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
	}
}

//Update history when content is sent
- (IBAction)sendContent:(id)sender
{
	NSAttributedString	*textStorage = [self textStorage];
	
	//Add to history if there is text being sent
	[historyArray insertObject:[[textStorage copy] autorelease] atIndex:1];
	if ([historyArray count] > MAX_HISTORY) {
		[historyArray removeLastObject];
	}

	currentHistoryLocation = 0; //Move back to bottom of history

	//Send the content
	[super sendContent:sender];
	
	//Clear the undo/redo stack as it makes no sense to carry between sends (the history is for that)
	[[self undoManager] removeAllActions];
}

//Populate the history with messages from the message history
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject *content = [[notification userInfo] objectForKey:@"AIContentObject"];

	if (([self chat] == [content chat]) && ([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]) && [content isOutgoing]) {
		//Populate the history with messages from us
		[historyArray insertObject:[content message] atIndex:1];
		if ([historyArray count] > MAX_HISTORY) {
			[historyArray removeLastObject];
		}
	}
}

//Push and Pop ---------------------------------------------------------------------------------------------------------
#pragma mark Push and Pop
//Enable/Disable push-pop
- (void)setPushPopEnabled:(BOOL)inBool
{
	pushPopEnabled = inBool;
}

//Push out of the message entry field
- (void)pushContent
{
	if ([[self textStorage] length] != 0 && pushPopEnabled) {
		[pushArray addObject:[[[self textStorage] copy] autorelease]];
		[self setString:@""];
		[self _setPushIndicatorVisible:YES];
	}
}

//Pop into the message entry field
- (void)popContent
{
    if ([pushArray count] && pushPopEnabled) {
        [self setAttributedString:[pushArray lastObject]];
        [self setSelectedRange:NSMakeRange([[self textStorage] length], 0)]; //selection to end
        [pushArray removeLastObject];
        if ([pushArray count] == 0) {
            [self _setPushIndicatorVisible:NO];
        }
    }
}

//Swap current content
- (void)swapContent
{
	if (pushPopEnabled) {
		NSAttributedString *tempMessage = [[[self textStorage] copy] autorelease];
				
		if ([pushArray count]) {
			[self popContent];
		} else {
			[self setString:@""];
		}
		
		if (tempMessage && [tempMessage length] != 0) {
			[pushArray addObject:tempMessage];
			[self _setPushIndicatorVisible:YES];
		}
	}
}

//Push indicator
- (void)_setPushIndicatorVisible:(BOOL)visible
{
	static NSImage	*pushIndicatorImage = nil;
	
	//
	if (!pushIndicatorImage) pushIndicatorImage = [[NSImage imageNamed:@"stackImage" forClass:[self class]] retain];

    if (visible && !pushIndicatorVisible) {
        pushIndicatorVisible = visible;
		
        //Push text over to make room for indicator
        NSSize size = [self frame].size;
        size.width -= ([pushIndicatorImage size].width);
        [self setFrameSize:size];
				
		// Make the indicator and set its action. It is a button with no border.
		pushIndicator = [[NSButton alloc] initWithFrame:
            NSMakeRect(0, 0, [pushIndicatorImage size].width, [pushIndicatorImage size].height)]; 
		[pushIndicator setButtonType:NSMomentaryPushButton];
        [pushIndicator setAutoresizingMask:(NSViewMinXMargin)];
        [pushIndicator setImage:pushIndicatorImage];
        [pushIndicator setImagePosition:NSImageOnly];
		[pushIndicator setBezelStyle:NSRegularSquareBezelStyle];
		[pushIndicator setBordered:NO];
        [[self superview] addSubview:pushIndicator];
		[pushIndicator setTarget:self];
		[pushIndicator setAction:@selector(popContent)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewFrameDidChangeNotification object:[self superview]];
		
        [self positionPushIndicator]; //Set the indicators initial position
		
    } else if (!visible && pushIndicatorVisible) {
        pushIndicatorVisible = visible;

        //Push text back
        NSSize size = [self frame].size;
        size.width += [pushIndicatorImage size].width;
        [self setFrameSize:size];

		//Unsubcribe, if necessary.
		if (!characterCounter) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
		}
		//Remove indicator
        [pushIndicator removeFromSuperview];
        [pushIndicator release]; pushIndicator = nil;
		
		[self positionPushIndicator];
    }
}

//Reposition the push indicator into lower right corner
- (void)positionPushIndicator
{
    NSRect visRect = [[self superview] bounds];
    NSRect indFrame = [pushIndicator frame];
	float counterPadding = characterCounter ? NSWidth([characterCounter frame]) : 0;
	[pushIndicator setFrameOrigin:NSMakePoint(NSMaxX(visRect) - NSWidth(indFrame) - INDICATOR_RIGHT_PADDING - counterPadding, 
											  NSMaxY(visRect) - NSHeight(indFrame) - INDICATOR_BOTTOM_PADDING)];
    [[self enclosingScrollView] setNeedsDisplay:YES];
}

#pragma mark Indicators Positioning

/**
 * @brief Dispatch for both indicators to observe bounds & frame changes of their superview
 *
 * Stupid that this is necessary, but you can only remove an entire object from a notification center's observer list,
 * not on a per-method basis.
 */
- (void)positionIndicators:(NSNotification *)notification
{
	if (pushIndicatorVisible)
		[self positionPushIndicator];
	if (characterCounter)
		[self positionCharacterCounter];
}

#pragma mark Character Counter

/**
 * @brief Makes the character counter for this view visible.
 */
- (void)setCharacterCounterVisible:(BOOL)visible
{
	if (visible && !characterCounter) {
		characterCounter = [[AITwitterCharacterCounterView alloc] initWithFrame:(NSRect){ NSZeroPoint, [AITwitterCharacterCounterView idealSize] }];
		[characterCounter setAutoresizingMask:(NSViewMinXMargin)];
#warning Hard-coded numbers are bad! 140 is the message budget on Twitter, but this should be a property, to accomodate other services that may have different budgets.
		[characterCounter setMaximumMessageSize:140U];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewFrameDidChangeNotification object:[self superview]];		

		[self updateCharacterCounter];
		[[self superview] addSubview:characterCounter];
		
	} else if (!visible && characterCounter) {	
		[characterCounter removeFromSuperview];
		
		// Make sure to resize this view back to the right size.
		NSSize size = [self frame].size;
        size.width += NSWidth([characterCounter frame]);
        [self setFrameSize:size];

		//Unsubscribe, if necessary.
		if (!pushIndicatorVisible) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
		}

		[characterCounter release];
		characterCounter = nil;
		
		// Reposition the push indicator, if necessary.
		if (pushIndicatorVisible)
			[self positionPushIndicator];
		
		[[self enclosingScrollView] setNeedsDisplay:YES];
	}
}

/**
 * @brief Set the number of characters the character counter should count down from.
 */
- (void)setCharacterCounterMaximum:(int)inMaxCharacters
{
	maxCharacters = inMaxCharacters;
}

/**
 * @brief Update the character counter and resize this view to make space if the counter's bounds change.
 */
- (void)updateCharacterCounter
{
	NSRect visRect = [[self superview] bounds];

	[characterCounter setCurrentMessageSize:[[self textStorage] length]];

	//Reposition the character counter.
	[self positionCharacterCounter];
	
	//Shift the text entry view over as necessary.
	float indent = 0;
	if (pushIndicatorVisible || characterCounter) {
		float pushIndicatorX = pushIndicator ? NSMinX([pushIndicator frame]) : NSMaxX([self bounds]);
		float characterCounterX = characterCounter ? NSMinX([characterCounter frame]) : NSMaxX([self bounds]);
		indent = NSWidth(visRect) - fminf(pushIndicatorX, characterCounterX);
	}
	[self setFrameSize:NSMakeSize(NSWidth(visRect) - indent, NSHeight([self frame]))];
	
	//Reposition the push indicator if necessary.
	if (pushIndicatorVisible)
		[self positionPushIndicator];
		
	[[self enclosingScrollView] setNeedsDisplay:YES];
}

/**
 * @brief Keeps the character counter in the bottom right corner.
 */
- (void)positionCharacterCounter
{
	NSRect visRect = [[self superview] bounds];
	NSRect counterRect = [characterCounter frame];
	
	//NSMaxY([self frame]) is necessary because visRect's height changes after you start typing. No idea why.
	[characterCounter setFrameOrigin:NSMakePoint(NSMaxX(visRect) - NSWidth(counterRect) - INDICATOR_RIGHT_PADDING,
												 NSMaxY([self frame]) - NSHeight(counterRect) - INDICATOR_BOTTOM_PADDING)];
	[[self enclosingScrollView] setNeedsDisplay:YES];
}

#pragma mark Contextual Menus

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu			*contextualMenu = nil;
	
	NSArray			*itemsArray = nil;
	NSEnumerator    *enumerator;
	NSMenuItem		*menuItem;
	BOOL			addedOurLinkItems = NO;

	if ((contextualMenu = [super menuForEvent:theEvent])) {
		contextualMenu = [[contextualMenu copy] autorelease];
		enumerator = [[contextualMenu itemArray] objectEnumerator];
		NSMenuItem	*editLinkItem = nil;
		while ((menuItem = [enumerator nextObject])) {
			if ([[menuItem title] rangeOfString:AILocalizedString(@"Edit Link", nil)].location != NSNotFound) {
				editLinkItem = menuItem;
				break;
			}
		}

		if (editLinkItem) {
			//There was an Edit Link item.  Remove it, and add out own link editing items in its place.
			int editIndex = [contextualMenu indexOfItem:editLinkItem];
			[contextualMenu removeItem:editLinkItem];
			
			NSMenu  *linkItemsMenu = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObject:
				[NSNumber numberWithInt:Context_TextView_LinkEditing]]
																								  forTextView:self];
			
			enumerator = [[linkItemsMenu itemArray] objectEnumerator];
			while ((menuItem = [enumerator nextObject])) {
				[contextualMenu insertItem:[[menuItem copy] autorelease] atIndex:editIndex++];
			}
			
			addedOurLinkItems = YES;
		}
	} else {
		contextualMenu = [[[NSMenu alloc] init] autorelease];
	}

	//Retrieve the items which should be added to the bottom of the default menu
	NSArray	*locationArray = (addedOurLinkItems ?
							  [NSArray arrayWithObject:[NSNumber numberWithInt:Context_TextView_Edit]] :
							  [NSArray arrayWithObjects:[NSNumber numberWithInt:Context_TextView_LinkEditing], 
								  [NSNumber numberWithInt:Context_TextView_Edit], nil]);
	NSMenu  *adiumMenu = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:locationArray
																						  forTextView:self];
	itemsArray = [adiumMenu itemArray];
	
	if ([itemsArray count] > 0) {
		[contextualMenu addItem:[NSMenuItem separatorItem]];
		int i = [(NSMenu *)contextualMenu numberOfItems];
		enumerator = [itemsArray objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			//We're going to be copying; call menu needs update now since it won't be called later.
			NSMenu	*submenu = [menuItem submenu];
			NSMenuItem	*menuItemCopy = [[menuItem copy] autorelease];
			if (submenu && [submenu respondsToSelector:@selector(delegate)]) {
				[[menuItemCopy submenu] setDelegate:[submenu delegate]];
			}

			[contextualMenu insertItem:menuItemCopy atIndex:i++];
		}
	}
	
    return contextualMenu;
}

#pragma mark Drag and drop

/*An NSTextView which has setImportsGraphics:YES as of 10.3 gets the following drag types by default:
"NSColor pasteboard type"
"NSFilenamesPboardType"
"Apple PDF pasteboard type"
"Apple PICT pasteboard type"
"NeXT Encapsulated PostScript v1.2 pasteboard type"
"NeXT TIFF v4.0 pasteboard type"
"CorePasteboardFlavorType 0x6D6F6F76"
"Apple HTML pasteboard type"
"NeXT RTFD pasteboard type"
"NeXT Rich Text Format v1.0 pasteboard type"
"NSStringPboardType"
"NSFilenamesPboardType"
*/
/*
- (NSArray *)acceptableDragTypes;
{
    NSMutableArray *dragTypes;
    
    dragTypes = [NSMutableArray arrayWithArray:[super acceptableDragTypes]];
    return dragTypes;
}
*/

//We don't need to prepare for the types we are handling in performDragOperation: below
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	NSString 		*type = [pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES];
	NSString		*superclassType = [pasteboard availableTypeFromArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	BOOL			allowDragOperation;

	if (type && !superclassType) {		
		// XXX - This shouldn't let you insert into a view for which the delegate says NO to some sort of check.
		allowDragOperation = YES;
	} else {
		allowDragOperation = [super prepareForDragOperation:sender];
	}
	
	return (allowDragOperation);
}

//No conclusion is needed for the types we are handling in performDragOperation: below
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	NSString 		*type = [pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES];
	NSString		*superclassType = [pasteboard availableTypeFromArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	
	
	
	if (!type || superclassType) {
		[super concludeDragOperation:sender];
	}
}

- (void)addAttachmentsFromPasteboard:(NSPasteboard *)pasteboard
{
	if ([pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {
		//The pasteboard points to one or more files on disc.  Use them directly.
		NSArray			*files = [pasteboard propertyListForType:NSFilenamesPboardType];
		NSEnumerator	*enumerator = [files objectEnumerator];
		NSString		*path;
		while ((path = [enumerator nextObject])) {
			[self addAttachmentOfPath:path];
		}
		
	} else {
		//The pasteboard contains image data with no corresponding file.
		NSImage	*image = [[NSImage alloc] initWithPasteboard:pasteboard];
		[self addAttachmentOfImage:image];
		[image release];			
	}	
}

//The textView's method of inserting into the view is insufficient; we can do better.
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL			success = NO;

	NSString *myType = [[pasteboard types] firstObjectCommonWithArray:FILES_AND_IMAGES_TYPES];
	NSString *superclassType = [[pasteboard types] firstObjectCommonWithArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	
	if (myType &&
		(!superclassType || ([[pasteboard types] indexOfObject:myType] < [[pasteboard types] indexOfObject:superclassType]))) {
		[self addAttachmentsFromPasteboard:pasteboard];
		
		success = YES;		
	} else {
		success = [super performDragOperation:sender];
		
	}

	return success;
}

#pragma mark Spell Checking

/*!
 * @brief Spell checking was toggled
 *
 * Set our preference, as we toggle spell checking globally when it is changed locally
 */
- (void)toggleContinuousSpellChecking:(id)sender
{
	[super toggleContinuousSpellChecking:sender];

	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[self isContinuousSpellCheckingEnabled]]
										 forKey:KEY_SPELL_CHECKING
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Grammar checking was toggled
 *
 * Set our preference, as we toggle grammar checking globally when it is changed locally
 */
- (void)toggleGrammarChecking:(id)sender
{
	[super toggleGrammarChecking:sender];
	
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[self isGrammarCheckingEnabled]]
										 forKey:KEY_GRAMMAR_CHECKING
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}


#pragma mark Writing Direction
- (void)toggleBaseWritingDirection:(id)sender
{
	if ([self baseWritingDirection] == NSWritingDirectionRightToLeft) {
		[self setBaseWritingDirection:NSWritingDirectionLeftToRight];
	} else {
		[self setBaseWritingDirection:NSWritingDirectionRightToLeft];			
	}
	
	//Apply it immediately
	[self setBaseWritingDirection:[self baseWritingDirection]
							range:NSMakeRange(0, [[self textStorage] length])];
}

#pragma mark Attachments
/*!
 * @brief Add an attachment of the file at inPath at the current insertion point
 *
 * @param inPath The full path, whose contents will not be loaded into memory at this time
 */
- (void)addAttachmentOfPath:(NSString *)inPath
{
	if ([[inPath pathExtension] caseInsensitiveCompare:@"textClipping"] == NSOrderedSame) {
		inPath = [inPath stringByAppendingString:@"/..namedfork/rsrc"];

		NSData *data = [NSData dataWithContentsOfFile:inPath];
		if (data) {
			data = [data subdataWithRange:NSMakeRange(260, [data length] - 260)];
			
			NSAttributedString *clipping = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:nil] autorelease];
			if (clipping) {
				NSDictionary	*attributes = [[self typingAttributes] copy];
				
				[self insertText:clipping];

				if (attributes) {
					[self setTypingAttributes:attributes];
				}
				
				[attributes release];
			}
		}

	} else {
		AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
		[attachment setPath:inPath];
		[attachment setString:[inPath lastPathComponent]];
		[attachment setShouldSaveImageForLogging:YES];
		
		//Insert an attributed string into the text at the current insertion point
		[self insertText:[self attributedStringWithTextAttachmentExtension:attachment]];
		
		[attachment release];
	}
}

/*!
 * @brief Add an attachment of inImage at the current insertion point
 */
- (void)addAttachmentOfImage:(NSImage *)inImage
{
	AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
	
	[attachment setImage:inImage];
	[attachment setShouldSaveImageForLogging:YES];
	
	//Insert an attributed string into the text at the current insertion point
	[self insertText:[self attributedStringWithTextAttachmentExtension:attachment]];
	
	[attachment release];
}

/*!
 * @brief Generate an NSAttributedString which contains attachment and displays it using attachment's iconImage
 */
- (NSAttributedString *)attributedStringWithTextAttachmentExtension:(AITextAttachmentExtension *)attachment
{
	NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:[attachment iconImage]];
	
	[attachment setHasAlternate:NO];
	[attachment setAttachmentCell:cell];
	[cell release];
	
	return [NSAttributedString attributedStringWithAttachment:attachment];
}

/*!
 * @brief Given RTFD data, return an NSAttributedString whose attachments are all AITextAttachmentExtension objects
 */
- (NSAttributedString *)attributedStringWithAITextAttachmentExtensionsFromRTFDData:(NSData *)data
{
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithRTFD:data
																				documentAttributes:NULL] autorelease];
	if ([attributedString length] && [attributedString containsAttachments]) {
		int							currentLocation = 0;
		NSRange						attachmentRange;
		
		NSString					*attachmentCharacterString = [NSString stringWithFormat:@"%C",NSAttachmentCharacter];
		
		//Find each attachment
		attachmentRange = [[attributedString string] rangeOfString:attachmentCharacterString
														   options:0 
															 range:NSMakeRange(currentLocation,
																			   [attributedString length] - currentLocation)];
		while (attachmentRange.length != 0) {
			//Found an attachment in at attachmentRange.location
			NSTextAttachment	*attachment = [attributedString attribute:NSAttachmentAttributeName
																  atIndex:attachmentRange.location
														   effectiveRange:nil];

			//If it's not already an AITextAttachmentExtension, make it into one
			if (![attachment isKindOfClass:[AITextAttachmentExtension class]]) {
				NSAttributedString	*replacement;
				NSFileWrapper		*fileWrapper = [attachment fileWrapper];
				NSString			*destinationPath;
				NSString			*preferredName = [fileWrapper preferredFilename];
				
				//Get a unique folder within our temporary directory
				destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
				[[NSFileManager defaultManager] createDirectoriesForPath:destinationPath];
				destinationPath = [destinationPath stringByAppendingPathComponent:preferredName];
				
				//Write the file out to it
				[fileWrapper writeToFile:destinationPath
							  atomically:NO
						 updateFilenames:NO];
				
				//Now create an AITextAttachmentExtension pointing to it
				AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
				[attachment setPath:destinationPath];
				[attachment setString:preferredName];
				[attachment setShouldSaveImageForLogging:YES];

				//Insert an attributed string into the text at the current insertion point
				replacement = [self attributedStringWithTextAttachmentExtension:attachment];
				[attachment release];
				
				//Remove the NSTextAttachment, replacing it the AITextAttachmentExtension
				[attributedString replaceCharactersInRange:attachmentRange
									  withAttributedString:replacement];
				
				attachmentRange.length = [replacement length];					
			} 
			
			currentLocation = attachmentRange.location + attachmentRange.length;
			
			
			//Find the next attachment
			attachmentRange = [[attributedString string] rangeOfString:attachmentCharacterString
															   options:0
																 range:NSMakeRange(currentLocation,
																				   [attributedString length] - currentLocation)];
		}
	}

	return attributedString;
}

- (void)changeDocumentBackgroundColor:(id)sender
{
	NSColor	*backgroundColor = [sender color];
	NSRange	selectedRange = [self selectedRange];

	[[self textStorage] addAttribute:NSBackgroundColorAttributeName
							   value:backgroundColor
							   range:selectedRange];
	[[self textStorage] addAttribute:AIBodyColorAttributeName
							   value:backgroundColor
							   range:selectedRange];

	NSMutableDictionary *typingAttributes = [[self typingAttributes] mutableCopy];
	[typingAttributes setObject:backgroundColor forKey:AIBodyColorAttributeName];
	[typingAttributes setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	[self setTypingAttributes:typingAttributes];
	[typingAttributes release];	

	[[self textStorage] edited:NSTextStorageEditedAttributes
						 range:selectedRange
				changeInLength:0];
}

- (void)insertText:(id)aString
{
	[super insertText:aString];
	// Auto set the writing direction based on our content
	[self setBaseWritingDirection:[[[self textStorage] string] baseWritingDirection]];
}

@end

@implementation NSMutableAttributedString (AIMessageEntryTextViewAdditions)
- (void)convertForPasteWithTraitsUsingAttributes:(NSDictionary *)typingAttributes;
{
	NSRange fullRange = NSMakeRange(0, [self length]);

	//Remove non-trait attributes
	if ([typingAttributes objectForKey:NSBackgroundColorAttributeName]) {
		[self addAttribute:NSBackgroundColorAttributeName
					 value:[typingAttributes objectForKey:NSBackgroundColorAttributeName]
					 range:fullRange];

	} else {
		[self removeAttribute:NSBackgroundColorAttributeName range:fullRange];
	}

	if ([typingAttributes objectForKey:NSForegroundColorAttributeName]) {
		[self addAttribute:NSForegroundColorAttributeName
					 value:[typingAttributes objectForKey:NSForegroundColorAttributeName]
					 range:fullRange];
		
	} else {
		[self removeAttribute:NSForegroundColorAttributeName range:fullRange];
	}

	if ([typingAttributes objectForKey:NSParagraphStyleAttributeName]) {
		[self addAttribute:NSParagraphStyleAttributeName
					 value:[typingAttributes objectForKey:NSParagraphStyleAttributeName]
					 range:fullRange];
		
	} else {
		[self removeAttribute:NSParagraphStyleAttributeName range:fullRange];
	}

	[self removeAttribute:NSBaselineOffsetAttributeName range:fullRange];
	[self removeAttribute:NSCursorAttributeName range:fullRange];
	[self removeAttribute:NSExpansionAttributeName range:fullRange];
	[self removeAttribute:NSKernAttributeName range:fullRange];
	[self removeAttribute:NSLigatureAttributeName range:fullRange];
	[self removeAttribute:NSObliquenessAttributeName range:fullRange];
	[self removeAttribute:NSShadowAttributeName range:fullRange];
	[self removeAttribute:NSStrokeWidthAttributeName range:fullRange];
	
	NSRange			searchRange = NSMakeRange(0, fullRange.length);
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];
	NSFont			*myFont = [typingAttributes objectForKey:NSFontAttributeName];

	while (searchRange.location < fullRange.length) {
		NSFont *font;
		NSRange effectiveRange;
		font = [self attribute:NSFontAttributeName 
					   atIndex:searchRange.location
		 longestEffectiveRange:&effectiveRange
					   inRange:searchRange];

		if (font) {
			NSFontTraitMask thisFontTraits = [fontManager traitsOfFont:font];
			NSFontTraitMask	traits = 0;
			
			if (thisFontTraits & NSBoldFontMask) {
				traits |= NSBoldFontMask;
			} else {
				traits |= NSUnboldFontMask;				
			}

			if (thisFontTraits & NSItalicFontMask) {
				traits |= NSItalicFontMask;
			} else {
				traits |= NSUnitalicFontMask;
			}
			
			font = [fontManager fontWithFamily:[myFont familyName]
										traits:traits
										weight:[fontManager weightOfFont:myFont]
										  size:[myFont pointSize]];
			 
			if (font) {
				[self addAttribute:NSFontAttributeName
							 value:font
							 range:effectiveRange];
			}
		}

		searchRange.location = effectiveRange.location + effectiveRange.length;
		searchRange.length = fullRange.length - searchRange.location;
	}

	//Replace attachments with nothing! Absolutely nothing!
	[self convertAttachmentsToStringsUsingPlaceholder:@""];
}




@end
