//
//  AIAutoLinkingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 12 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIAutoLinkingPlugin.h"

 
@implementation AIAutoLinkingPlugin

- (void)installPlugin
{
	hyperlinkScanner = [[SHHyperlinkScanner alloc] initWithStrictChecking:NO];

	[[adium contentController] registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
	
	//Filter as content when outgoing so other content filters can know about the presence of links
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];

	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{

}

- (void)dealloc
{
	[hyperlinkScanner release];
	
	[super dealloc];
}
	
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	NSMutableAttributedString	*replacementMessage = nil;

	if(inAttributedString){
		NSRange						linkRange = NSMakeRange(0,0);
		unsigned					index = 0;
		unsigned					stringLength = [inAttributedString length];

		replacementMessage = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];

		// do some quick scanning to avoid overwriting custom titled links that happen to have domain names in them.
		// e.g. if the entire string "check out the new story on adiumx.com" is linked to a specific story URI, then
		// adiumx.com should not link to only http://adiumx.com
		while(index < stringLength){
			if([inAttributedString attribute:NSLinkAttributeName atIndex:index effectiveRange:&linkRange]){
				// if the link is found at that index, append the link's whole range to the replacement string
				[replacementMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:linkRange]];
			}else{
				// if not, the range to the next link attribute is returned, and we linkify that range's substring
				[replacementMessage appendAttributedString:[hyperlinkScanner linkifyString:[inAttributedString attributedSubstringFromRange:linkRange]]];
			}
			// increase the index
			index += linkRange.length;
		}
	}
	
    return (replacementMessage);
}

//Auto linking overrides other potential filters; do it first
- (float)filterPriority
{
	return HIGHEST_FILTER_PRIORITY;
}

@end



