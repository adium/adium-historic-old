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

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AISMPreferences : NSObject {
    AIAdium			*owner;

    //Prefixes
    IBOutlet	NSView		*view_prefixes;
    IBOutlet	NSButton	*button_setPrefixFont;
    IBOutlet	NSTextField	*textField_prefixFontName;
    IBOutlet	NSButton	*checkBox_hideDuplicatePrefixes;
    IBOutlet	NSPopUpButton	*popUp_incomingPrefix;
    IBOutlet	NSPopUpButton	*popUp_outgoingPrefix;
    
    //TimeStamps
    IBOutlet	NSView		*view_timeStamps;
    IBOutlet	NSButton	*checkBox_showTimeStamps;
    IBOutlet	NSButton	*checkBox_hideDuplicateTimeStamps;
    IBOutlet	NSButton	*checkBox_showSeconds;
    
    //Gridding
    IBOutlet	NSView		*view_gridding;
    IBOutlet	NSButton	*checkBox_displayGridlines;
    IBOutlet	NSSlider	*slider_gridDarkness;
    IBOutlet	NSButton	*checkBox_senderGradient;
    IBOutlet	NSSlider	*slider_gradientDarkness;

    //Alias
    IBOutlet	NSView		*view_alias;
    IBOutlet	NSTextField	*textField_alias;
    
    
    NSDictionary		*prefixColors;

    NSDictionary		*preferenceDict;
}

+ (AISMPreferences *)messageViewPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
