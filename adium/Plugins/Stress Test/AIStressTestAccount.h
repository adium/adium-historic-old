//
//  AIStressTestAccount.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface AIStressTestAccount : AIAccount <AIAccount_Content> {
    NSMutableDictionary	*handleDict;
    NSMutableDictionary	*chatDict;

    AIChat	*commandChat;
    AIHandle	*commandHandle;
}
- (void)echo:(NSString *)string;
- (void)_echo:(NSString *)string;
- (AIChat *)chatForHandle:(AIHandle *)inHandle;

@end
