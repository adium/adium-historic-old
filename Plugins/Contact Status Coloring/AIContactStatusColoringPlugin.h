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

@class AIContactStatusColoringPreferences;

@interface AIContactStatusColoringPlugin : AIPlugin <AIListObjectObserver, AIFlashObserver> {
    AIContactStatusColoringPreferences *preferences;

    NSMutableArray	*flashingListObjectArray;

    BOOL		awayEnabled;
    BOOL		idleEnabled;
    BOOL		signedOffEnabled;
    BOOL		signedOnEnabled;
    BOOL		typingEnabled;
    BOOL		unviewedContentEnabled;
    BOOL		onlineEnabled;
    BOOL		idleAndAwayEnabled;
	BOOL		offlineEnabled;
    
    NSColor		*awayColor;
    NSColor		*idleColor;
    NSColor		*signedOffColor;
    NSColor		*signedOnColor;
    NSColor		*typingColor;
    NSColor		*unviewedContentColor;
    NSColor		*onlineColor;
    NSColor		*idleAndAwayColor;
	NSColor		*offlineColor;
    
    NSColor		*awayInvertedColor;
    NSColor		*idleInvertedColor;
    NSColor		*signedOffInvertedColor;
    NSColor		*signedOnInvertedColor;
    NSColor		*typingInvertedColor;
    NSColor		*unviewedContentInvertedColor;
    NSColor		*onlineInvertedColor;
    NSColor		*idleAndAwayInvertedColor;
	NSColor		*offlineInvertedColor;
	
    NSColor		*awayLabelColor;
    NSColor		*idleLabelColor;
    NSColor		*signedOffLabelColor;
    NSColor		*signedOnLabelColor;
    NSColor		*typingLabelColor;
    NSColor		*unviewedContentLabelColor;
    NSColor		*onlineLabelColor;
    NSColor		*idleAndAwayLabelColor;
	NSColor		*offlineLabelColor;
	
    float		alpha;
	float		offlineOpacity;
}

@end
