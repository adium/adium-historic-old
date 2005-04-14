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
	[plcaeholder release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (([[self string] isEqualToString:@""]) && 
		([[self window] firstResponder] != self)){
		NSSize	size = [self frame].size;
		
		[placeholder drawInRect:NSMakeRect(PLACEHOLDER_SPACING, 
										   PLACEHOLDER_SPACING, 
										   size.width - (PLACEHOLDER_SPACING*2),
										   size.height - (PLACEHOLDER_SPACING*2))];
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
