//
//  CBContactCountingDisplayPlugin.h
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface CBContactCountingDisplayPlugin : AIPlugin 
{

}
- (void)installPlugin;
- (void)uninstallPlugin;

- (void)preferencesChanged:(NSNotification *)notification;
- (void)contactsChanged:(NSNotification *)notification;
@end
