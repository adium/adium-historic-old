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

#import "AIEmoticonPreferences.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIEmoticonsPlugin.h"

#define	EMOTICON_PREF_NIB		@"EmoticonPrefs"
#define EMOTICON_PREF_TITLE		@"Emoticons/Smilies"

@interface AIEmoticonPreferences (PRIVATE)
- (void)configureView;
- (id)initWithOwner:(id)inOwner;
@end

@implementation AIEmoticonPreferences
+ (AIEmoticonPreferences *)emoticonPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//User changed a preference
- (IBAction)preferenceChanged:(id)sender
{
    if(sender == checkBox_enable){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Enable"
                                              group:PREF_GROUP_EMOTICONS];
        
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:EMOTICON_PREF_NIB owner:self];

	//Init NSTableView of Packs
    NSButtonCell	*newCell;
    newCell = [[[NSButtonCell alloc] init] autorelease];
    [newCell setButtonType:NSSwitchButton];
    [newCell setControlSize:NSSmallControlSize];
    [newCell setTitle:@""];
    [newCell setRefusesFirstResponder:YES];
    [[[table_packList tableColumns] objectAtIndex:0] setDataCell:newCell];
	NSLog (@"table_packList: %d", table_packList);

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:EMOTICON_PREF_TITLE categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS] retain];
    [self configureView];
	//[checkList_packList addItemName:@"Test1" state:NSOnState];
	//[checkList_packList addItemName:@"Test2" state:NSOffState];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
	//Enablement
	[checkBox_enable	setState:[[preferenceDict objectForKey:@"Enable"] intValue]];
	
    //Font
    //[self showFont:[[preferenceDict objectForKey:KEY_FORMATTING_FONT] representedFont] inField:textField_desiredFont];

    //Text
    //[colorWell_textColor setColor:[[preferenceDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor]];

    //Background
    //[colorWell_backgroundColor setColor:[[preferenceDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor]];
}

//Emoticon Packs Table View ----------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSLog (@"RowCount request");
    return(2/*[availableUsers count]*/);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
	NSLog (@"CellData request");

    if([identifier compare:@"check"] == 0){
        if(row == 1/*[usersToImport containsObject:[availableUsers objectAtIndex:row]]*/){
            return([NSNumber numberWithBool:YES]);
        }else{
            return([NSNumber numberWithBool:NO]);
        }
    }else{
		if (row == 1)
		{
			return @"First Item :-)";
		}
		else
		{
			return @"Other Item :-)";
		}
		
		
        //return([availableUsers objectAtIndex:row]);
    }
}

 // Received when checkboxes are checked and unchecked
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSLog (@"SetObjectValue request");
    /*NSString	*user = [availableUsers objectAtIndex:row];
    
    if([object intValue] == 0){
        [usersToImport removeObject:user];
    }else{
        [usersToImport addObject:user];
    }    */
}
@end
