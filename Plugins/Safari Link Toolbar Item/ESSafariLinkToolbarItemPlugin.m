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
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/AIApplescriptAdditions.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/NDRunLoopMessenger.h>

#define SAFARI_LINK_IDENTIFER   @"SafariLink"
#define SAFARI_LINK_SCRIPT_PATH [[NSBundle bundleForClass:[self class]] pathForResource:@"Safari.scpt" ofType:nil]

@interface ESSafariLinkToolbarItemPlugin (PRIVATE)
- (NSString *)_executeSafariLinkScript;
@end

@implementation ESSafariLinkToolbarItemPlugin

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

- (void)uninstallPlugin
{
	[safariLinkScript release]; safariLinkScript = nil;
}

- (IBAction)insertSafariLink:(id)sender
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
    if(responder && [responder isKindOfClass:[NSTextView class]]){
		
		//Run the script in our filter thread to avoid threading conflicts, waiting for a result and then returning it
		NSString	*scriptResult = [[[adium contentController] filterRunLoopMessenger] target:self 
																			   performSelector:@selector(_executeSafariLinkScript)
																					withResult:YES];
		
		//If the script fails, do nothing
		if(scriptResult && [scriptResult length]){
			//Insert the script result - it should have returned HTML, so process it first
			NSAttributedString	*attributedScriptResult;
			NSDictionary		*attributes;
			
			attributedScriptResult = [AIHTMLDecoder decodeHTML:scriptResult];

			attributes = [[(NSTextView *)responder typingAttributes] copy];
			[(NSTextView *)responder insertText:attributedScriptResult];
			if(attributes) [(NSTextView *)responder setTypingAttributes:attributes];
			
			[attributes release];
		}
	}
}

//Execute the script, returning its output
- (NSString *)_executeSafariLinkScript
{
	//Create the NSAppleScript object if necessary
	if (!safariLinkScript){
		safariLinkScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:SAFARI_LINK_SCRIPT_PATH] error:nil];
	}
	
	return([[safariLinkScript executeFunction:@"substitute" withArguments:nil error:nil] stringValue]);
}

@end
