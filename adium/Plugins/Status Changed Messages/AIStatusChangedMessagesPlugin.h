//
//  AIStatusChangedMessagesPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Apr 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@protocol AIContactObserver;

@interface AIStatusChangedMessagesPlugin : AIPlugin  <AIContactObserver> {

}

@end
