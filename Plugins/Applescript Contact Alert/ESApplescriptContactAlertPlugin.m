//
//  ESApplescriptContactAlertPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Sep 08 2004.
//

#import "ESApplescriptContactAlertPlugin.h"
#import "ESPanelApplescriptDetailPane.h"

#define APPLESCRIPT_ALERT_SHORT AILocalizedString(@"Run an Applescript",nil)
#define APPLESCRIPT_ALERT_LONG AILocalizedString(@"Run the Applescript \"%@\"",nil)

@implementation ESApplescriptContactAlertPlugin

- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:APPLESCRIPT_CONTACT_ALERT_IDENTIFIER withHandler:self];
}

//Run Applescript Alert -------------------------------------------------------------------------------------------------
#pragma mark Run Applescript Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(APPLESCRIPT_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*scriptName = [[[details objectForKey:KEY_APPLESCRIPT_TO_RUN] lastPathComponent] stringByDeletingPathExtension];
	
	if(scriptName && [scriptName length]){
		return([NSString stringWithFormat:APPLESCRIPT_ALERT_LONG, scriptName]);
	}else{
		return(APPLESCRIPT_ALERT_SHORT);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"ApplescriptAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESPanelApplescriptDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSURL 			*scriptURL;
	NSAppleScript   *script;
	
	scriptURL = [NSURL fileURLWithPath:[details objectForKey:KEY_APPLESCRIPT_TO_RUN]];
	script = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil];
	
	[script executeAndReturnError:nil];
	[script release];
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(YES);
}

@end
