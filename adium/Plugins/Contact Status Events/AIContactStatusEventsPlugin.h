//
//  AIContactStatusEventsPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Feb 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@interface AIContactStatusEventsPlugin : AIPlugin <AIHandleObserver> {
    NSMutableDictionary		*onlineDict;
    NSMutableDictionary		*awayDict;
    NSMutableDictionary		*idleDict;

}


@end
