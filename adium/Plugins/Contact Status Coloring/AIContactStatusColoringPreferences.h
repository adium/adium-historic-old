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

@interface AIContactStatusColoringPreferences : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_signedOff;
    IBOutlet	NSColorWell	*colorWell_signedOff;
    IBOutlet	NSColorWell	*colorWell_signedOffLabel;

    IBOutlet	NSButton	*checkBox_signedOn;
    IBOutlet	NSColorWell	*colorWell_signedOn;
    IBOutlet	NSColorWell	*colorWell_signedOnLabel;

    IBOutlet	NSButton	*checkBox_away;
    IBOutlet	NSColorWell	*colorWell_away;
    IBOutlet	NSColorWell	*colorWell_awayLabel;

    IBOutlet	NSButton	*checkBox_idle;
    IBOutlet	NSColorWell	*colorWell_idle;
    IBOutlet	NSColorWell	*colorWell_idleLabel;

    IBOutlet	NSButton	*checkBox_typing;
    IBOutlet	NSColorWell	*colorWell_typing;
    IBOutlet	NSColorWell	*colorWell_typingLabel;

    IBOutlet	NSButton	*checkBox_unviewedContent;
    IBOutlet	NSColorWell	*colorWell_unviewedContent;
    IBOutlet	NSColorWell	*colorWell_unviewedContentLabel;

    IBOutlet	NSButton	*checkBox_online;
    IBOutlet	NSColorWell	*colorWell_online;
    IBOutlet	NSColorWell	*colorWell_onlineLabel;

    IBOutlet	NSButton	*checkBox_idleAndAway;
    IBOutlet	NSColorWell	*colorWell_idleAndAway;
    IBOutlet	NSColorWell	*colorWell_idleAndAwayLabel;
	
    IBOutlet	NSButton	*checkBox_offline;
    IBOutlet	NSColorWell	*colorWell_offline;
    IBOutlet	NSColorWell	*colorWell_offlineLabel;
}

@end
