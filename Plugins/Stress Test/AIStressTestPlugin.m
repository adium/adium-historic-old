///
//  AIStressTestPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//

#import "AIStressTestPlugin.h"
#import "AIStressTestAccount.h"
#import "DCStressTestJoinChatViewController.h"
#import "AIStressTestService.h"

@implementation AIStressTestPlugin

- (void)installPlugin
{
#ifdef DEVELOPMENT_BUILD
	[[AIStressTestService alloc] init];
#endif
}


@end

