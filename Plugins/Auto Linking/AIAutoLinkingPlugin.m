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

#import "AIAutoLinkingPlugin.h"
#import "AIContentController.h"
#import <AIHyperlinks/AIHyperlinks.h>
 
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



