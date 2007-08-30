//
//  ESPurpleQQAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

#import "ESPurpleQQAccount.h"


@implementation ESPurpleQQAccount

- (const char*)protocolPlugin
{
    return "prpl-qq";
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (label && (strcmp(label, "Modify my information") == 0)) {
		return AILocalizedString(@"Modify My Information", "Menu title for configuring the public information for a QQ account");
	}
	
	return [super titleForAccountActionMenuLabel:label];
}

@end
