//
//  ESTextViewWithPlaceholder.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.
//

#import "ESTextViewWithPlaceholder.h"

#define PLACEHOLDER_SPACING		2

@implementation ESTextViewWithPlaceholder

//Current implementation suggested by Philippe Mougin on the cocoadev mailing list

- (void)setPlaceholder:(NSString *)inPlaceholder
{
    NSDictionary *attributes;
	
	[placeholder release];

	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, nil];
    placeholder = [[NSAttributedString alloc] initWithString:inPlaceholder
												  attributes:attributes];
	
	[self setNeedsDisplay:YES];
}

- (NSString *)placeholder
{
    return [placeholder string];
}

- (void)dealloc
{
	[placeholder release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (([[self string] isEqualToString:@""]) && 
		([[self window] firstResponder] != self)) {
		NSSize	size = [self frame].size;
		NSSize textContainerInset = [self textContainerInset];
		
		[placeholder drawInRect:NSMakeRect(textContainerInset.width, 
										   textContainerInset.height, 
										   size.width - (textContainerInset.width * 2),
										   size.height - (textContainerInset.height * 2))];
	}
}

- (BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];

	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	
	return [super resignFirstResponder];
}
@end
