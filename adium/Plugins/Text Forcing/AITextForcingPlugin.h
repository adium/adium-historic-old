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

#define PREF_GROUP_TEXT_FORCING			@"Text Forcing"
#define TEXT_FORCING_DEFAULT_PREFS	@"TextForcingDefaults"

#define KEY_FORCE_FONT				@"Force Font"
#define KEY_FORCE_TEXT_COLOR			@"Force Text Color"
#define KEY_FORCE_BACKGROUND_COLOR		@"Force Background Color"

#define KEY_FORCE_DESIRED_FONT			@"Desired Font"
#define KEY_FORCE_DESIRED_TEXT_COLOR		@"Desired Text Color"
#define KEY_FORCE_DESIRED_BACKGROUND_COLOR	@"Desired Background Color"

@class AITextForcingPreferences;
@protocol AIContentFilter;

@interface AITextForcingPlugin : AIPlugin <AIContentFilter> {
    AITextForcingPreferences	*preferences;

    BOOL		forceFont;
    BOOL		forceText;
    BOOL		forceBackground;
    NSFont		*force_desiredFont;
    NSColor		*force_desiredTextColor;
    NSColor		*force_desiredBackgroundColor;
    
}

@end
