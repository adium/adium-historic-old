//
//  SmackListContact.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-05.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIListContact.h"

@interface SmackListContact : AIListContact <AIContainingObject> {
    NSMutableArray *containedObjects;
    BOOL expanded;
    float largestOrder;
    float smallestOrder;
}

@end
