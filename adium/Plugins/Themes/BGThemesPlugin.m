/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "BGThemesPlugin.h"
#import "BGThemeManageView.h"

#define KEY_GROUP_SEPARATOR                     @"_BGTheme_"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define THEME_FOLDER_NAME                       @"Themes"
#define THEME_PATH                              [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:THEME_FOLDER_NAME]

@implementation BGThemesPlugin

- (void)installPlugin
{ 
    // if there is no themes directory, create it
    [[AIObject sharedAdiumInstance] createResourcePathForName:THEME_FOLDER_NAME];
	
    themePane = [[BGThemesPreferences preferencePane] retain];
    [themePane setPlugin:self];
}

-(void)createThemeNamed:(NSString *)newName by:(NSString *)newAuthor version:(NSString *)newVersion
{
    NSArray				*themableKeys;
    NSString			*group;
    NSString			*key;
    NSEnumerator		*keyEnumerator;
    NSMutableDictionary *newTheme = [NSMutableDictionary dictionary];
    NSEnumerator		*enumerator = [[[adium preferenceController] themablePreferences] keyEnumerator];
	
    // set basic attributes of theme
    [newTheme setObject:newName forKey:@"themeName"];
    [newTheme setObject:newAuthor forKey:@"themeAuthor"];
    [newTheme setObject:newVersion forKey:@"themeVersion"];
	
    // build theme from all themable preferences
    while (group = [enumerator nextObject]){
        themableKeys = [[[adium preferenceController] themablePreferences] objectForKey:group]; 
        keyEnumerator = [themableKeys objectEnumerator];
        while (key = [keyEnumerator nextObject]){
            [self saveKey:key group:group toDict:newTheme];
        }
    }
    [self saveTheme:newTheme];
}

-(void)saveTheme:(NSMutableDictionary *)saveTheme
{
    // write a file containing the theme's dictionary to the themes folder   
    NSArray *resourcePaths = [[AIObject sharedAdiumInstance] resourcePathsForName:THEME_FOLDER_NAME];
    if([resourcePaths count]) {
        NSString *savePath = [[resourcePaths objectAtIndex:0] stringByAppendingPathComponent:[[saveTheme objectForKey:@"themeName"] stringByAppendingPathExtension:@"AdiumTheme"]];
        if([saveTheme writeToFile:savePath atomically:YES] == NO)
        {
            NSRunAlertPanel(@"Your theme was not saved",@"Adium was unable to save your theme in the Themes directory. Please try again.",@"OK",nil,nil);
        }
    } else {
        NSRunAlertPanel(@"Your theme was not saved",@"Adium was unable to save your theme in the Themes directory because it was not in the correct location. Please relaunch the Adium Theme preferences and it will attempt to repair this so you may try again.",@"OK",nil,nil);
    }
    [themePane createDone];
}

// ======= efficiency by evands =========
- (void)saveKey:(NSString *)key group:(NSString *)group toDict:(NSMutableDictionary *)dict
{
    [dict setObject:[[adium preferenceController] preferenceForKey:key group:group] forKey:[NSString stringWithFormat:@"%@%@%@",key,KEY_GROUP_SEPARATOR,group]];
}

- (void)applyPreferenceFromKey:(NSString *)key inDict:(NSDictionary *)dict
{
    //Get the components, which should be the key and the group
    NSArray *adiumComponents = [key componentsSeparatedByString:KEY_GROUP_SEPARATOR];

    //Verify we got components - two of them, to be exact
    if(adiumComponents && ([adiumComponents count]==2)){
        [[adium preferenceController] setPreference:[dict objectForKey:key]
											 forKey:[adiumComponents objectAtIndex:0]
											  group:[adiumComponents objectAtIndex:1]];
    }
}
/// ====== end efficiency ================

-(void)applyTheme:(NSString *)newThemeName
{
    // read in the theme dictionary
    NSDictionary	*updateTheme = [NSDictionary dictionaryWithContentsOfFile:newThemeName];
    NSEnumerator	*updateEnum = [updateTheme keyEnumerator];
    NSString		*key;  
	
    // set every preference by key and then adium will update
    [[adium preferenceController] delayPreferenceChangedNotifications:YES];
    while(key = [updateEnum nextObject])
    {
        [self applyPreferenceFromKey:key inDict:updateTheme];
    }
    [[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

@end
