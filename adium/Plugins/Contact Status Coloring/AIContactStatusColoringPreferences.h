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

@interface AIContactStatusColoringPreferences : NSObject {
    AIAdium			*owner;

    NSDictionary		*preferenceDict;

    IBOutlet	NSView			*view_prefView;
    
    IBOutlet	NSColorWell		*colorWell_signedOff;
    IBOutlet	NSColorWell		*colorWell_signedOn;
    IBOutlet	NSColorWell		*colorWell_online;
    IBOutlet	NSColorWell		*colorWell_away;
    IBOutlet	NSColorWell		*colorWell_idle;
    IBOutlet	NSColorWell		*colorWell_idleAway;
    IBOutlet	NSColorWell		*colorWell_openTab;
    IBOutlet	NSColorWell		*colorWell_typing;
    IBOutlet	NSColorWell		*colorWell_unviewedContent;
    IBOutlet	NSColorWell		*colorWell_warning;

    IBOutlet	NSColorWell		*colorWell_signedOffInverted;
    IBOutlet	NSColorWell		*colorWell_signedOnInverted;
    IBOutlet	NSColorWell		*colorWell_onlineInverted;
    IBOutlet	NSColorWell		*colorWell_awayInverted;
    IBOutlet	NSColorWell		*colorWell_idleInverted;
    IBOutlet	NSColorWell		*colorWell_idleAwayInverted;
    IBOutlet	NSColorWell		*colorWell_openTabInverted;
    IBOutlet	NSColorWell		*colorWell_typingInverted;
    IBOutlet	NSColorWell		*colorWell_unviewedContentInverted;
    IBOutlet	NSColorWell		*colorWell_warningInverted;
}

+ (AIContactStatusColoringPreferences *)contactStatusColoringPreferencesWithOwner:(id)inOwner;
- (IBAction)changePreference:(id)sender;

@end
