//
//  AIEventAdditions.m
//  Adium
//
//  Created by Adam Iser on Wed Jan 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEventAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSEvent (AIEventAdditions)

+ (BOOL)cmdKey{
    return(([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0);
}

+ (BOOL)shiftKey{
    return(([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) != 0);
}

+ (BOOL)optionKey{    
    return(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
}

+ (BOOL)controlKey{
    return(([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) != 0);
}

@end