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
#import "BGThemeManageView.h"

@interface BGThemesPreferences : AIPreferencePane {
    // create
    IBOutlet NSWindow *createWindow;
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *authorField;
    IBOutlet NSTextField *versionField;
    IBOutlet AIPlasticButton *createButton;
    IBOutlet AIPlasticButton *removeButton;
    // manage
    IBOutlet BGThemeManageView *themesList;
    // other
    NSMenu *themeMenu;
    id themePlugin;
}
-(IBAction)createAction:(id)sender;
-(IBAction)createTheme:(id)sender;
-(void)setPlugin:(id)newPlugin;
-(void)createDone;
@end
