//
//  CBActionSupportPlugin.h
//  Adium
//
//  Created by Colin Barrett on Tue Jun 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@protocol AIContentFilter;

@interface CBActionSupportPlugin : AIPlugin <AIContentFilter>
{

}
/*
//AIPlugin subclassed methods
- (void)installPlugin;

//AIContentFilter protocol methods
- (void)filterContentObject:(id <AIContentObject>)inObject;
*/
@end
