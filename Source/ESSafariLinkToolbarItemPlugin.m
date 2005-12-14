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
	CFURLRef	urlToDefaultBrowser = NULL;
	NSString	*browserName = nil;
	NSImage		*browserImage = nil;

	if (LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://google.com"],
							   kLSRolesViewer,
							   NULL /*outAppRef*/,
							   &urlToDefaultBrowser) != kLSApplicationNotFoundErr) {
		NSString	*defaultBrowserName;
		NSString	*defaultBrowserPath;

		defaultBrowserPath = [(NSURL *)urlToDefaultBrowser path];
		defaultBrowserName = [[NSFileManager defaultManager] displayNameAtPath:defaultBrowserPath];

		//Is the default browser supported?
		//XXX FireFox should be supportable, but I can't get the script to work -eds
		NSEnumerator *enumerator = [[NSArray arrayWithObjects:@"Safari",/*@"Firefox",*/@"Omniweb",@"Camino",@"NetNewsWire",nil] objectEnumerator];
		NSString	 *aSupportedBrowser;

		while ((aSupportedBrowser = [enumerator nextObject])) {
			if ([defaultBrowserName rangeOfString:aSupportedBrowser
										  options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
				//Use the name and image provided by the system if possible
				browserName = defaultBrowserName;
				browserImage = [[NSWorkspace sharedWorkspace] iconForFile:defaultBrowserPath];
				break;
			}
		}
	}
	
	if (urlToDefaultBrowser) {
		CFRelease(urlToDefaultBrowser);
	}
	
	if (!browserName || !browserImage) {
		//Fall back on Safari and the image stored within our bundle if necessary
		browserName = @"Safari";
		browserImage = [NSImage imageNamed:@"Safari" forClass:[self class]];
	}	

	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SAFARI_LINK_IDENTIFER
														  label:[NSString stringWithFormat:AILocalizedString(@"%@ Link",nil), browserName]
												   paletteLabel:[NSString stringWithFormat:AILocalizedString(@"Insert %@ Link",nil), browserName]
														toolTip:[NSString stringWithFormat:AILocalizedString(@"Insert link to active page in %@",nil), browserName]
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:browserImage
														 action:@selector(insertSafariLink:)
														   menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Insert a link to the active Safari page into the first responder if it is an NSTextView
 */
- (IBAction)insertSafariLink:(id)sender
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWindow earliestResponderOfClass:[NSTextView class]];
	
	if (earliestTextView) {
		NSTask		*scriptTask;
		NSArray		*applescriptRunnerArguments;
		NSString	*applescriptRunnerPath;
		NSPipe		*standardOutput;

		//Find the path to the ApplescriptRunner application
		applescriptRunnerPath = [[NSBundle mainBundle] pathForResource:@"AdiumApplescriptRunner"
																ofType:nil
														   inDirectory:nil];
		//Set up our task
		scriptTask = [[NSTask alloc] init];
		[scriptTask setLaunchPath:applescriptRunnerPath];
		
		applescriptRunnerArguments = [NSArray arrayWithObjects:
			SAFARI_LINK_SCRIPT_PATH,
			@"substitute",
			AILocalizedString(@"Multiple browsers are open. Please select one link:", "Prompt when more than one web browser is available when inserting a link from the active browser."),
			nil];
		[scriptTask setArguments:applescriptRunnerArguments];
		
		standardOutput = [[NSPipe alloc] init];
		if (standardOutput) {
			//NSPipe can return nil if an error occurs; don't assume success.
			[scriptTask setStandardOutput:standardOutput];
			[scriptTask setEnvironment:[NSDictionary dictionaryWithObject:earliestTextView
																   forKey:@"Text View"]];			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(scriptDidFinish:)
														 name:NSTaskDidTerminateNotification
													   object:scriptTask];
			[scriptTask launch];
			
		} else {
			[scriptTask release];
			NSBeep();
		}
		[standardOutput release];
	}
}

/*
 * @brief A script finished executing
 *
 * @param aNotification The notification, whose object is the NSTask which terminated
 */
- (void)scriptDidFinish:(NSNotification *)aNotification
{
	NSTask				*scriptTask = [aNotification object];
	NSDictionary		*environment = [scriptTask environment];
	id					standardOutput = [scriptTask standardOutput];
	NSTextView			*earliestTextView = [environment objectForKey:@"Text View"];
	NSFileHandle		*output;
	NSString			*scriptResult = nil;
	
	if ([standardOutput isKindOfClass:[NSPipe class]] &&
		(output = [(NSPipe *)standardOutput fileHandleForReading])) {
		//Retrieve the HTML returned by the script via standardOutput
		scriptResult = [[NSString alloc] initWithData:[output readDataToEndOfFile]
											 encoding:NSUTF8StringEncoding];
	}
	
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
		
	} else {
		NSBeep();
		
	}
	
	/* Remove the observer. If we don't, and another NSTask is allocated with the same id as scriptTask, we'll get two
	 * -scriptDidFinish: callbacks when that task terminates. Because this method releases the task, that would be a
	 * double-release error, resulting in a crash.
	 */
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTaskDidTerminateNotification
												  object:scriptTask];
	
	[scriptResult release];
	[scriptTask release];
}

@end
