//
//  AIStressTestAccount.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface AIStressTestAccount : AIAccount <AIAccount_Content> {
    NSMutableDictionary	*chatDict;

    AIChat			*commandChat;
    AIListContact	*commandContact;
}
- (void)echo:(NSString *)string;
- (void)_echo:(NSString *)string;
- (AIChat *)chatForContact:(AIListContact *)inContact;

@end
