//
//  SHAOLamerKillerPlugin.h
//  Adium
//
//  Created by Stephen Holt on Tue Jul 13 2004.

@protocol AIContentFilter;

@interface SHAOLamerKillerPlugin :  AIPlugin <AIContentFilter> {
    NSArray *stringShitlist;
    int killCount;
}

@end
