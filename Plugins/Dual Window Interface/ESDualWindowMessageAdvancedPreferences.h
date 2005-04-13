/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIPreferencePane.h>

#define PREF_GROUP_WEBKIT_MESSAGE_DISPLAY		@"WebKit Message Display"
#define WEBKIT_DEFAULT_PREFS					@"WebKit Defaults"

#define KEY_WEBKIT_NAME_FORMAT					@"Name Format"
#define KEY_WEBKIT_USE_NAME_FORMAT				@"Use Custom Name Format"
#define	KEY_WEBKIT_TIME_STAMP_FORMAT			@"Time Stamp"
#define KEY_WEBKIT_MIN_FONT_SIZE				@"Min Font Size"

@interface ESDualWindowMessageAdvancedPreferences : AIPreferencePane {
    IBOutlet	NSButton		*autohide_tabBar;
    IBOutlet    NSButton		*checkBox_allowInactiveClosing;
	
	IBOutlet	NSButton		*checkBox_customNameFormatting;
	IBOutlet	NSPopUpButton   *popUp_nameFormat;
	
	IBOutlet	NSPopUpButton	*popUp_minimumFontSize;
	IBOutlet	NSPopUpButton	*popUp_timeStampFormat;
	
	IBOutlet	NSButton		*checkBox_hide;
	IBOutlet	NSPopUpButton	*popUp_windowPosition;
}

@end
