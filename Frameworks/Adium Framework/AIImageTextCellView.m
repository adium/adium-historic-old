//
//  AIImageTextCellView.m
//  Adium
//
//  Created by Evan Schoenberg on 12/22/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "AIImageTextCellView.h"

@interface AIImageTextCellView (PRIVATE)
- (void)_initImageTextView;
@end

@implementation AIImageTextCellView

-(id)initWithFrame:(NSRect)inFrame
{
	if(self = [super initWithFrame:inFrame]){
		[self _initImageTextView];
	}
	
	return(self);
}

- (id)initWithCoder:(NSCoder *)encoder
{
	if(self = [super initWithCoder:encoder]){
		[self _initImageTextView];		
	}
	
	return(self);
}

- (void)_initImageTextView
{
	cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:12]];
	[cell setIgnoresFocus:YES];
}

- (void)dealloc
{
	[cell release]; cell = nil;
	[super dealloc];
}

//NSCell expects to draw into a flipped view
- (BOOL)isFlipped
{
	return(YES);
}

//Drawing
- (void)drawRect:(NSRect)inRect
{
	NSSize	cellSize = [cell cellSizeForBounds:inRect];
	
	if(cellSize.width < inRect.size.width){
		int difference = (inRect.size.width - cellSize.width)/2;
		inRect.size.width -= difference;
		inRect.origin.x += difference;
	}
	
	if(cellSize.height < inRect.size.height){
		int difference = (inRect.size.height - cellSize.height)/2;
		inRect.size.height -= difference;
		inRect.origin.y += difference;		
	}

	[cell drawInteriorWithFrame:inRect inView:self];
}

//Cell setting methods
- (void)setStringValue:(NSString *)inString
{
	[cell setStringValue:inString];
}

- (void)setImage:(NSImage *)inImage
{
	[cell setImage:inImage];
}

- (void)setSubString:(NSString *)inSubString
{
	[cell setSubString:inSubString];
}

@end
