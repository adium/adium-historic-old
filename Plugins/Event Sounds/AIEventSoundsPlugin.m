/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIEventSoundsPlugin.h"
#import "ESEventSoundAlertDetailPane.h"

#define EVENT_SOUNDS_ALERT_SHORT	AILocalizedString(@"Play a sound",nil)
#define EVENT_SOUNDS_ALERT_LONG		AILocalizedString(@"Play the sound \"%@\"",nil)

#define SOUND_ALERT_IDENTIFIER		@"PlaySound"

@interface AIEventSoundsPlugin (PRIVATE)
- (void)eventNotification:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIEventSoundsPlugin

- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:SOUND_ALERT_IDENTIFIER withHandler:self];
}

- (void)uninstallPlugin
{

}

//Play Sound Alert -----------------------------------------------------------------------------------------------------
#pragma mark Play Sound Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(EVENT_SOUNDS_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*fileName = [[[details objectForKey:KEY_ALERT_SOUND_PATH] lastPathComponent] stringByDeletingPathExtension];
	
	if(fileName && [fileName length]){
		return([NSString stringWithFormat:EVENT_SOUNDS_ALERT_LONG, fileName]);
	}else{
		return(EVENT_SOUNDS_ALERT_SHORT);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"SoundAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESEventSoundAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString	*soundPath = [[details objectForKey:KEY_ALERT_SOUND_PATH] stringByExpandingBundlePath];
	[[adium soundController] playSoundAtPath:soundPath];
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(NO);
}

//Play the sound when the alert is selected
- (void)didSelectAlert:(NSDictionary *)alert
{
	NSString	*soundPath = [[[alert objectForKey:KEY_ACTION_DETAILS] objectForKey:KEY_ALERT_SOUND_PATH] stringByExpandingBundlePath];
	[[adium soundController] playSoundAtPath:soundPath];
}

@end

