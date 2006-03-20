//
//  RAFjoscarAIMService.m
//  Adium
//
//  Created by Augie Fackler on 12/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "RAFjoscarAIMService.h"
#import "RAFjoscarAIMAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIImageAdditions.h>
#import "RAFjoscarAccountViewController.h"

@implementation RAFjoscarAIMService

//subclass should change this
- (Class)accountClass{
	return [RAFjoscarAIMAccount class];
}

//Account Creation
- (AIAccountViewController *)accountViewController{
    return [RAFjoscarAccountViewController accountViewController];
}

- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}

//subclass should change this
- (NSString *)serviceCodeUniqueID{
	return(@"joscar-OSCAR-AIM");
}
//subclass should change this
- (NSString *)shortDescription{
	return @"AIM";
}
//subclass should change this
- (NSString *)longDescription{
	return @"AOL Instant Messenger";
}
//subclass should change this
- (NSString *)serviceID{
	return @"AIM";
}

//subclass should change this
//- (DCJoinChatViewController *)joinChatView{
//	return(nil);
//}

- (NSImage *)defaultServiceIcon{
	static NSImage	*defaultServiceIcon = nil;
	if (!defaultServiceIcon) defaultServiceIcon = [[NSImage imageNamed:@"joscar" forClass:[self class]] retain];
	return defaultServiceIcon;
}

@end
