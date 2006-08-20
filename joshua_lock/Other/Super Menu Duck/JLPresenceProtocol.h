//
//  JLPresenceRemoteProtocol.h
//  Adium
//
//  Created by Joshua Lock on 20/08/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#define ADIUM_PRESENCE_BROADCAST				@"AIPresenceBroadcast"

@protocol JLPresenceRemoteProtocol
- (void)populateStatusObjects;
- (NSMutableArray *)statusObjectArray;
@end

@protocol JLStatusObjectProtocol
- (NSString *)title;
- (BOOL)isActiveStatus;
- (NSString *)toolTip;
- (BOOL)hasSubmenu;
- (int)type;
@end
