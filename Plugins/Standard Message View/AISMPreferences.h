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

@class JVFontPreviewField;

@interface AISMPreferences : AIPreferencePane {

    IBOutlet    NSButton        *checkBox_showUserIcons;
    IBOutlet    NSButton        *checkBox_combineMessages;
    
    IBOutlet    NSButton        *checkBox_ignoreTextStyles;
	
    IBOutlet	JVFontPreviewField          *textField_desiredFont;
    IBOutlet	NSButton                    *button_setPrefixFont;
    
    IBOutlet    NSPopUpButton   *popUp_timeStamps;
    IBOutlet    NSPopUpButton   *popUp_prefixFormat;
	IBOutlet	NSPopUpButton   *popUp_messageColoring;
	
	
	// Custom Colors sheet	
	IBOutlet	NSWindow		*window_customStyle;
	
	IBOutlet	NSButton		*button_saveCustom;
	IBOutlet	NSButton		*button_cancelCustom;
	
	IBOutlet	NSColorWell		*colorWell_incomingBackground;
	IBOutlet	NSColorWell		*colorWell_incomingHeader;
	IBOutlet	NSColorWell		*colorWell_outgoingBackground;
	IBOutlet	NSColorWell		*colorWell_outgoingHeader;
	
	//IBOutlet	NSTextField		*textField_customName;
    
}

@end
