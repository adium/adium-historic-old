//
//  BGThemesPlugin.m
//  Adium
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//
#import "BGThemesPlugin.h"
#import "BGThemesPreferences.h"
#import "BGThemeManageView.h"

#define KEY_GROUP_SEPARATOR @"_BGTheme_"
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define THEME_FOLDER_NAME @"Themes"
#define THEME_PATH  [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:THEME_FOLDER_NAME]

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
    NSMutableDictionary *newTheme = [[NSMutableDictionary alloc] init];
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
        [saveTheme writeToFile:savePath atomically:YES];
#warning we should provide some kind of alert if this write fails. --boredzo
    } else {
        NSBeep();
        NSLog(@"Could not find a folder in which to save the file\n");
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
    if (adiumComponents && ([adiumComponents count]==2)){
        [[adium preferenceController] setPreference:[dict objectForKey:key] forKey:[adiumComponents objectAtIndex:0] group:[adiumComponents objectAtIndex:1]];
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
