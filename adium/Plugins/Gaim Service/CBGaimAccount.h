//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface CBGaimAccount : AIAccount 
{

}


//AIAccount sublcassed methods
- (void)initAccount;
- (NSArray *)supportedPropertyKeys;
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue;
- (NSDictionary *)defaultProperties;
- (id <AIAccountViewController>)accountView;
- (NSString *)accountID;
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;
- (NSString *)accountDescription;
@end
