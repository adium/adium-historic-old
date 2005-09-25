//
//  AITextViewAdditions.h
//  Adium
//
//  Created by Nicholas Peshek on Mon Sep 10 2005.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AITextViewAdditions.h"
#import "AITextAttributes.h"

@implementation NSTextView (AITextViewAdditions)

- (void)changeDocumentBackgroundColor:(id)sender
{
	NSColor						*newColor = [sender color];
	NSMutableAttributedString	*attrStorageString = [[[self textStorage] mutableCopy] autorelease];
	NSRange						selectedText = [self selectedRange];
	
	if (selectedText.length > 0) {
		[attrStorageString addAttribute:NSBackgroundColorAttributeName value:newColor range:[self selectedRange]];
	} else {
		[self setBackgroundColor:newColor];
		[attrStorageString addAttribute:AIBodyColorAttributeName value:newColor range:NSMakeRange(0, [[attrStorageString string] length])];;			
	}
	
	[[self textStorage] setAttributedString:attrStorageString];
	if(selectedText.length > 0)
	{
		[self setSelectedRange:selectedText];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}
@end