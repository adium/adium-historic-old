//
//  AdiumIBPalette.m
//  AdiumIBPalette
//
//  Created by Peter Hosey on 2006-05-11.
//  Copyright 2006 The Adium Project. All rights reserved.
//

#import "AdiumIBPalette.h"

@implementation AdiumIBPalette

- (void)finishInstantiate
{
	/* `finishInstantiate' can be used to associate non-view objects with
	 * a view in the palette's nib.  For example:
	 *   [self associateObject:aNonUIObject ofType:IBObjectPboardType
	 *                withView:aView];
	 */
	[super finishInstantiate];
}

@end
