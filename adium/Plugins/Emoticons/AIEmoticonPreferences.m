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
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"

#define	EMOTICON_PREF_NIB		@"EmoticonPrefs"
#define EMOTICON_PREF_TITLE		@"Emoticons/Smilies"

@interface AIEmoticonPreferences (PRIVATE)
- (void)configureView;
- (id)initWithOwner:(id)inOwner plugin:(AIEmoticonsPlugin *)pluginSet;
- (void)getCurrentEmoticons;
- (void)enableIndividualEmoticonControls:(BOOL)enable;
- (void)populateIndividualEmoticonControls;
- (void)initTable:(NSTableView *)table	withEmoticons:(NSArray *)emoticons;
- (void)selectEmoticon:(id)sender;
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
    }else if (sender == checkBox_enableEmoticon){
        if (emoticonIsSelected  &&  selectedEmoticon < [curEmoticons count]) {
            NSMutableDictionary	*emoDict = [curEmoticons objectAtIndex:selectedEmoticon];
            if (emoDict){
                id		emoID = [emoDict objectForKey:@"Emoticon"];
                AIEmoticonPack	*emoPack = [emoDict objectForKey:@"Pack"];
                
                [emoPack setEmoticon:emoID enabled:([sender state] == NSOnState)];

                //[table_curEmoticons display];
                [self populateIndividualEmoticonControls];
                [table_curEmoticons setNeedsDisplay:YES];
            }
        }
    }
}

// User performed action in table
- (IBAction)tableClicked:(id)sender
{
    int row = [table_packList clickedRow];

    NSAttributedString*	about = [[packs objectAtIndex:row] about];
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

- (void)dealloc
{
    [packs release];
    if (curEmoticons)
        [curEmoticons release];
    [owner release];
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner plugin:(AIEmoticonsPlugin *)pluginSet
{
    //Init
    [super init];
    owner = [inOwner retain];
    plugin = pluginSet;
    packs = [[NSMutableArray alloc] init];
    curEmoticons = nil;
    emoticonIsSelected = false;

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Emoticons withDelegate:self label:EMOTICON_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:EMOTICON_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [plugin loadEmoticonsIfNecessary:NO]; //let the plugin unload its emoticons if it doesn't seem them anymore (if parsing is disabled)
    [view_prefView release]; view_prefView = nil;
}

//Configures our view for the current preferences
- (void)configureView
{
    [plugin loadEmoticonsIfNecessary:YES]; //if the plugin hasn't already loaded emoticons (because parsing is disabled) load them now
    
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_EMOTICONS];

    //Enablement
    [checkBox_enable setState:[[preferenceDict objectForKey:@"Enable"] intValue]];
    
    //Init NSTableView of Packs
    NSButtonCell	*newCell = [[[NSButtonCell alloc] init] autorelease];

    [newCell setButtonType:NSSwitchButton];
    [newCell setControlSize:NSSmallControlSize];
    [newCell setTitle:@""];
    [newCell setRefusesFirstResponder:YES];

    [[[table_packList tableColumns] objectAtIndex:0] setDataCell:newCell];
    [[[table_packList tableColumns] objectAtIndex:0] setIdentifier:@"check"];
    [[[table_packList tableColumns] objectAtIndex:1] setIdentifier:@"packname"];

    [table_packList setDataSource:self];
    [table_curEmoticonTexts setDataSource:self];
    
    //Emoticon Packs
    [plugin allEmoticonPacks:packs];
    [table_packList reloadData];
    
    //Init NSTableView of current emoticons
    [self getCurrentEmoticons];
    [table_curEmoticons setDataSource:self];
    [table_curEmoticons setDelegate:self];
    [table_curEmoticons setTarget:self];
    [table_curEmoticons setAction:@selector(selectEmoticon:)];
    [self initTable:table_curEmoticons  withEmoticons:curEmoticons];
    
    // Set up controls for currently selected emoticon
    [self populateIndividualEmoticonControls];
}

- (void)getCurrentEmoticons
{
    // Prepare //
    // Prep emoticon array
    if (curEmoticons)
        [curEmoticons release];
        
    curEmoticons = [[NSMutableArray array] retain];
    
    // Check pack array
    if ([packs count] == 0)
        [plugin allEmoticonPacks:packs];
    
    
    // Look through all packs for emoticons	//
    NSEnumerator	*enumerator = [packs objectEnumerator];
    AIEmoticonPack	*curPack = nil;
    
    while (curPack = [enumerator nextObject]) {
        int packState = [curPack isEnabled];
        
        if (packState != NSOffState) {
            [curPack verifyEmoticons];
            
            NSEnumerator	*emoEnumerator = [curPack emoticonEnumerator];
            id				emoID = nil;

            while (emoID = [emoEnumerator nextObject]) {
                [curEmoticons addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[curPack emoticonImage:emoID], @"Image", emoID, @"Emoticon", curPack, @"Pack", [NSNumber numberWithInt:[curPack emoticonEnabled:emoID]], @"Enabled", nil]];
            }
            
        }
    }
        
    /*curEmoticons = [[plugin getEmoticons] retain];
    
    // Stopgap measure: until we write the emoticon-gathering right,
    // go through and remove duplicates from the array
    NSEnumerator	*enumerator = [curEmoticons objectEnumerator];
    AIEmoticon		*emoticon = nil;
    NSMutableArray	*pathsUsed = [NSMutableArray array],
                    *emoticonsToRemove = [NSMutableArray array];
    while (emoticon = [enumerator nextObject]) {
        if ([pathsUsed indexOfObject:[emoticon path]] != NSNotFound) {
            [emoticonsToRemove addObject:emoticon];
        } else {
            [pathsUsed addObject:[emoticon path]];
        }
    }
    
    //NSLog (@"Removing %d emoticons from an array of %d.", [emoticonsToRemove count], [curEmoticons count]);
    enumerator = [emoticonsToRemove objectEnumerator];
    while (emoticon = [enumerator nextObject]) {
        [curEmoticons removeObject:emoticon];
    }*/
}

- (void)enableIndividualEmoticonControls:(BOOL)enable
{
    [image_emoticonImage setEnabled:enable];
    [checkBox_enableEmoticon setEnabled:enable];
    [table_curEmoticonTexts setEnabled:enable];

    [text_emoticonName setStringValue:@""];
    [text_emoticonPack setStringValue:@""];
}

- (void)populateIndividualEmoticonControls
{
    if (emoticonIsSelected){
        [self enableIndividualEmoticonControls:TRUE];

        NSMutableDictionary		*emoDict = [curEmoticons objectAtIndex:selectedEmoticon];
        id						emoID = [emoDict objectForKey:@"Emoticon"];
        AIEmoticonPack			*emoPack = [emoDict objectForKey:@"Pack"];

        if (emoDict && emoPack) {
            [image_emoticonImage  setImage:[emoDict objectForKey:@"Image"]];
            //[text_emoticonName	setStringValue:[emoPack emoticonName:emoID]];
            //[text_emoticonPack  setStringValue:[NSString stringWithFormat:@"from pack %@", [emoPack title]]];
            [text_emoticonName  setStringValue:[NSString stringWithFormat:@"\"%@\" from pack \"%@\"", [emoPack emoticonName:emoID], [emoPack title]]];
            [checkBox_enableEmoticon setIntValue:[emoPack emoticonEnabled:emoID]];
            [table_curEmoticonTexts reloadData];
        }else{
            NSLog (@"Emoticon Dict or Pack NIL");
            [self enableIndividualEmoticonControls:FALSE];
        }
    }else{
        [self enableIndividualEmoticonControls:FALSE];
    }
}

- (void)initTable:(NSTableView *)table	withEmoticons:(NSArray *)emoticons
{
    // Determine optimal cell size
    float	dim = 5;
    NSEnumerator	*enumerator = [emoticons objectEnumerator];
    NSMutableDictionary		*emoDict = nil;
    NSImage			*image = nil;
    
    while (emoDict = [enumerator nextObject]) {
        image = [emoDict objectForKey:@"Image"];
        
        if ([image size].height > dim)
            dim = [image size].height;
            
        if ([image size].width > dim)
            dim = [image size].width;
    }
    
    if (dim > 32.0)		dim = 32.0;
    
    // Compare cell size to table dimensions
    //float targetColCount = [table frame].size.width / (dim + 4);
    float targetColCount = [table visibleRect].size.width / (dim + 4);
    //NSLog (@"Target column count: %f, Table width: %f", targetColCount, [table bounds].size.width);
    [table setRowHeight:dim]; 
    
    // Remove old columns
    NSArray	*oldColumns = [table tableColumns];
    enumerator = [oldColumns objectEnumerator];
    NSTableColumn	*curColumn = nil;
    
    while (curColumn = [enumerator nextObject]) {
        [table removeTableColumn:curColumn];
    }
    
    // Create new columns
    unsigned int i;	// i starts at 2 because the numbers mesh to make the right number of columns that way.
    for (i = 2; i < targetColCount; i++)
    {
        curColumn = [[[NSTableColumn alloc] initWithIdentifier:@"EmoticonColumn"] autorelease];
        [curColumn setWidth:dim + 4];	// "+ 4" adds padding since we are viewing a string w/ attachment
        [curColumn setResizable:false];
        [curColumn setEditable:false];
        [curColumn setTableView:table];
        [curColumn setDataCell:[[[IKTableImageCell alloc] initImageCell:nil] autorelease]];
        //[curColumn setDataCell:[[[NSImageCell alloc] initImageCell:nil] autorelease]];
        
        //NSLog (@"Adding column #%d", i);
        
        [table addTableColumn:curColumn];
        //[table addTableColumn:[curColumn copy]];
    }
}

//Emoticon Packs Table View ----------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == table_packList)
        return([packs count]);
    else if (tableView == table_curEmoticons)
    {
        return(([curEmoticons count] / [tableView numberOfColumns]) + 1);	// Should check remainder, I am assuming there is one and adding one.
    }
    else if (tableView == table_curEmoticonTexts)
    {
        //Checks if there's a selected emoticon to look at, then finds out how many represented texts there are from that
        NSMutableDictionary	*emoDict = [curEmoticons objectAtIndex:selectedEmoticon];
        if (emoticonIsSelected && emoDict) {
            id			emoID = [emoDict objectForKey:@"Emoticon"];
            AIEmoticonPack	*emoPack = [emoDict objectForKey:@"Pack"];

            //Does this fix our problem?  The world may never know.
            return (([[emoPack emoticonAllTextRepresentationsAsArray:emoID] count] / [tableView numberOfColumns]) + 1);
            
        }else{
            return nil;
        }
    }
else
    {
        NSLog (@"Emoticon prefs Rowcount request: Unrecognized table %@", tableView);
        return 0;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if  (tableView == table_packList)
    {	// Return either whether the pack is enabled, or the pack name
        NSString	*identifier = [tableColumn identifier];
        if([identifier compare:@"check"] == 0){
            return([NSNumber numberWithInt:[(AIEmoticonPack *)[packs objectAtIndex:row] isEnabled]]);
        }else{
            return([[packs objectAtIndex:row] title]);
        }
    }
    else if (tableView == table_curEmoticons)
    {
        unsigned long index = (row * [tableView numberOfColumns]) + [tableView indexOfTableColumn:tableColumn];
        
        if (index < [curEmoticons count])
            return [[curEmoticons objectAtIndex:index] objectForKey:@"Image"];
        else
            return nil;
    }
    else if (tableView == table_curEmoticonTexts)
    {
        NSMutableDictionary	*emoDict = [curEmoticons objectAtIndex:selectedEmoticon];
        if (emoticonIsSelected && emoDict) {
            id			emoID = [emoDict objectForKey:@"Emoticon"];
            AIEmoticonPack	*emoPack = [emoDict objectForKey:@"Pack"];
            unsigned long index = (row * [tableView numberOfColumns]) + [tableView indexOfTableColumn:tableColumn];

            if (index < [[emoPack emoticonAllTextRepresentationsAsArray:emoID] count])
                return [[emoPack emoticonAllTextRepresentationsAsArray:emoID] objectAtIndex:index];
            else
                return nil;
        }
        else
            return nil;
    }
    else
        return nil;
}

// Received when checkboxes are checked and unchecked
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (tableView == table_packList)
    {
        //NSString*		packKey = [NSString stringWithFormat:@"%@_pack_%@", [[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_SOURCE], [[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_TITLE]];
        //NSMutableDictionary*	prefDict = [NSMutableDictionary dictionaryWithDictionary:[[packs objectAtIndex:row] objectForKey:KEY_EMOTICON_PACK_PREFS]];
        AIEmoticonPack		*pack = [packs objectAtIndex:row];
    
        switch ([object intValue])
        {
        case	NSOffState:
            // Turn off selected emoticon-pack
            [pack setEnabled:FALSE];
            break;
    
        case	NSOnState:
        {	// Turn on selected emoticon-pack
                //Conflict resolution
            // For now, this just turns off the other packs.  Later it will check for individual conflicts
            NSEnumerator	*numer = [packs objectEnumerator];
            AIEmoticonPack	*otPack = nil;
    
            while (otPack = [numer nextObject]) {
                if ([otPack isEnabled] != NSOffState) {
                    /*NSString* curPackKey = [NSString stringWithFormat:@"%@_pack_%@", [packDict objectForKey:KEY_EMOTICON_PACK_SOURCE], [packDict objectForKey:KEY_EMOTICON_PACK_TITLE]];
        
                    NSMutableDictionary* tempPrefs = [NSMutableDictionary dictionaryWithDictionary:[packDict objectForKey:KEY_EMOTICON_PACK_PREFS]];
                    [tempPrefs setObject:[NSNumber numberWithInt:NSOffState] forKey:@"inUse"];
        
                    [[owner preferenceController] setPreference:tempPrefs forKey:curPackKey group:PREF_GROUP_EMOTICONS];*/
                    [otPack setEnabled:FALSE];
                }
            }
    
            //Action
            //[prefDict setObject:[NSNumber numberWithInt:NSOnState] forKey:@"inUse"];
            [pack setEnabled:TRUE];
            break;
        }
        case	NSMixedState:
            NSLog (@"Mixed State checkbox in pack list, right after click.");
        }
    
        //[[owner preferenceController] setPreference:prefDict forKey:packKey group:PREF_GROUP_EMOTICONS];
        //[plugin	loadEmoticonsFromPacks];
        [self configureView];	// Maybe we can take this out later.  I want to make sure the dicts in the emoticon
                // packs are up-to-date.  Right now, we certainly need it.
    }
    else
    {
        NSLog (@"Emoticon prefs, setObjectValue ignored.");
    }
}

- (void)selectEmoticon:(id)sender
{
    //NSLog (@"Click was in emoticon table");
    unsigned long index = ([table_curEmoticons clickedRow] * [table_curEmoticons numberOfColumns]) + [table_curEmoticons clickedColumn];

    if (index < [curEmoticons count]){
        emoticonIsSelected = TRUE;
        selectedEmoticon = index;
    }else{
        emoticonIsSelected = FALSE;
    }

    [self populateIndividualEmoticonControls];
    [table_curEmoticons setNeedsDisplay:YES];
}

/*- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSLog (@"Received table click");
    if (tableView == table_curEmoticons){
        NSLog (@"Click was in emoticon table");
        unsigned long index = ([tableView clickedRow] * [tableView numberOfColumns]) + [tableView indexOfTableColumn:tableColumn];
        emoticonIsSelected = TRUE;
        selectedEmoticon = index;
        
        [self populateIndividualEmoticonControls];
    }
}*/

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    if (aTableView == table_packList)
        return YES;
    else
        return NO;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if (tableView == table_curEmoticons)
    {
        // Decide
        unsigned long index = (row * [tableView numberOfColumns]) + [tableView indexOfTableColumn:tableColumn];
        BOOL	select = FALSE, dim = FALSE;
        
         // Highlight
        if (index == selectedEmoticon && emoticonIsSelected)	select = TRUE;

         // Enablement
        if (index < [curEmoticons count]) {
            NSMutableDictionary	*emoDict = [curEmoticons objectAtIndex:index];
            if (emoDict){
                id		emoID = [emoDict objectForKey:@"Emoticon"];
                AIEmoticonPack	*emoPack = [emoDict objectForKey:@"Pack"];

                if ([emoPack emoticonEnabled:emoID] == FALSE)
                    dim = TRUE;
            }
        }
        
        // Display
        [aCell setHighlighted:select];
        //[aCell setCellAttribute:NSChangeGrayCell to:TRUE];
        if (dim)
            [aCell setEnabled:FALSE];
        else
            [aCell setEnabled:TRUE];
        
        //NSLog (@"(Dim: %d)	Select: %d", dim, select);
    }
}
@end
