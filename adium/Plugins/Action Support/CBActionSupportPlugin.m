//
//  CBActionSupportPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Jun 17 2003.
//

#import "CBActionSupportPlugin.h"

@implementation CBActionSupportPlugin

- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *ourMessage = nil;
    if (inAttributedString) {
        NSRange meRange = [[inAttributedString string] rangeOfString:@"/me "];
        
        if(meRange.location == 0 && meRange.length == 4)
        {
            ourMessage = [[inAttributedString mutableCopyWithZone:nil] autorelease];
            
            [ourMessage replaceCharactersInRange:meRange withString:@"*"];
            
            NSAttributedString *splat = [[NSAttributedString alloc] initWithString:@"*" 
                                                                        attributes:[ourMessage attributesAtIndex:0 
                                                                                                  effectiveRange:nil]];
            [ourMessage appendAttributedString:splat];
            [splat release];
        }
    }
    return (ourMessage ? ourMessage : inAttributedString);
}

@end