//
//  SHAOLamerKillerPlugin.h
//  Adium
//
//  Created by Stephen Holt on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@protocol AIContentFilter;

@interface SHAOLamerKillerPlugin :  AIPlugin <AIContentFilter> {
    NSArray *stringShitlist;
    int killCount;
}

@end
