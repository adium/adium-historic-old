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
- (id)initWithOwner:(id)inOwner plugin:(AIEmoticonsPlugin *)pluginSet;
@end

@implementation AIEmoticonPreferences
+ (AIEmoticonPreferences *)emoticonPreferencesWithOwner:(id)inOwner plugin:(AIEmoticonsPlugin *)pluginSet
{
    return([[[self alloc] initWithOwner:inOwner plugin:pluginSet] autorelease]);
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

// User performed action in table
- (IBAction)tableClicked:(id)sender
{
    int row = [table_packList clickedRow];
    
    NSAttributedString*	about = [[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_ABOUT];
    NSMutableAttributedString     *display = [text_packInfo textStorage];
    
    if (about)
    {
        [display setAttributedString:about];
    }
    else
    {
        [display setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
        //NSLog (@"No about string");
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner plugin:(AIEmoticonsPlugin *)pluginSet
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
	plugin = pluginSet;
	packs = [[NSMutableArray alloc] init];

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
    [[[table_packList tableColumns] objectAtIndex:0] setIdentifier:@"check"];
    [[[table_packList tableColumns] objectAtIndex:1] setIdentifier:@"packname"];
	[table_packList setDataSource:self];

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
	
	//Emoticon Packs
	[plugin allEmoticonPacks:packs];
	[table_packList reloadData];
}

//Emoticon Packs Table View ----------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([packs count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    if([identifier compare:@"check"] == 0){
        //if(row == 0/*[usersToImport containsObject:[availableUsers objectAtIndex:row]]*/){
        //    return([NSNumber numberWithBool:YES]);
        //}else{
        //    return([NSNumber numberWithBool:NO]);
        //}
		return([[[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_PREFS] objectForKey:@"inUse"]);
    }else{
		/*if (row == 0)
		{
			return @"First Item :-)";
		}
		else
		{
			return @"Other Item :-)";
		}*/
		
		return([[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_TITLE]);
        //return([availableUsers objectAtIndex:row]);
    }
}

 // Received when checkboxes are checked and unchecked
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", [[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_SOURCE], [[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_TITLE]];
	NSMutableDictionary*	prefDict = [NSMutableDictionary dictionaryWithDictionary:[[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_PREFS]];
	
	switch ([object intValue])
	{
		case	NSOffState:
			// Turn off selected emoticon-pack
			[prefDict setObject:[NSNumber numberWithInt:NSOffState] forKey:@"inUse"];
			break;
			
		case	NSOnState:
		{	// Turn on selected emoticon-pack
			//Conflict resolution
				// For now, this just turns off the other packs.  Later it will check for individual conflicts
			NSEnumerator	*numer = [packs objectEnumerator];
			NSMutableDictionary	*packDict = nil;
			
			while (packDict = [numer nextObject])
			{
				if ([[[packDict objectForKey:KEY_EMOTICON_PACK_PREFS] objectForKey:@"inUse"] intValue] != NSOffState)
				{
					NSString* curPackKey = [NSString stringWithFormat:@"%@_pack_%@", [packDict objectForKey:KEY_EMOTICON_PACK_SOURCE], [packDict objectForKey:KEY_EMOTICON_PACK_TITLE]];
					
					NSMutableDictionary* tempPrefs = [NSMutableDictionary dictionaryWithDictionary:[packDict objectForKey:KEY_EMOTICON_PACK_PREFS]];
					[tempPrefs setObject:[NSNumber numberWithInt:NSOffState] forKey:@"inUse"];
					
					[[owner preferenceController] setPreference:tempPrefs forKey:curPackKey group:PREF_GROUP_EMOTICONS];
				}
			}
			
			//Action
			[prefDict setObject:[NSNumber numberWithInt:NSOnState] forKey:@"inUse"];
			break;
		}
		case	NSMixedState:
			NSLog (@"Mixed State checkbox in pack list, right after click.");
	}
				
	[[owner preferenceController] setPreference:prefDict forKey:packKey group:PREF_GROUP_EMOTICONS];
	[plugin	loadEmoticonsFromPacks];
	[self configureView];	// Maybe we can take this out later.  I want to make sure the dicts in the emoticon
							// packs are up-to-date.  Right now, we certainly need it.
}
@end
