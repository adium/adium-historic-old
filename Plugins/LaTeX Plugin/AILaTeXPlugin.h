//
//  AILaTeXPlugin.h
//  Adium
//
//  Created by Stephen Poprocki on Sat Dec 13 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//
//

@protocol AIContentFilter;

@interface AILaTeXPlugin : AIPlugin <AIContentFilter>
{
}

- (NSMutableAttributedString *)attributedStringWithPasteboard:(NSPasteboard *)pb textEquivalent:(NSString *)textEquivalent;

@end
