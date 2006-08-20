#import <Cocoa/Cocoa.h>

@class AIAccountMenu, AIStatusMenu, AIAdium;
@protocol JLPresenceRemoteProtocol;

// FIXME: We should probably define this in a global place like AIAdium.h
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
	
	BOOL							adiumIsRunning;
	id<JLPresenceRemoteProtocol>	presenceRemote;
}
// FIXME: any of this private API?
- (void)adiumStarted:(NSNotification *)note;
- (void)adiumClosing:(NSNotification *)note;
- (void)drawOfflineMenu;
- (void)drawOnlineMenu;
- (void)removeAllMenuItems;
- (void)quitSMD;
- (void)unviewedContentOn:(NSNotification *)note;
- (void)unviewedContentOff:(NSNotification *)note;
- (void)quitAdium;
- (void)bringAdiumToFront;
- (void)connectToVend;

@end
