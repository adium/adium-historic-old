//
//  AIStressTestAccount.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright 2003-2005 The Adium Team. All rights reserved.
//

@interface AIStressTestAccount : AIAccount {
    NSMutableDictionary	*chatDict;

    AIChat			*commandChat;
	AIChat			*groupChat;
    AIListContact	*commandContact;
	NSMutableArray  *listObjectArray;
}

- (void)echo:(NSString *)string;
- (void)_echo:(NSString *)string;

@end
