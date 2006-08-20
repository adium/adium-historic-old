#import <Cocoa/Cocoa.h>
//#import "JLPresenceProtocol.h"

@class AIAccountMenu, AIStatusMenu, AIAdium, JLPresenceRemote;
//@class JLAdiumDelegate;

// FIXME: We need this defined in a global place like AIAdium.h
#define ADIUM_PRESENCE_BROADCAST				@"AIPresenceBroadcast"

@interface SMDMenu : NSObject 
{
	NSStatusItem	*statusItem;
	NSMenu			*theMenu;
	
	NSImage							*adiumImage;
	NSImage							*adiumHighlightImage;
	NSImage							*adiumOfflineImage;
	NSImage							*adiumOfflineHighlightImage;
	NSImage							*adiumRedImage;
	NSImage							*adiumRedHighlightImage;
	NSDistributedNotificationCenter *notificationCenter;
	
	JLPresenceRemote				*presenceRemote;
}
// FIXME: any of this private API?
- (void)adiumStarted:(NSNotification *)note;
- (void)adiumClosing:(NSNotification *)note;
- (void)drawOfflineMenu;
- (void)drawOnlineMenu;
- (void)removeAllMenuItems;
- (void)quitSMD;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)unviewedContentOn:(NSNotification *)note;
- (void)unviewedContentOff:(NSNotification *)note;
- (void)quitAdium;
- (void)bringAdiumToFront;
- (void)connectToVend;

@end
