//
//  MSNAccount.h
//  Adium
//
//  Created by Colin Barrett on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AISocket, AIGroup;

@interface MSNAccount : AIAccount <AIAccount_Content, AIAccount_Handles>
{
    AISocket 		*socket;		// The connection socket
    int			connectionPhase;	// Offline/Connecting/Online/Disconnecting

    NSString		*screenName;		// Current signed on screenName
    NSString		*password;		// Current signed on password
}

@end
