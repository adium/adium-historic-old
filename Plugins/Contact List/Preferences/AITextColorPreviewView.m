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

#import "AITextColorPreviewView.h"
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

@interface AITextColorPreviewView (PRIVATE)
- (void)_initTextColorPreviewView;
@end

@implementation AITextColorPreviewView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initTextColorPreviewView];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _initTextColorPreviewView];
    return(self);
}

- (void)_initTextColorPreviewView
{
	backColorOverride = nil;
}

- (void)drawRect:(NSRect)rect
{
	NSMutableDictionary	*attributes;
	NSAttributedString	*sample;
	id					shadow = nil;

	//Background
	if(backgroundGradientColor){
		[[AIGradient gradientWithFirstColor:[backgroundGradientColor color]
							   secondColor:[backgroundColor color]
								 direction:AIVertical] drawInRect:rect];
	}else{
		[(backColorOverride ? backColorOverride : [backgroundColor color]) set];
		[NSBezierPath fillRect:rect];
	}

	//Shadow
	if([NSApp isOnPantherOrBetter] && [textShadowColor color]){
		Class 	shadowClass = NSClassFromString(@"NSShadow"); //Weak Linking for 10.2 compatability
		shadow = [[[shadowClass alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[textShadowColor color]];
	}

	//Text
	attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:12], NSFontAttributeName,
		[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment], NSParagraphStyleAttributeName,
		[textColor color], NSForegroundColorAttributeName,
		nil];
	if(shadow) [attributes setObject:shadow forKey:NSShadowAttributeName];
	
	sample = [[[NSAttributedString alloc] initWithString:AILocalizedString(@"Sample",nil)
											  attributes:attributes] autorelease];
	int	sampleHeight = [sample size].height;
	
#warning todo: center the string in the rect
	[sample drawInRect:NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - sampleHeight) / 2.0,
								  rect.size.width,
								  sampleHeight)];
}

- (void)dealloc
{
	[backColorOverride release];
	[super dealloc];
}

//Overrides.  pass nil to disable
- (void)setBackColorOverride:(NSColor *)inColor
{
	if(backColorOverride != inColor){
		[backColorOverride release];
		backColorOverride = [inColor retain];
	}
}

@end
