//
//  AIEventAdditions.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSEvent (AIEventAdditions)

+ (BOOL)cmdKey;
+ (BOOL)shiftKey;
+ (BOOL)optionKey;
+ (BOOL)controlKey;
    
@end
