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
    NSMutableAttributedString   *replacementMessage = [[[NSMutableAttributedString alloc] initWithAttributedString:[scanner linkifyString:inAttributedString]] autorelease];
    return (replacementMessage);
}


@end



