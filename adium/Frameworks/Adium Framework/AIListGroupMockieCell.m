//
//  AIListGroupMockieCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//

#import "AIListGroupMockieCell.h"
#import "AIListOutlineView.h"

@interface AIListGroupMockieCell (PRIVATE)
- (NSImage *)cachedGroupGradient:(NSSize)inSize;
- (NSImage *)cachedExpandedGroupGradient:(NSSize)inSize;
@end

@implementation AIListGroupMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//
- (void)dealloc
{
	[_groupGradient release];
	[_groupExpandedGradient release];
	
	[super dealloc];
}

//Draw a gradient behind our group
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSImage			*image;
	
	if([controlView isItemExpanded:listObject]){
		image = [self cachedGroupGradient:rect.size];
	}else{
		image = [self cachedExpandedGroupGradient:rect.size];
	}
	
	[image drawInRect:rect
			 fromRect:NSMakeRect(0,0,rect.size.width,rect.size.height)
			operation:NSCompositeSourceOver
			 fraction:1.0];
}

- (NSImage *)cachedGroupGradient:(NSSize)inSize
{
	NSRect	rect;
	
	if(!_groupGradient || !NSEqualSizes(inSize,_groupGradientSize)){
		[_groupGradient release];
		NSLog(@"rendering gradient");
		rect = NSMakeRect(0,0,inSize.width,inSize.height);
		
		_groupGradient = [[NSImage alloc] initWithSize:inSize];
		_groupGradientSize = inSize;

		[_groupGradient lockFocus];
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS]];
		[_groupGradient unlockFocus];
	}
	
	return(_groupGradient);
}
- (NSImage *)cachedExpandedGroupGradient:(NSSize)inSize
{
	NSRect	rect;
	
	if(!_groupExpandedGradient || !NSEqualSizes(inSize,_groupExpandedGradientSize)){
		[_groupExpandedGradient release];
		NSLog(@"rendering gradient");
		rect = NSMakeRect(0,0,inSize.width,inSize.height);
		
		_groupExpandedGradient = [[NSImage alloc] initWithSize:inSize];
		_groupExpandedGradientSize = inSize;
		
		[_groupExpandedGradient lockFocus];
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS]];
		[_groupExpandedGradient unlockFocus];
	}
	
	return(_groupExpandedGradient);
}


@end
