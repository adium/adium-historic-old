//
//  AIWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Dec 14 2003.
//

#import "AIWindowController.h"

@implementation AIWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    adium = [AIObject sharedAdiumInstance];
    return([super initWithWindowNibName:windowNibName]);
}

//Custom window frame saving code for Adium's silly multiple-user system
- (void)windowDidLoad
{
	NSString	*key = [self adiumFrameAutosaveName];

	if(key){
		NSString	*frameString = [[adium preferenceController] preferenceForKey:key
																			group:PREF_GROUP_WINDOW_POSITIONS];
		
		if(frameString){
			NSRect		windowFrame = NSRectFromString(frameString);
			NSSize		minSize = [[self window] minSize];
			NSSize		maxSize = [[self window] maxSize];
			
			//Respect the min and max sizes
			if(windowFrame.size.width < minSize.width) windowFrame.size.width = minSize.width;
			if(windowFrame.size.height < minSize.height) windowFrame.size.height = minSize.height;
			if(windowFrame.size.width > maxSize.width) windowFrame.size.width = maxSize.width;
			if(windowFrame.size.height > maxSize.height) windowFrame.size.height = maxSize.height;

			//Don't allow the window to shrink smaller than its toolbar
			NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
															   styleMask:[[self window] styleMask]];
			if(contentFrame.size.height < [[self window] toolbarHeight]){
				windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
			}

			//
			[[self window] setFrame:windowFrame display:NO];
		}
	}
}

- (BOOL)windowShouldClose:(id)sender
{
	NSString	*key = [self adiumFrameAutosaveName];

 	if(key){
		[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
											 forKey:key
											  group:PREF_GROUP_WINDOW_POSITIONS];
	}
	
	return(YES);
}

- (NSString *)adiumFrameAutosaveName
{
	return(nil);
}
	
@end
