//
//  AILaTeXPlugin.m
//  Adium XCode
//
//  Created by Stephen Poprocki on Sat Dec 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

// User must have a working LaTeX and Equation Service installation for anything to happen.

#import "AILaTeXPlugin.h"

@implementation AILaTeXPlugin

- (void)installPlugin
{
    [[owner contentController] registerDisplayingContentFilter:self];
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if([[inObject type] isEqual:CONTENT_MESSAGE_TYPE])
    {
        AIContentMessage *contMsg = (AIContentMessage *)inObject;
        NSMutableAttributedString *newMessage = [[contMsg message] mutableCopy];
        NSScanner *stringScanner = [[NSScanner alloc] initWithString: [newMessage string]];
        NSArray *returnTypes = [NSArray arrayWithObjects:NSPDFPboardType, NSStringPboardType, nil];
        NSPasteboard *pb = [NSPasteboard pasteboardWithName:@"latexPboard"];
        NSString *innerLaTeX;
        int i, removedChars = 0; 
        
        [stringScanner setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];
        while ([stringScanner isAtEnd] == NO)
        {
            [stringScanner scanUpToString:@"$$" intoString:nil];
            [stringScanner scanString:@"$$" intoString:nil];
            
            i = [stringScanner scanLocation];
            if([stringScanner scanUpToString:@"$$" intoString:&innerLaTeX] && ([stringScanner isAtEnd] == NO))
            {
                [stringScanner setScanLocation:([stringScanner scanLocation]+2)];
                
                [pb declareTypes:returnTypes owner:self];
                [pb setString:innerLaTeX forType:NSStringPboardType];
                if(NSPerformService(@"Equation Service/Typeset Equation", pb))
                {
                    NSString *fullLaTeX = [NSString stringWithFormat:@"$$%@$$", innerLaTeX];
                    NSMutableAttributedString *replacement = [self attributedStringWithPasteboard:pb textEquivalent:fullLaTeX];
                    
                    //grab the original attributes, to ensure that the background is not lost in a message consisting only of LaTeX
                    [replacement addAttributes:[[contMsg message] attributesAtIndex:i effectiveRange:nil] range:NSMakeRange(0,1)];
                    //insert the image
                    [newMessage replaceCharactersInRange:NSMakeRange(i-2-removedChars, [fullLaTeX length]) withAttributedString:replacement];
                    removedChars += [fullLaTeX length]-1;
                }
            }
        }
        
        [contMsg setMessage:newMessage];
        [newMessage release];
        [stringScanner release];
    }
}

//Returns an attributed string containing the LaTeX image
- (NSMutableAttributedString *)attributedStringWithPasteboard:(NSPasteboard *)pb textEquivalent:(NSString *)textEquivalent
{
    NSImage *img = [[NSImage alloc] initWithPasteboard:pb];
    NSTextAttachmentCell *cell = [[NSTextAttachmentCell alloc] initImageCell:img];
    AITextAttachmentExtension *attachment = [[AITextAttachmentExtension alloc] init];
    NSAttributedString *attachString;
    
    [attachment setAttachmentCell:cell];
    [attachment setString:textEquivalent];
    attachString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    [img release];
    [cell release];
    [attachment release];
    return [[attachString mutableCopy] autorelease];
}

@end
