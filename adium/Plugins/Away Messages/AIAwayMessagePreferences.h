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

@class AIAlternatingRowOutlineView;

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT			@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR		@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"
#define KEY_FORMATTING_SUBBACKGROUND_COLOR	@"Default SubBackground Color"

@interface AIAwayMessagePreferences : AIObject {
    IBOutlet	NSView				*view_prefView;
    IBOutlet	AIAlternatingRowOutlineView	*outlineView_aways;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSTextView			*textView_message;
    IBOutlet	NSTextView			*textView_autoresponse;
    IBOutlet	AIAutoScrollView	*scrollView_awayList;
    IBOutlet	AIAutoScrollView	*scrollView_awayText;

    NSMutableArray					*awayMessageArray;
    NSMutableDictionary				*displayedMessage;

    NSMutableDictionary				*dragItem;
	
	NSDictionary					*defaultAttributes;
}

+ (AIAwayMessagePreferences *)awayMessagePreferences;
- (IBAction)deleteAwayMessage:(id)sender;
- (IBAction)newAwayMessage:(id)sender;

@end
