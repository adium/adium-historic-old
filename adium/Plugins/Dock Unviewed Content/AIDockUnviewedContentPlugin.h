//
//  AIDockUnviewedContentPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Apr 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIDockUnviewedContentPlugin : AIPlugin <AIContactObserver> {
    NSMutableArray		*unviewedContactsArray;
    AIIconState			*unviewedState;

}

@end
