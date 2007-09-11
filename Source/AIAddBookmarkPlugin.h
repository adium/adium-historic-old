//
//  AIAddBookmarkPlugin.h
//  Adium
//
//  Created by Erik Beerepoot on 30/07/07.
//  Copyright 2007 Adium. GPL Licensed.
//

#import <Cocoa/Cocoa.h>
#import <AIBookmarkController.h>
#import <Adium/AIPlugin.h>
@interface AIAddBookmarkPlugin : AIPlugin {
		id			delegate;
		AIBookmarkController *bookmarkController;
}

-(void)installPlugin;
-(void)uninstallPlugin;
-(void)setDelegate:(id)newDelegate;
-(id)delegate;
@end
