//
//  AIMSNServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIAdium.h>

@class AIServiceType;

@interface AIMSNServicePlugin : AIPlugin <AIServiceController>
{
    AIServiceType *handleServiceType;
}
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner;
- (AIServiceType *)handleServiceType;
@end
