/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>
#import <AIAdium.h>

//Strings
#define AIM_TOC2_PREFERENCE_VIEW	@"AIMTOCPreferenceView"
#define AIM_TOC2_PREFERENCE_TITLE	@"AIM Connection"

//File Names
#define AIM_TOC2_DEFAULT_PREFS 		@"Default Preferences"
#define AIM_TOC2_PREFS 			@"AIM(TOC2)"

//Preference Keys
#define AIM_TOC2_KEY_HOST		@"host"
#define AIM_TOC2_KEY_PORT		@"port"

@class AIServiceType;

@interface AIMTOC2ServicePlugin : AIPlugin <AIServiceController> {
    IBOutlet 	NSView		*view_preferences;
    
    //Preferences
    IBOutlet	NSTextField	*textField_host;
    IBOutlet	NSTextField	*textField_port;

    AIServiceType		*handleServiceType;
}

- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner;
- (AIServiceType *)handleServiceType;
- (IBAction)preferenceChanged:(id)sender;

@end
