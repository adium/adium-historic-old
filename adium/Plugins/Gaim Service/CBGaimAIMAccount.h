//
//  CBGaimAIMAccount.h
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "CBGaimAccount.h"
#import "aim.h"

@interface CBGaimAIMAccount : CBGaimAccount {

}

//Overriden from CBGAimAccount
- (NSArray *)supportedPropertyKeys;
- (NSString *)accountID;
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;
- (NSString *)accountDescription;
@end
