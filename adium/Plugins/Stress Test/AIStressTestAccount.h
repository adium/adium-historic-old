//
//  AIStressTestAccount.h
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//
#ifdef DEVELOPMENT_BUILD
@interface AIStressTestAccount : AIAccount <AIAccount_Content> {
    NSMutableDictionary	*chatDict;

    AIChat			*commandChat;
    AIListContact	*commandContact;
}
- (void)echo:(NSString *)string;
- (void)_echo:(NSString *)string;

@end
#endif