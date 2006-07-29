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
	//hack so we can message to offline smack contacts
	AIListContact *bogusContact;
    BOOL expanded;
    float largestOrder;
    float smallestOrder;
}

- (NSAttributedString *)resourceInfo;

@end
