//
//  AIListGroupGradientCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//

#import "AIListGroupGradientCell.h"

@interface AIListGroupGradientCell (PRIVATE)
- (NSImage *)cachedGradient:(NSSize)inSize;
@end

@implementation AIListGroupGradientCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

- (void)dealloc
{
	[_gradient release];
	
	[super dealloc];
}

//
- (void)setShadowColor:(NSColor *)inColor
{
	if(inColor != shadowColor){
		[shadowColor release];
		shadowColor = [inColor retain];
	}
}
- (NSColor *)shadowColor{
	return(shadowColor);
}

//Reset gradient cache
- (void)flushGradientCache
{
	[_gradient release]; _gradient = nil;
}

//
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if(inBackgroundColor != backgroundColor){
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	if(inGradientColor != gradientColor){
		[gradientColor release];
		gradientColor = [inGradientColor retain];
	}
	
	//Reset gradient cache
	[self flushGradientCache];
}

//Draw a gradient behind our group
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	[[self cachedGradient:rect.size] drawInRect:rect
									   fromRect:NSMakeRect(0,0,rect.size.width,rect.size.height)
									  operation:NSCompositeCopy
									   fraction:1.0];
}

- (NSImage *)cachedGradient:(NSSize)inSize
{
	if(!_gradient || !NSEqualSizes(inSize,_gradientSize)){
		[_gradient release];
		NSLog(@"rendering gradient");
		_gradient = [[NSImage alloc] initWithSize:inSize];
		_gradientSize = inSize;
		
		[_gradient lockFocus];
		[[self backgroundGradient] drawInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_gradient unlockFocus];
	}
	
	return(_gradient);
}

//Gradient
- (AIGradient *)backgroundGradient
{
	return([AIGradient gradientWithFirstColor:backgroundColor
								  secondColor:gradientColor
									direction:AIVertical]);
}

//Shadow our text to make it prettier
- (NSDictionary *)additionalLabelAttributes
{
	if([NSApp isOnPantherOrBetter]){
		NSShadow	*shadow = [[[NSShadow alloc] init] autorelease];
		
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:shadowColor];
		
		return([NSDictionary dictionaryWithObject:shadow forKey:NSShadowAttributeName]);
	}else{
		return(nil);
	}
}

@end
