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

#import "AIObject.h"
#import "AIChat.h"
#import "AIAccount.h"
#import "AIMenuController.h"
#import "AIMessageEntryTextView.h"
#import "AIPreferenceController.h"
#import "ESFileWrapperExtension.h"
#import "AITextAttachmentExtension.h"

#import "AIContentController.h"
#import "AIInterfaceController.h"

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>

#define MAX_HISTORY					25		//Number of messages to remember in history
#define ENTRY_TEXTVIEW_PADDING		6		//Padding for auto-sizing

#define KEY_DISABLE_TYPING_NOTIFICATIONS		@"Disable Typing Notifications"

#define KEY_SPELL_CHECKING						@"Spell Checking Enabled"
#define	PREF_GROUP_DUAL_WINDOW_INTERFACE		@"Dual Window Interface"

#define FILES_AND_IMAGES_TYPES [NSArray arrayWithObjects: \
	NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType, nil]

#define PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY [NSArray arrayWithObjects: \
	NSRTFPboardType, NSStringPboardType, nil]

@interface AIMessageEntryTextView (PRIVATE)
- (void)_setPushIndicatorVisible:(BOOL)visible;
- (void)_positionIndicator:(NSNotification *)notification;
- (void)_resetCacheAndPostSizeChanged;

- (NSAttributedString *)attributedStringWithAITextAttachmentExtensionsFromRTFDData:(NSData *)data;
- (NSAttributedString *)attributedStringWithTextAttachmentExtension:(AITextAttachmentExtension *)attachment;
- (void)addAttachmentOfPath:(NSString *)inPath;
- (void)addAttachmentOfImage:(NSImage *)inImage;
- (void)addAttachmentsFromPasteboard:(NSPasteboard *)pasteboard;
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
	indicator = nil;
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
													modifierFlags:nil
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

		} else if ([charactersIgnoringModifiers isEqualToString:@"\r"] == YES || inChar == NSEnterCharacter) {
			if (flags & NSShiftKeyMask) {
				[self insertText:@"\n"];
			} else {
				[super keyDown:inEvent];
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

    //Reset cache and resize
	[self _resetCacheAndPostSizeChanged];
}

//10.3+ only, called when the user presses escape - we'll clear our text view in response
- (void)cancelOperation:(id)sender
{
	if (clearOnEscape) {
		NSUndoManager	*undoManager = [self undoManager];
		[undoManager registerUndoWithTarget:self
								   selector:@selector(setAttributedString:)
									 object:[[[self textStorage] copy] autorelease]];
		[undoManager setActionName:AILocalizedString(@"Clear", nil)];

		[self setString:@""];
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
}

//Adium Text Entry -----------------------------------------------------------------------------------------------------
#pragma mark Adium Text Entry

/*
 * @brief Toggle whether message sending is enabled based on a notification. The notification object is the AIChat of the appropriate message entry view
 */
- (void)toggleMessageSending:(NSNotification *)not
{
	//XXX - We really should query the AIChat about this, but AIChat's "can't send" is really designed for handling offline, not banned. Bringing up the offline messaging dialog when banned would make no sense.
	[self setSendingEnabled:[[[not userInfo] objectForKey:@"TypingEnabled"] boolValue]];
}

/*
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
	NSColor	*backgroundColor;
	[super setTypingAttributes:attrs];

	//Correctly set our background color
	if ((backgroundColor = [attrs objectForKey:AIBodyColorAttributeName])) {
		[self setBackgroundColor:backgroundColor];
	} else {
		static NSColor	*cachedWhiteColor = nil;

		//Create cachedWhiteColor first time we're called; we'll need it later, repeatedly
		if (!cachedWhiteColor) cachedWhiteColor = [[NSColor whiteColor] retain];

		[self setBackgroundColor:cachedWhiteColor];
	}
	
	[self setInsertionPointColor:[backgroundColor contrastingColor]];
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
		NSData *data = [generalPasteboard dataForType:type];
		NSMutableAttributedString *attributedString;
		
		if ([type isEqualToString:NSStringPboardType]) {
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			attributedString = [[NSMutableAttributedString alloc] initWithString:string
																	  attributes:[self typingAttributes]];
			[string release];
			
		} else {
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
		//Notify that we changed our text
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
															object:self];
		[attributedString release];

	} else if ([FILES_AND_IMAGES_TYPES containsObject:type]) {
		if (![self handlePasteAsRichText]) {
			[self paste:sender];
		}
		
	} else if ([type isEqualToString:NSURLPboardType]) {
		//Paste a URL directly
		[self paste:sender];

	} else {		
		//If we didn't handle it yet, let super try to deal with it
		[self paste:sender];
	}

	if (attributes) {
		[self setTypingAttributes:attributes];
	}

	[attributes release];	
}

#pragma mark Deletion

- (void)deleteBackward:(id)sender
{
	//Perform the delete
	[super deleteBackward:sender];
	
	//If we are now an empty string, and we still have a link active, clear the link
	if ([[self textStorage] length] == 0) {
		NSDictionary *typingAttributes = [self typingAttributes];
		if ([typingAttributes objectForKey:NSLinkAttributeName]) {
			
			NSMutableDictionary *newTypingAttributes = [typingAttributes mutableCopy];
			
			[newTypingAttributes removeObjectForKey:NSLinkAttributeName];
			[self setTypingAttributes:newTypingAttributes];
			
			[newTypingAttributes release];
		}
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

        _desiredSizeCached = NSMakeSize([self frame].size.width, textHeight + ENTRY_TEXTVIEW_PADDING);
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
        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
        lastPostedSize = [self desiredSize];
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
        size.width -= ([pushIndicatorImage size].width + 2);
        [self setFrameSize:size];
		
		// Make the indicator and set its action. It is a button with no border.
		indicator = [[NSButton alloc] initWithFrame:
            NSMakeRect(0, 0, [pushIndicatorImage size].width, [pushIndicatorImage size].height)]; 
		[indicator setButtonType:NSMomentaryPushButton];
        [indicator setAutoresizingMask:(NSViewMinXMargin)];
        [indicator setImage:pushIndicatorImage];
        [indicator setImagePosition:NSImageOnly];
		[indicator setBezelStyle:NSRegularSquareBezelStyle];
		[indicator setBordered:NO];
        [[self superview] addSubview:indicator];
		[indicator setTarget:self];
		[indicator setAction:@selector(popContent)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_positionIndicator:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_positionIndicator:) name:NSViewFrameDidChangeNotification object:[self superview]];
		
        [self _positionIndicator:nil]; //Set the indicators initial position
		
    } else if (!visible && pushIndicatorVisible) {
        pushIndicatorVisible = visible;
		
        //Push text back
        NSSize size = [self frame].size;
        size.width += [pushIndicatorImage size].width;
        [self setFrameSize:size];
		
        //Remove indicator
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
        [indicator removeFromSuperview];
        [indicator release]; indicator = nil;
    }
}

//Reposition indicator into lower right corner
- (void)_positionIndicator:(NSNotification *)notification
{
    NSRect visRect = [[self enclosingScrollView] documentVisibleRect];
    NSRect indFrame = [indicator frame];
    
    [indicator setFrameOrigin:NSMakePoint(NSMaxX(visRect) - indFrame.size.width - 2, NSMaxY(visRect) - indFrame.size.height - 2)];
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
			if (submenu &&
			   [submenu respondsToSelector:@selector(delegate)] &&
			   [[submenu delegate] respondsToSelector:@selector(menuNeedsUpdate:)]) {
				[[submenu delegate] menuNeedsUpdate:submenu];
			}

			[contextualMenu insertItem:[[menuItem copy] autorelease] atIndex:i++];
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
	NSString 		*type = [pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES];
	NSString		*superclassType = [pasteboard availableTypeFromArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];

	BOOL	success = NO;
	if (type && !superclassType) {
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

#pragma mark Attachments
/*
 * @brief Add an attachment of the file at inPath at the current insertion point
 *
 * @param inPath The full path, whose contents will not be loaded into memory at this time
 */
- (void)addAttachmentOfPath:(NSString *)inPath
{
	AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
	[attachment setPath:inPath];
	[attachment setString:[inPath lastPathComponent]];
	
	//Insert an attributed string into the text at the current insertion point
	[self insertText:[self attributedStringWithTextAttachmentExtension:attachment]];
	
	[attachment release];
}

/*
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

/*
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

/*
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

@end

@implementation NSMutableAttributedString (AIMessageEntryTextViewAdditions)
- (void)convertForPasteWithTraitsUsingAttributes:(NSDictionary *)typingAttributes;
{
	NSRange fullRange = NSMakeRange(0, [self length]);

	//Remove non-trait attributes
	[self removeAttribute:NSBackgroundColorAttributeName range:fullRange];
	[self removeAttribute:NSBaselineOffsetAttributeName range:fullRange];
	[self removeAttribute:NSCursorAttributeName range:fullRange];
	[self removeAttribute:NSExpansionAttributeName range:fullRange];
	[self removeAttribute:NSForegroundColorAttributeName range:fullRange];
	[self removeAttribute:NSKernAttributeName range:fullRange];
	[self removeAttribute:NSLigatureAttributeName range:fullRange];
	[self removeAttribute:NSObliquenessAttributeName range:fullRange];
	[self removeAttribute:NSParagraphStyleAttributeName range:fullRange];
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
