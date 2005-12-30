//
//  AITextViewAdditions.h
//  Adium
//
//  Created by Nicholas Peshek on Mon Sep 10 2005.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIColorAdditions.h"
#import "AITextViewAdditions.h"
#import "AITextAttributes.h"

@implementation NSTextView (AITextViewAdditions)

- (void)changeDocumentBackgroundColor:(id)sender
{
	NSColor		*newColor = [sender color];
	BOOL		isDark = [newColor colorIsDark];
	NSRange		selectedText = [self selectedRange];
	
	if (selectedText.length > 0) {
		[[self textStorage] addAttribute:NSBackgroundColorAttributeName value:newColor range:[self selectedRange]];
	} else {
		[self setBackgroundColor:newColor];
		[[self textStorage] addAttribute:AIBodyColorAttributeName value:newColor range:NSMakeRange(0, [[[self textStorage] string] length])];
		
		if (isDark) {
			[self setInsertionPointColor:[NSColor whiteColor]];
		} else {
			[self setInsertionPointColor:[NSColor blackColor]];
		}
	}

	if (selectedText.length > 0) {
		[self setSelectedRange:selectedText];
	}
	
	[self didChangeText];
}
@end