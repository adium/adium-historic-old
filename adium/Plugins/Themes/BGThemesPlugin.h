//
//  BGThemesPlugin.h
//  Adium
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#import "BGThemesPreferences.h"

#define THEME_ADIUM_DEFAULT		@"Adium Default"

@interface BGThemesPlugin : AIPlugin {
    BGThemesPreferences *themePane;
    NSString *themePath;
}
-(void)saveTheme:(NSMutableDictionary *)saveTheme;
-(void)applyTheme:(NSString *)newThemeName;
-(void)createThemeNamed:(NSString *)newName by:(NSString *)newAuthor version:(NSString *)newVersion;
-(void)saveKey:(NSString *)key group:(NSString *)group toDict:(NSMutableDictionary *)dict;
-(void)applyPreferenceFromKey:(NSString *)key inDict:(NSDictionary *)dict;
@end
