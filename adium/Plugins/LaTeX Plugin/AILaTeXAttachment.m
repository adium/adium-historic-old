//
//  AILaTeXAttachment.m
//  Adium XCode
//
//  Created by the Stephen Poprocki on Sat Dec 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AILaTeXAttachment.h"

@implementation AILaTeXAttachment

//Returns an attributed string containing the LaTeX image
- (NSMutableAttributedString *)attributedStringWithTextEquivalent:(NSString *)textEquivalent
{
    AITextAttachmentExtension *attachment;
    NSFileWrapper *wrapper;
    NSAttributedString *attachString;
    NSString *path = [@"~/Library/Application Support/Equation Service/Output/final.pdf" stringByExpandingTildeInPath];
    
    wrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
    attachment = [[[AITextAttachmentExtension alloc] initWithFileWrapper:wrapper] autorelease];
    [attachment setString:textEquivalent];
    attachString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    return [[attachString mutableCopy] autorelease];
}

@end
