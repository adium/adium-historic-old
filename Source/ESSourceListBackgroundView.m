//
//  ESSourceListBackgroundView.m
//  Adium
//
//  Created by Evan Schoenberg on 6/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ESSourceListBackgroundView.h"


@implementation ESSourceListBackgroundView

- (void)_initSourceListBackgroundView
{
	[self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initSourceListBackgroundView];
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

static void linearGradientBackgroundShadingValues(void *info, const float *in, float *out);
static void linearGradientBackgroundShadingValues(void *info, const float *in, float *out){
	float *colors = (float *)info;
	
	register float a = in[0];
	register float a_coeff = 1.0f - a;
	
	out[0] = a_coeff * colors[4] + a * colors[0];
	out[1] = a_coeff * colors[5] + a * colors[1];
	out[2] = a_coeff * colors[6] + a * colors[2];
	out[3] = a_coeff * colors[7] + a * colors[3];
}

-(void)drawControlBackgroundInRect:(NSRect)aRect active:(BOOL)isActive{
	CGPoint					startPoint, endPoint;
	CGFunctionRef			function;
	CGShadingRef			shading;
	CGColorSpaceRef			colorspace;
	
	CGContextRef			context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGRect					bounds = CGRectMake( aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height );
	
	CGContextAddRect( context, bounds );
	
	CGContextSaveGState( context );
	CGContextClip( context );
	
	colorspace = CGColorSpaceCreateDeviceRGB();
	
	startPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
	endPoint = CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds));
	
	static float colors[8];
	
	if( isActive ){
		[[[NSColor controlShadowColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]
		getRed:&colors[0] green: &colors[1] blue: &colors[2] alpha: &colors[3]
			];
		[[[NSColor controlHighlightColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
			getRed:&colors[4] green: &colors[5] blue: &colors[6] alpha: &colors[7]
			];
	}else{
		[[[NSColor headerColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]
		getRed:&colors[0] green: &colors[1] blue: &colors[2] alpha: &colors[3]
			];
		[[[NSColor controlLightHighlightColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
			getRed:&colors[4] green: &colors[5] blue: &colors[6] alpha: &colors[7]
			];
	}
	
	static const CGFunctionCallbacks callbacks = { 0U, linearGradientBackgroundShadingValues, NULL };
	function = CGFunctionCreate( (void *)colors, 1U, NULL, 4U, NULL, &callbacks );
	
	shading = CGShadingCreateAxial( colorspace, startPoint, endPoint, function, false, false );
	
	CGContextDrawShading( context, shading );
	
	CGShadingRelease( shading );
	CGColorSpaceRelease( colorspace );
	CGFunctionRelease( function );
	
	CGContextRestoreGState( context );
}

- (void)drawRect:(NSRect)rect
{
	//remainder and thumb
	[self drawControlBackgroundInRect:[self bounds]
							   active:NO];
	
	[super drawRect:rect];
}

@end
