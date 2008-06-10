//
//  AISocialNetworkingStatusMenu.h
//  Adium
//
//  Created by Evan Schoenberg on 6/7/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class AIAccount;

@interface AISocialNetworkingStatusMenu : AIObject {

}

+ (NSMenuItem *)socialNetworkingSubmenuItem;
+ (NSMenu *)socialNetworkingSubmenuForAccount:(AIAccount *)inAccount;

@end
