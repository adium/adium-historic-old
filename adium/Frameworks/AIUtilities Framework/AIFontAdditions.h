//
//  AIFontAdditions.h
//  Adium
//
//  Created by Adam Iser on Wed Dec 25 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFont (AIFontAdditions)
- (NSAttributedString *)stringRepresentation;
@end

@interface NSString (AIFontAdditions)
- (NSFont *)representedFont;
@end
