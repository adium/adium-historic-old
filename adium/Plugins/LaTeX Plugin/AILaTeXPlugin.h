//
//  AILaTeXPlugin.h
//  Adium XCode
//
//  Created by Stephen Poprocki on Sat Dec 13 2003.
//

@protocol AIContentFilter;

@interface AILaTeXPlugin : AIPlugin <AIContentFilter>
{
}

- (NSMutableAttributedString *)attributedStringWithPasteboard:(NSPasteboard *)pb textEquivalent:(NSString *)textEquivalent;

@end
