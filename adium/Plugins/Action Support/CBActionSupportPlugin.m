//
//  CBActionSupportPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Jun 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBActionSupportPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

@implementation CBActionSupportPlugin

- (void)installPlugin
{
    //Register us as a filter
    [[owner contentController] registerOutgoingContentFilter:self];
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        AIContentMessage *inObj = (AIContentMessage *)inObject;
        NSRange meRange = [[[inObj message] string] rangeOfString:@"/me "];
        
        if(meRange.location == 0 && meRange.length == 4)
        {
            NSMutableAttributedString *ourMessage = [[inObj message] mutableCopy];
            
            [ourMessage replaceCharactersInRange:meRange withString:@"*"];
            
            NSAttributedString *splat = [[NSAttributedString alloc] initWithString:@"*" 
                attributes:[ourMessage attributesAtIndex:0 effectiveRange:nil]];
            [ourMessage appendAttributedString:splat];
            [splat release];
            
            [inObj setMessage:ourMessage];
            [ourMessage release];
        }
    }
}

@end