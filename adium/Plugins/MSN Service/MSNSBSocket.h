//
//  MSNSBSocket.h
//  Adium
//
//  Created by Colin Barrett on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AISocket;

@interface MSNSBSocket : NSObject 
{
    AISocket 		*socket;		// The connection socket
}

@end
