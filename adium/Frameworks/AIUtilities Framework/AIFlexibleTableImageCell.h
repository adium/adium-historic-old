//
//  AIFlexibleTableImageCell.h
//  Adium
//
//  Created by Adam Iser on Thu Jan 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIFlexibleTableCell.h"

@interface AIFlexibleTableImageCell : AIFlexibleTableCell {
    NSImage	*image;
}

+ (AIFlexibleTableImageCell *)cellWithImage:(NSImage *)inImage;

@end
