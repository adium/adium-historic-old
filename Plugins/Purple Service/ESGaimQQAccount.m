//
//  ESGaimQQAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

#import "ESGaimQQAccount.h"


@implementation ESGaimQQAccount

- (const char*)protocolPlugin
{
    return "prpl-qq";
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (label && (strcmp(label, "Modify my information") == 0)) {
		/* Modifying information depends upon adiumGaimRequestFields */
		return nil;
	}
	
	return [super titleForAccountActionMenuLabel:label];
}

@end
