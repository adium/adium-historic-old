//
//  AIAutoLinkingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 12 2003.
//

#import "AIAutoLinkingPlugin.h"

 
@implementation AIAutoLinkingPlugin

- (void)installPlugin
{
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterOutgoing];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
//	[[adium contentController] unregisterDisplayingContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    SHHyperlinkScanner          *scanner = [[[SHHyperlinkScanner alloc] initWithStrictChecking:NO] autorelease];
    NSMutableAttributedString   *replacementMessage = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    NSRange                      linkRange = NSMakeRange(0,0);
    unsigned                     index = 0;
    unsigned                     stringLength = [inAttributedString length];
    
    // do some quick scanning to avoid overwriting custom titled links that happen to have domain names in them.
    // e.g. if the entire string "check out the new story on adiumx.com" is linked to a specific story URI, then
    // adiumx.com should not link to only http://adiumx.com
    while(index < stringLength){
        if([inAttributedString attribute:NSLinkAttributeName atIndex:index effectiveRange:&linkRange]){
            // if the link is found at that index, append the link's whole range to the replacement string
            [replacementMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:linkRange]];
        }else{
            // if not, the range to the next link attribute is returned, and we linkify that range's substring
            [replacementMessage appendAttributedString:[scanner linkifyString:[inAttributedString attributedSubstringFromRange:linkRange]]];
        }
        // increase the index
        index += linkRange.length;
    }
    
    return (replacementMessage);
}


@end



