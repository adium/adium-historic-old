//
//  AIMessageAliasPlugin.h
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//

@protocol AIContentFilter;

@interface AIMessageAliasPlugin  : AIPlugin <AIContentFilter, AIStringFilter>
{
    NSDictionary *hash;
}

@end
