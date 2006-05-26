//
//  BDClientSupport.h
//  Adium
//
//  Created by Brandon on 2/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDClientSupport.h"

#define ICHAT_LOG_DATA			@"PATH"
#define ICHAT_STATUS_DATA		[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"com.apple.iChat.plist"]

#define FIRE_LOG_DATA			@"PATH"
#define FIRE_STATUS_DATA		[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Fire"] stringByAppendingPathComponent:@"FireConfiguration.plist"]

#define PROTEUS3_LOG_DATA		@"PATH"
#define PROTEUS3_STATUS_DATA	[[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Instant Messaging"] stringByAppendingPathComponent:@"Profile"] stringByAppendingPathComponent:@"Status.plist"]

#define PROTEUS4_LOG_DATA		@"PATH"
#define PROTEUS4_STATUS_DATA	[[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Proteus"] stringByAppendingPathComponent:@"Profile"] stringByAppendingPathComponent:@"Status.plist"]

#define GAIM_LOG_DATA			@"PATH"
#define GAIM_STATUS_DATA		@"PATH"

#define ADIUM_LOG_DATA			[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium"]
	


@interface BDClientSupport : NSObject
{
}

@end
