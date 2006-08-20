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
- (void)setTitle: (NSString *)title;
- (NSString *)title;
- (void)setIsActiveStatus: (BOOL)activeStatus;
- (BOOL)isActiveStatus;
- (void)setToolTip: (NSString *)tip;
- (NSString *)toolTip;
- (void)setHasSubmenu: (BOOL)submenu;
- (BOOL)hasSubmenu;
- (void)setType: (int)aType;
- (int)type;
- (void)setImage: (NSImage *)image;
- (NSImage *)image;
@end
