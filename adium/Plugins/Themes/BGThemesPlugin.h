/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
