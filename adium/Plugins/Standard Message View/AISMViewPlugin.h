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

@protocol AIMessageViewController;
@class AISMPreferences, ESSMAdvancedPreferences;

#define PREF_GROUP_STANDARD_MESSAGE_DISPLAY	@"Message Display"
#define SMV_DEFAULT_PREFS					@"SMVDefaults"

#define KEY_SMV_SHOW_USER_ICONS                 @"Show icons"
#define	KEY_SMV_TIME_STAMP_FORMAT		@"Time Stamp"
#define	KEY_SMV_PREFIX_INCOMING			@"Prefix Incoming"
#define	KEY_SMV_PREFIX_OUTGOING			@"Prefix Outgoing"
#define	KEY_SMV_COMBINE_MESSAGES		@"Combine Messages"
#define KEY_SMV_COMBINE_MESSAGES_INDENT         @"Combine Messeages HeadIndent"
#define	KEY_SMV_IGNORE_TEXT_STYLES		@"Ignore Text Styles"


//Old?
#define	KEY_SMV_PREFIX_FONT			@"Prefix Font"
#define	KEY_SMV_SHOW_TIME_STAMPS		@"Show Time Stamps"
#define	KEY_SMV_SHOW_TIME_SECONDS		@"Show Seconds"
#define KEY_SMV_SHOW_AMPM                       @"Show AM-PM"
#define	KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS	@"Hide Duplicate Times"
#define	KEY_SMV_SHOW_PREFIX			@"Show Prefix"
#define	KEY_SMV_HIDE_DUPLICATE_PREFIX		@"Hide Duplicate Prefixes"
#define	KEY_SMV_INCOMING_PREFIX_COLOR		@"Incoming Prefix Color"
#define	KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR	@"Incoming Prefix Light Color"
#define	KEY_SMV_INCOMING_PREFIX_COLOR_NAME	@"Incoming Prefix Color Name"
#define	KEY_SMV_OUTGOING_PREFIX_COLOR		@"Outgoing Prefix Color"
#define	KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR	@"Outgoing Prefix Light Color"
#define	KEY_SMV_OUTGOING_PREFIX_COLOR_NAME	@"Outgoing Prefix Color Name"
#define	KEY_SMV_DISPLAY_GRID_LINES		@"Show GridLines"
#define	KEY_SMV_GRID_DARKNESS			@"GridLine Darkness"
#define	KEY_SMV_DISPLAY_SENDER_GRADIENT		@"Show Sender Gradient"
#define	KEY_SMV_SENDER_GRADIENT_DARKNESS	@"Sender Gradient Darkness"
#define	KEY_SMV_TIME_STAMP_FORMAT_SECONDS	@"Time Stamp Seconds"

@interface AISMViewPlugin : AIPlugin <AIMessageViewPlugin> {
    NSMutableArray		*controllerArray;

    AISMPreferences		*preferences;
    ESSMAdvancedPreferences     *advancedPreferences;
}

@end
