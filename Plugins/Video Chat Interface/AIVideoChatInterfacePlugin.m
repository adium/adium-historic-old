//
//  AIVideoChatInterfacePlugin.m
//  Adium
//
//  Created by Adam Iser on 12/4/04.
//

#import "AIVideoChatInterfacePlugin.h"
//#import "AIVideoChatWindowController.h"
#import "AILocalVideoWindowController.h"

@implementation AIVideoChatInterfacePlugin

- (void)installPlugin
{
	NSMenuItem	*menuItem;
	
	//View my webcam menu
	menuItem = [[NSMenuItem alloc] initWithTitle:@"My Webcam"
										  target:self 
										  action:@selector(openSelfVideo:)
								   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Window_Auxiliary];
	
	
	
	//Observe video chat creation and destruction
//	[[adium notificationCenter] addObserver:self
//								   selector:@selector(videoChatDidOpen:)
//									   name:AIVideoChatDidOpenNotification
//									 object:nil];
//	[[adium notificationCenter] addObserver:self
//								   selector:@selector(videoChatWillClose:)
//									   name:AIVideoChatWillCloseNotification
//									 object:nil];
}

- (void)openSelfVideo:(id)sender
{
	[[AILocalVideoWindowController showLocalVideoWindow] showWindow:nil];
}

//- (void)videoChatDidOpen:(NSNotification *)notification
//{
//	AIVideoChatWindowController	*window;
//	NSLog(@"Video chat open");
//	
//	//
//	window = [[AIVideoChatWindowController windowForVideoChat:[notification object]] retain];
//	[window showWindow:nil];
//}
//
//- (void)videoChatDidClose:(NSNotification *)notification
//{
//	NSLog(@"Video chat close");
//}

@end
