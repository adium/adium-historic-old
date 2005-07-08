/*
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "AIToolbarController.h"
#import "ESSafariLinkToolbarItemPlugin.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIAppleScriptAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/NDRunLoopMessenger.h>

#define SAFARI_LINK_IDENTIFER	@"SafariLink"
#define SAFARI_LINK_SCRIPT_PATH	[[NSBundle bundleForClass:[self class]] pathForResource:@"Safari.scpt" ofType:nil]

@interface ESSafariLinkToolbarItemPlugin (PRIVATE)
- (NSString *)_executeSafariLinkScript;
@end

/*!
 * @class ESSafariLinkToolbarItemPlugin
 * @brief Component to add a toolbar item which inserts a link to the active Safari web page
 */
@implementation ESSafariLinkToolbarItemPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	safariLinkScript = nil;

	//SafariLink
	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SAFARI_LINK_IDENTIFER
														  label:AILocalizedString(@"Safari Link",nil)
												   paletteLabel:AILocalizedString(@"Insert Safari Link",nil)
														toolTip:AILocalizedString(@"Insert link to active page in Safari",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"Safari" forClass:[self class]]
														 action:@selector(insertSafariLink:)
														   menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[safariLinkScript release]; safariLinkScript = nil;
	[super dealloc];
}

/*!
 * @brief Insert a link to the active Safari page into the first responder if it is an NSTextView
 */
- (IBAction)insertSafariLink:(id)sender
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWindow earliestResponderOfClass:[NSTextView class]];
	
	if (earliestTextView) {
		NSTask			*scriptTask;
		NSMutableArray	*applescriptRunnerArguments = [NSArray arrayWithObjects:SAFARI_LINK_SCRIPT_PATH, @"substitute", nil];
		NSString		*applescriptRunnerPath;
		NSPipe			*standardOuptut = [NSPipe pipe];
		NSString		*scriptResult;

		//Find the path to the ApplescriptRunner application
		applescriptRunnerPath = [[NSBundle mainBundle] pathForResource:@"AdiumApplescriptRunner"
																ofType:nil
														   inDirectory:nil];
		//Set up our task
		scriptTask = [[NSTask alloc] init];
		[scriptTask setLaunchPath:applescriptRunnerPath];
		[scriptTask setArguments:applescriptRunnerArguments];
		[scriptTask setStandardOutput:standardOuptut];

		//Launch, then block until it's finished
		[scriptTask launch];
		[scriptTask waitUntilExit];

		//Retrieve the HTML returned by the script via standardOutput
		scriptResult = [[NSString alloc] initWithData:[[standardOuptut fileHandleForReading] readDataToEndOfFile]
											 encoding:NSUTF8StringEncoding];

		//If the script returns nil or fails, do nothing
		if (scriptResult && [scriptResult length]) {
			//Insert the script result - it should have returned an HTML link, so process it first
			NSAttributedString	*attributedScriptResult;
			NSDictionary		*attributes;

			attributedScriptResult = [AIHTMLDecoder decodeHTML:scriptResult];

			attributes = [[earliestTextView typingAttributes] copy];
			[earliestTextView insertText:attributedScriptResult];
			if (attributes) [earliestTextView setTypingAttributes:attributes];
			[attributes release];
		}

		[scriptResult release];
		[scriptTask release];
	}
}

@end
