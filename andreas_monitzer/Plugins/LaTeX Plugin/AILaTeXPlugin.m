/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// User must have a working LaTeX and Equation Service installation for anything to happen.

#import "AIContentController.h"
#import "AILaTeXPlugin.h"
#import <Adium/AITextAttachmentExtension.h>

@interface AILaTeXPlugin (PRIVATE)
+ (NSMutableAttributedString *)attributedStringWithPasteboard:(NSPasteboard *)pb textEquivalent:(NSString *)textEquivalent;
@end

/*!
 * @class AILaTeXPlugin
 * @brief Filter plugin which converts $$xxx$$, where xxx is a LaTeX expression, to LaTeX
 *
 * This has no effect if the LaTeX Equation Service is not installed.
 */
@implementation AILaTeXPlugin

- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString       *newMessage = nil;

    if (inAttributedString && 
		([[inAttributedString string] rangeOfString:@"$$" options:NSLiteralSearch].location != NSNotFound)) {
		NSScanner       *stringScanner;
		NSArray         *returnTypes;
		NSPasteboard    *pb;
		NSString        *innerLaTeX;
		int				i, removedChars = 0; 
        
		stringScanner = [[NSScanner alloc] initWithString:[inAttributedString string]];
        returnTypes = [NSArray arrayWithObjects:NSPDFPboardType, NSStringPboardType, nil];
        pb = [NSPasteboard pasteboardWithName:@"latexPboard"];
		
		[stringScanner setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];
		
		while ([stringScanner isAtEnd] == NO) {
			[stringScanner scanUpToString:@"$$" intoString:nil];
			[stringScanner scanString:@"$$" intoString:nil];
			
			i = [stringScanner scanLocation];
			if ([stringScanner scanUpToString:@"$$" intoString:&innerLaTeX] && ![stringScanner isAtEnd]) {
				[stringScanner setScanLocation:([stringScanner scanLocation]+2)];

				[pb declareTypes:returnTypes owner:self];
				[pb setString:innerLaTeX forType:NSStringPboardType];
				if (NSPerformService(@"Equation Service/Typeset Equation", pb)) {
					NSString                    *fullLaTeX;
					NSMutableAttributedString   *replacement;
					
					fullLaTeX = [NSString stringWithFormat:@"$$%@$$", innerLaTeX];
					replacement = [[self class] attributedStringWithPasteboard:pb 
														textEquivalent:fullLaTeX];
					
					// grab the original attributes, to ensure that the background is not lost in a message consisting only of LaTeX
					[replacement addAttributes:[inAttributedString attributesAtIndex:i effectiveRange:nil]
										 range:NSMakeRange(0,1)];
					
					// insert the image
					if (!newMessage) // only create the copy if needed
						newMessage = [[inAttributedString mutableCopy] autorelease];

					[newMessage replaceCharactersInRange:NSMakeRange(i-2-removedChars, [fullLaTeX length]) 
									withAttributedString:replacement];
					removedChars += [fullLaTeX length]-1;
				}
			}
		}

		[stringScanner release];
    }

    return (newMessage ? newMessage : inAttributedString);
}

- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

/*!
 * @brief Returns an attributed string containing the LaTeX image
 */
+ (NSMutableAttributedString *)attributedStringWithPasteboard:(NSPasteboard *)pb textEquivalent:(NSString *)textEquivalent
{
    NSImage						*img = [[NSImage alloc] initWithPasteboard:pb];
    NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:img];
    AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
    NSMutableAttributedString	*attachString;
    
    [attachment setAttachmentCell:cell];
    [attachment setString:textEquivalent];
    [attachment setShouldSaveImageForLogging:YES];
	[attachment setHasAlternate:YES];
	[attachment setImage:img];
    attachString = [[[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy] autorelease];
    
    [img release];
    [cell release];
    [attachment release];

    return attachString;
}

@end
