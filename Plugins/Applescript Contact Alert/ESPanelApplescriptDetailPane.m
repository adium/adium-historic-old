//
//  ESPanelApplescriptDetailPane.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Sep 08 2004.
//

#import "ESPanelApplescriptDetailPane.h"
#import "ESApplescriptContactAlertPlugin.h"

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
	scriptPath = nil;
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
}

@end
