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
    //Register our content filter
	[[adium contentController] registerDisplayingContentFilter:self];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterDisplayingContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
{
    SHHyperlinkScanner          *scanner = [[[SHHyperlinkScanner alloc] initWithStrictChecking:NO] autorelease];
    NSMutableAttributedString   *replacementMessage = [[[NSMutableAttributedString alloc] initWithAttributedString:[scanner linkifyString:inAttributedString]] autorelease];
    return (replacementMessage);
}


@end



