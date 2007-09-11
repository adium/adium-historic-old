//
//  AIMessageWindow.m
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import "AIMessageWindow.h"
#import "AIClickThroughThemeDocumentButton.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import "AIMessageWindowController.h"
#import "AIInterfaceControllerProtocol.h"

/*!
 * @class AIMessageWindow
 * @brief This AIDockingWindow subclass serves message windows.
 *
 * It overrides the standardWindowButton:forStyleMask: class method to provide
 * AIClickThroughThemeDocumentButton objects for NSWindowDocumentIconButton requests on 10.4 and earlier.
 * Delegate methods in 10.5+ handle what we need.
 */
@implementation AIMessageWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]))
		return nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptedWindowDidClose:) name:NSWindowWillCloseNotification object:nil];
	return self;
}

/*!
 * @brief Return the standard window button for a mask
 *
 * We return AIClickThroughThemeDocumentButton instead of NSThemeDocumentButton to provide
 * click-through dragging behavior on 10.4 and earlier.
 */
+ (NSButton *)standardWindowButton:(NSWindowButton)button forStyleMask:(unsigned int)styleMask
{
	NSButton *standardWindowButton = [super standardWindowButton:button forStyleMask:styleMask];

	if (![NSApp isOnLeopardOrBetter]) {
		if (button == NSWindowDocumentIconButton) {
			[NSKeyedArchiver setClassName:@"AIClickThroughThemeDocumentButton" forClass:[NSThemeDocumentButton class]];
			standardWindowButton = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:standardWindowButton]];
			
			[[standardWindowButton retain] autorelease];
		}
	}
	
	return standardWindowButton;
}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[[NSUniqueIDSpecifier alloc]
		   initWithContainerClassDescription:containerClassDesc
		   containerSpecifier:nil key:@"chatWindows"
		   uniqueID:[NSNumber numberWithInt:[self uniqueID]]] autorelease];
}

- (NSArray *)chats
{
	return [(AIMessageWindowController *)[self windowController] containedChats];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)command
{
	[command suspendExecution];
	rememberedScriptCommand = command;
	
	//get a list of all the chats in this window
	NSArray *chatsInThisWindow = [self chats];
	for (int i=[chatsInThisWindow count]-1;i>=0;i--)
		[[[AIObject sharedAdiumInstance] interfaceController] closeChat:[chatsInThisWindow objectAtIndex:i]];
	return nil;
}
- (void)scriptedWindowDidClose:(NSNotification *)notification
{
	[rememberedScriptCommand resumeExecutionWithResult:nil];
	rememberedScriptCommand = nil;
}
@end
