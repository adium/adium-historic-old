//
//  AIActionDetailsPane.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIActionDetailsPane.h"


@implementation AIActionDetailsPane

//Return a new action details pane
+ (AIActionDetailsPane *)actionDetailsPane
{
    return([[[self alloc] init] autorelease]);
}

//Return a new preference pane, passing plugin
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin
{
    return([[[self alloc] initForPlugin:inPlugin] autorelease]);
}

//For subclasses -------------------------------------------------------------------------------
//
- (void)configureForActionDetails:(NSDictionary *)inDetails
{
	
}

//
- (NSDictionary *)actionDetails
{
	return(nil);
}

@end
