/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIGradient.h"
#import "BZContextImageBridge.h"

@interface AIGradient (PRIVATE)

- (id)initWithFirstColor:(NSColor*)inColor1
			 secondColor:(NSColor*)inColor2
			   direction:(AIDirection)inDirection;

@end

typedef struct
{
	float red;
	float green;
	float blue;
	float alpha;
} FloatRGB;

typedef struct
{
	//the start and end colours of a gradient.
	FloatRGB start;
	FloatRGB end;
} TwoColors;

void returnColorValue(void *refcon, const float *blendPoint, float *output);

int BlendColors(FloatRGB *result, FloatRGB *a, FloatRGB *b, float scale);

CGPathRef CreateCGPathWithNSBezierPath(const CGAffineTransform *transform, NSBezierPath *bezierPath);

enum {
	//number of bits for each component of a colour value.
	//for a 24-bit RGB value, this is 8.
	//for a 32-bit RGBA value (which is what this code uses), this is still 8.
	bitsPerComponent = 8U,
	componentsPerPixel = 4U, //RGBA
	bitsPerPixel = bitsPerComponent * componentsPerPixel
};

@implementation AIGradient

#pragma mark Class Initialization
+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(AIDirection)inDirection
{
	return ([[[self alloc] initWithFirstColor:inColor1 secondColor:inColor2 direction:inDirection] autorelease]);
}

+ (AIGradient*)selectedControlGradientWithDirection:(AIDirection)inDirection
{
	NSColor *selectedColor = [NSColor alternateSelectedControlColor];
	
	return ([self gradientWithFirstColor:[selectedColor darkenAndAdjustSaturationBy:-0.1] secondColor:[selectedColor darkenAndAdjustSaturationBy:0.1] direction:inDirection]);
}

- (void)dealloc {
	[color1 release];
	[color2 release];
	[super dealloc];
}

#pragma mark Private

- (id)initWithFirstColor:(NSColor*)inColor1
			 secondColor:(NSColor*)inColor2
			   direction:(AIDirection)inDirection
{
	if (self = [self init]) {
		[self setFirstColor:inColor1];
		[self setSecondColor:inColor2];
		[self setDirection:inDirection];
	}
	return self;
}

#pragma mark Accessor Methods

- (void)setFirstColor:(NSColor*)inColor
{
	if (color1) {
		[color1 release];
		color1 = nil;
	}
	color1 = [inColor retain];
}
- (NSColor*)firstColor
{
	return color1;
}

- (void)setSecondColor:(NSColor*)inColor
{
	if (color2) {
		[color2 release];
		color2 = nil;
	}
	color2 = [inColor retain];
}
- (NSColor*)secondColor
{
	return color1;
}

- (void)setDirection:(AIDirection)inDirection
{
	direction = inDirection;
}
- (AIDirection)direction
{
	return direction;
}

#pragma mark Drawing

- (void)drawInRect:(NSRect)inRect
{
	[self drawInBezierPath:[NSBezierPath bezierPathWithRect:inRect]];
}

//used, currently.
- (void)drawInBezierPath:(NSBezierPath *)inPath
{   
	NSRect inRect = [inPath bounds];
	CGRect *cgRect = (CGRect *)&inRect;

	//the transform shifts the CGPath to origin = 0,0 and scales it down to an integer width (and height).
	float wscale = ((int)inRect.size.width)  / inRect.size.width;
	float hscale = ((int)inRect.size.height) / inRect.size.height;
	CGAffineTransform transform = CGAffineTransformMake(
		/*a*/ wscale, /*b*/ 0.0f,
		/*c*/ 0.0f,   /*d*/ hscale,
		/*tx*/ -(inRect.origin.x), /*ty*/ -(inRect.origin.y)
	);
	cgRect->size = CGSizeApplyAffineTransform(cgRect->size, transform);

	float   width = inRect.size.width,
	height = inRect.size.height;

	TwoColors blendPoints;
	NSColor *startColor = [color1 retain], *endColor = [color2 retain], *temp;

	if(![[startColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
	{
		temp = startColor;
		startColor = [[startColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] retain];
		[temp release];
	}

	if(![[endColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
	{
		temp = endColor;
		endColor = [[endColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] retain];
		[temp release];
	}

	[startColor getRed:&(blendPoints.start.red)
	             green:&(blendPoints.start.green)
	              blue:&(blendPoints.start.blue)
	             alpha:&(blendPoints.start.alpha)];

	[endColor getRed:&(blendPoints.end.red)
	           green:&(blendPoints.end.green)
	            blue:&(blendPoints.end.blue)
	           alpha:&(blendPoints.end.alpha)];

	[startColor release];
	[endColor release];

	struct CGFunctionCallbacks callbacks = { 0, returnColorValue, NULL };
	
	CGFunctionRef function = CGFunctionCreate(
		&blendPoints,	// void *info,
		1,				// size_t domainDimension,
		NULL,			// float const *domain,
		4,				// size_t rangeDimension,
		NULL,			// float const *range,
		&callbacks		// CGFunctionCallbacks const *callbacks
	);
	if (function != NULL)
	{
		CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
		if (cspace != NULL)
		{
			CGPoint srcPt, dstPt;

			//note that the comments in this section refer to the bounds of
			//  the context, not the window. (e.g. 'top' means 'top of the
			//  context', not 'top of the window'.)
			if(direction == AIVertical)
			{
				//draw the gradient from the top middle to the bottom middle.
				srcPt.x = dstPt.x = width / 2.0f;
				srcPt.y = 0.0f;
				dstPt.y = height;
			}
			else
			{
				//draw the gradient from the middle left to the middle right.
				srcPt.y = dstPt.y = height / 2.0f;
				srcPt.x = 0.0f;
				dstPt.x = width;
			}

			CGShadingRef shading = CGShadingCreateAxial(
				cspace,		// CGColorSpaceRef colorspace,
				srcPt,		// CGPoint start,
				dstPt,		// CGPoint end,
				function,	// CGFunctionRef function,
				false,		// bool extendStart,
				false		// bool extendEnd
			);

			if (shading != NULL)
			{
				BZContextImageBridge *bridge = [BZContextImageBridge bridgeWithSize:inRect.size];
				CGContextRef context = [bridge context];

				if (context != NULL)
				{
					CGContextBeginPath(context);

					//Drawing stuff
					CGPathRef pathToAdd = CreateCGPathWithNSBezierPath(&transform, inPath); //thanks boredzo :)
					if(pathToAdd != NULL)
					{
						CGContextAddPath(context, pathToAdd);
						CGContextClip(context);

						CGContextDrawShading(context, shading);

						NSImage *image = [bridge image];

						[image drawInRect:inRect fromRect:NSMakeRect(0.0f,0.0f, width, height) operation:NSCompositeSourceOver fraction:1.0f];
						
						CGPathRelease(pathToAdd);
					} /* if(pathToAdd != NULL) */
					CGContextRelease(context);
				} /* if(context) */
				CGShadingRelease(shading);
			} /* if(shading) */
			CGColorSpaceRelease(cspace);
		} /* if(cspace) */
		CGFunctionRelease(function);
	} /* if(function) */
}

#pragma mark C Functions

//returnColorValue
//
//callback function for Quartz shaders.
//simply returns a colour along a plane, where blendPoint = 0.0f represents the
//  start of the plane and blendPoint = 1.0f represents the end of it.
//1 input:   the blend-point.
//4 outputs: the four components (RGBA) of the colour resulting from the blend.
//reference constant: a pointer to a TwoColors value giving the start and end
//  points of the aforementioned plane.
void returnColorValue(void *refcon, const float *blendPoint, float *output)
{
	TwoColors *gradient = refcon;

	BlendColors((FloatRGB *)output, &(gradient->start), &(gradient->end), *blendPoint);

	/*slow version:
	FloatRGB newColor;
	
	BlendColors(&newColor, &(gradient->start), &(gradient->end), *blendPoint);

	output[0] = newColor.red;
	output[1] = newColor.green;
	output[2] = newColor.blue;
	output[3] = newColor.alpha;
	*/
}

//BlendColors
//
//blend two colours, a and b, biased by scale (0.0f-1.0f).
//components, as is typical of Quartz, are 0.0f-1.0f also.
//return value is 0 if successful or < 0 if not.

int BlendColors(FloatRGB *result, FloatRGB *a, FloatRGB *b, float scale)
{
	//assure that the scale value is within the range of 0.0f-1.0f.
	if      (scale > 1.0f) scale = 1.0f;
	else if (scale < 0.0f) scale = 0.0f;

	float scaleComplement = 1.0f - scale;
	result->alpha = scale * b->alpha + scaleComplement * a->alpha;
	scale		  = scale * a->alpha + scaleComplement * (1.0f - b->alpha);
	scaleComplement = 1.0f - scale;
	result->red   = scale * b->red   + scaleComplement * a->red;
 	result->green = scale * b->green + scaleComplement * a->green;
	result->blue  = scale * b->blue  + scaleComplement * a->blue;

	return 0;
}

@end

//transform can be NULL. --boredzo
CGPathRef CreateCGPathWithNSBezierPath(const CGAffineTransform *transform, NSBezierPath *bezierPath)
{
	CGMutablePathRef cgpath = CGPathCreateMutable();
	if(cgpath != NULL)
	{
		int numElements = [bezierPath elementCount];
		int curElement;
		NSBezierPathElement elementType;
		NSPoint points[3];

		for(curElement = 0; curElement < numElements; curElement++)
		{
			//the points are copied into our points array. --boredzo
			elementType = [bezierPath elementAtIndex:curElement associatedPoints:points];

			switch(elementType)
			{
				case NSMoveToBezierPathElement:
					CGPathMoveToPoint(cgpath, transform,
						points[0].x, points[0].y);
					break;
				case NSLineToBezierPathElement:
					CGPathAddLineToPoint(cgpath, transform,
						points[0].x, points[0].y);
					break;
				case NSCurveToBezierPathElement:
					CGPathAddCurveToPoint(cgpath, transform,
						points[0].x, points[0].y,
						points[1].x, points[1].y,
						points[2].x, points[2].y);
					break;
				case NSClosePathBezierPathElement:
					CGPathCloseSubpath(cgpath);
					break;
				default:
					/*do something here? --boredzo
					 *I don't know if there are any others... --colin
					 *there aren't, but if elementAtIndex:associatedPoints:
					 *  returns an invalid (error) value, we might want to
					 *  report that to the user or something --boredzo
					 */;
			} //switch(elementType)
		} //for(curElement = 0; curElement < numElements; curElement++)
	} //if(cgpath != NULL)

	return cgpath;
}
