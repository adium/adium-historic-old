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

#import "ESPanelApplescriptDetailPane.h"
#import "ESApplescriptContactAlertPlugin.h"
#import <Adium/AILocalizationTextField.h>
#import <Adium/AILocalizationButton.h>

@interface ESPanelApplescriptDetailPane (PRIVATE)
- (void)setScriptPath:(NSString *)inPath;
@end

@implementation ESPanelApplescriptDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"ApplescriptContactAlert");    
}


//Configure the detail view
- (void)viewDidLoad
{
	[super viewDidLoad];

	scriptPath = nil;
	
	[label_applescript setStringValue:AILocalizedString(@"Applescript:",nil)];
	[button_browse setTitle:AILocalizedString(@"Browse...",nil)];
}

//
- (void)viewWillClose
{
	[scriptPath release]; scriptPath = nil;
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	[self setScriptPath:[inDetails objectForKey:KEY_APPLESCRIPT_TO_RUN]];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	if(scriptPath){
		return([NSDictionary dictionaryWithObject:scriptPath forKey:KEY_APPLESCRIPT_TO_RUN]);
	}else{
		return(nil);
	}
}

- (IBAction)chooseFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:AILocalizedString(@"Select an Applescript",nil)];
	
	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"applescript",@"scptd",@"scpt",nil]] == NSOKButton) {
		[self setScriptPath:[openPanel filename]];
	}
}

- (void)setScriptPath:(NSString *)inPath
{
	NSString	*scriptName;
	
	[scriptPath release];
	scriptPath = [inPath retain];
	
	//Update the display for this name
	scriptName = [[scriptPath lastPathComponent] stringByDeletingPathExtension];
	[textField_scriptName setStringValue:(scriptName ? scriptName : @"")];
	
	[self detailsForHeaderChanged];
}

@end
