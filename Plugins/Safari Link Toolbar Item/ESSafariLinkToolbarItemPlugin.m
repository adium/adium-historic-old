//
//  ESSafariLinkToolbarItemPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Jul 14 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESSafariLinkToolbarItemPlugin.h"

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
