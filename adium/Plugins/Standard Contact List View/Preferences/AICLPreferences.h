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

@interface AICLPreferences : AIPreferencePane {
    IBOutlet	NSView			*view_prefViewGeneral;
    IBOutlet	NSButton		*button_setFont;
    IBOutlet	NSTextField		*textField_fontName;
    IBOutlet	NSButton		*checkBox_alternatingGrid;
    IBOutlet	NSButton		*checkBox_showLabels;
	IBOutlet	NSButton		*checkBox_tooltips;
    IBOutlet	NSColorWell		*colorWell_contact;
    IBOutlet	NSColorWell		*colorWell_background;
    IBOutlet	NSColorWell		*colorWell_grid;
}

- (IBAction)spawnLayout:(id)sender;

@end
