//
//  AILaTeXPlugin.m
//  Adium XCode
//
//  Created by Stephen Poprocki on Sat Dec 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AILaTeXPlugin.h"
#import "AILaTeXAttachment.h"

@implementation AILaTeXPlugin

- (void)installPlugin
{
    [[owner contentController] registerDisplayingContentFilter:self];
    NSLog(@"Installing LaTeX Plugin");
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        NSLog(@"Checking message");
        AIContentMessage *contMsg = (AIContentMessage *)inObject;
        NSMutableAttributedString *newMessage = [[[contMsg message] mutableCopy] autorelease];
        NSScanner *stringScanner;
        NSString *retStr;
        NSArray *returnTypes = [NSArray arrayWithObjects:NSStringPboardType, nil];
        NSPasteboard *pb =[NSPasteboard pasteboardWithName:@"latexPboard"];
        
        [pb declareTypes:returnTypes owner:self];
    
        int i, removedChars = 0;
        stringScanner = [[NSScanner alloc] initWithString: [newMessage string]];
        while ([stringScanner isAtEnd] == NO)
        {
            [stringScanner scanUpToString:@"$$" intoString:nil];
            if ([stringScanner scanString:@"$$" intoString:nil] && ([stringScanner isAtEnd] == NO))
            {
                i = [stringScanner scanLocation];
                [stringScanner scanUpToString:@"$$" intoString:&retStr];
                [stringScanner setScanLocation:([stringScanner scanLocation]+2)];
                
                [pb setString:retStr forType:NSStringPboardType];
                if(NSPerformService(@"Equation Service/Typeset Equation",pb))
                {
                    NSString *fullStr = [NSString stringWithFormat:@"$$%@$$", retStr];
                    AILaTeXAttachment *attachment = [[[AILaTeXAttachment alloc] init] autorelease];
                    NSMutableAttributedString *replacement = [attachment attributedStringWithTextEquivalent:fullStr];
                    
                    //grab the original attributes, to ensure that the background is not lost in a message consisting only of an emoticon
                    [replacement addAttributes:[[contMsg message] attributesAtIndex:i effectiveRange:nil] range:NSMakeRange(0,1)];
                    //insert the image
                    [newMessage replaceCharactersInRange:NSMakeRange(i-2-removedChars, [retStr length]+4) withAttributedString:replacement];
                    removedChars += [retStr length]+3;
                }
            }
        }
        
        [contMsg setMessage:newMessage];
    }
}

@end