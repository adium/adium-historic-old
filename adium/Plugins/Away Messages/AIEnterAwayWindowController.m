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

#import "AIEnterAwayWindowController.h"
#import "AIAwayMessagesPlugin.h"

#define KEY_AWAY_SPELL_CHECKING		@"Custom Away"

#define ENTER_AWAY_WINDOW_NIB		@"EnterAwayWindow"		//Filename of the window nib
#define	KEY_ENTER_AWAY_WINDOW_FRAME	@"Enter Away Frame"
#define DEFAULT_AWAY_MESSAGE		@""
#define KEY_QUICK_AWAY_MESSAGE		@"Quick Away Message"

#define NO_PRESET_AWAY			AILocalizedString(@"None",nil)

@interface AIEnterAwayWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (BOOL)windowShouldClose:(id)sender;
- (void)loadAwayMessages;
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array;
- (NSMenu *)savedAwaysMenu;
@end

@implementation AIEnterAwayWindowController

//Return a new contact list window controller
AIEnterAwayWindowController	*sharedInstance = nil;
+ (AIEnterAwayWindowController *)enterAwayWindowController
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ENTER_AWAY_WINDOW_NIB];
    }
    return(sharedInstance);
}

//Closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Cancel
- (IBAction)cancel:(id)sender
{
    [self closeWindow:nil];
}

//Set the away
- (IBAction)setAwayMessage:(id)sender
{
    NSData	*newAway;

    //Save the away message
    newAway = [[textView_awayMessage textStorage] dataRepresentation];
    [[adium preferenceController] setPreference:newAway forKey:KEY_QUICK_AWAY_MESSAGE group:PREF_GROUP_AWAY_MESSAGES];

    //Set the away
    [[adium preferenceController] setPreference:newAway forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
    [[adium preferenceController] setPreference:nil forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
    
    //Close our window
    [self closeWindow:nil];
}

//Save the away
- (IBAction)save:(id)sender
{
    NSString * title = [[[popUp_title selectedItem] representedObject] objectForKey:@"Title"];
    NSString * message = [[textView_awayMessage textStorage] string];
    if(loaded_message) {
        [textField_title setStringValue:(title ? title : @"")];
    } else {
        [textField_title setStringValue:(message ? message : @"")];
    }
    
    [NSApp beginSheet:savePanel modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveSheetClosed:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)endSheet:(id)sender
{
    int retCode = 0;
    if(sender != savePanel_cancelButton) {
        retCode = 1;
    }
    [savePanel orderOut:nil];
    [NSApp endSheet:savePanel returnCode:retCode];
}

- (void)saveSheetClosed:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode == 1)
    {
        NSMutableArray * tempArray;
        NSEnumerator * enumerator;
        NSDictionary * dict;
        BOOL found = NO;

	NSString * theTitle = [textField_title stringValue];

	
        //Load the saved away messages
        tempArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];

        // Or create a blank list if we've never saved one before
        if (tempArray == nil)
            tempArray = [NSMutableArray array];

        //Test for replacement of an existing away
        enumerator = [tempArray objectEnumerator];
        while( (dict = [enumerator nextObject]) && !found)
        {
            NSString * storedTitle = [dict objectForKey:@"Title"];
            if ( storedTitle && ([storedTitle compare:theTitle] == 0) )
            {
                int index = [tempArray indexOfObject:dict];
                NSMutableDictionary * newdict = [[dict mutableCopy] autorelease];
                [newdict setObject:[[textView_awayMessage textStorage] dataRepresentation] forKey:@"Message"];
                [tempArray replaceObjectAtIndex:index withObject:newdict];
                found = YES;
            }
        }

        if (!found) { //never found one to replace then add it
            [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Away", @"Type", [[textView_awayMessage textStorage] dataRepresentation], @"Message", theTitle, @"Title", nil]];
        }

	//Save the away message array
        [[adium preferenceController] setPreference:tempArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];

	[popUp_title setMenu:[self savedAwaysMenu]];
	[popUp_title selectItemWithTitle:theTitle];
    }
}

//Private ----------------------------------------------------------------
//init the window controller
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    return(self);
}

//dealloc
- (void)dealloc
{
    [awayMessageArray release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
    NSData	*lastAway;

    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_ENTER_AWAY_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

    //Restore the last used custom away
    lastAway = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_QUICK_AWAY_MESSAGE];
    if(lastAway){
        [textView_awayMessage setAttributedString:[NSAttributedString stringWithData:lastAway]];
    }else{
        [textView_awayMessage setString:DEFAULT_AWAY_MESSAGE];
    }

    //Select the away text
    [textView_awayMessage setSelectedRange:NSMakeRange(0,[[textView_awayMessage textStorage] length])];

    //Restore spellcheck state
    [textView_awayMessage setContinuousSpellCheckingEnabled:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_AWAY_SPELL_CHECKING] boolValue]];

    //Configure our sending view
    [textView_awayMessage setTarget:self action:@selector(setAwayMessage:)];
    [textView_awayMessage setSendOnReturn:NO]; //Pref for these later :)
    [textView_awayMessage setSendOnEnter:YES]; //
	[textView_awayMessage setPushPop:NO];
    [textView_awayMessage setDelegate:self];
    loaded_message = NO;

    [self loadAwayMessages];

    [popUp_title setMenu:[self savedAwaysMenu]];

    [[self window] makeFirstResponder:textView_awayMessage];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Save spellcheck state
    [[adium preferenceController] setPreference:[NSNumber numberWithBool:[textView_awayMessage isContinuousSpellCheckingEnabled]] forKey:KEY_AWAY_SPELL_CHECKING group:PREF_GROUP_SPELLING];

    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_ENTER_AWAY_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Release the shared instance
    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//the combo box changed selection - set the message appropriately
- (IBAction)loadSavedAway:(id) sender
{
    if (![sender representedObject]) {
	[textView_awayMessage setString:@""];
	loaded_message = NO;
    } else {
	NSAttributedString * theString = [[sender representedObject] objectForKey:@"Message"];
        [textView_awayMessage setAttributedString:theString];
	[textView_awayMessage setSelectedRange:(NSMakeRange(0, [[theString string] length]))];
        loaded_message = YES;
    }

    //make the text editing active
    [[self window] makeFirstResponder:textView_awayMessage];
}

//Private ----------------------------------------------------
//Recursively load the away messages, rebuilding the structure with mutable objects
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*mutableArray = [[NSMutableArray alloc] init];

    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];

        if([type compare:@"Group"] == 0){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _loadAwaysFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];

        }else if([type compare:@"Away"] == 0){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Away", @"Type",
                [NSAttributedString stringWithData:[dict objectForKey:@"Message"]], @"Message",[dict objectForKey:@"Title"], @"Title",
                nil]];

        }
    }

    return(mutableArray);
}

//Recursively build a savable away message array (replacing NSAttributedString with NSData)
- (NSArray *)_saveArrayFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*saveArray = [[NSMutableArray alloc] init];

    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];

        if([type compare:@"Group"] == 0){
            [saveArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _saveArrayFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];

        }else if([type compare:@"Away"] == 0){
            [saveArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                @"Away", @"Type",
                [[dict objectForKey:@"Message"] dataRepresentation], @"Message", [dict objectForKey:@"Title"], @"Title",
                nil]];

        }
    }

    return(saveArray);
}

//Load the away messages
- (void)loadAwayMessages
{
    NSArray	*tempArray;

    //Release any existing away array
    [awayMessageArray release];

    //Load the saved away messages
    tempArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    if(tempArray){
        //Load the aways
        awayMessageArray = [self _loadAwaysFromArray:tempArray];

    }else{
        //If no aways exist, create an empty array
        awayMessageArray = [[NSMutableArray alloc] init];
    }

}

//Save the away messages
- (void)saveAwayMessages
{
    NSArray	*tempArray;

    //Rebuild the away message array, converting all attributed string to NSData's that are suitable for saving
    tempArray = [self _saveArrayFromArray:awayMessageArray];

    //Save the away message array
    [[adium preferenceController] setPreference:tempArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];
}

- (NSMenu *)savedAwaysMenu
{
    NSMenu		*savedAwaysMenu = [[NSMenu alloc] init];
    NSMenuItem		*menuItem;
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:NO_PRESET_AWAY
					   target:self
					   action:@selector(loadSavedAway:)
				    keyEquivalent:@"N"] autorelease];
    [menuItem setRepresentedObject:nil];
    [savedAwaysMenu addItem:menuItem];

    [self loadAwayMessages]; //load the away messages into awayMessageArray

    NSEnumerator *enumerator = [awayMessageArray objectEnumerator];
    NSDictionary *dict;
    while (dict = [enumerator nextObject])
    {
        NSString * title = [dict objectForKey:@"Title"];
        if (title) {
	    menuItem = [[[NSMenuItem alloc] initWithTitle:title
						target:self
						action:@selector(loadSavedAway:)
						keyEquivalent:@""] autorelease];
	} else {
	    NSString * message = [[dict objectForKey:@"Message"] string];

	    //Cap the away menu title (so they're not incredibly long)
            if([message length] > MENU_AWAY_DISPLAY_LENGTH){
                message = [[message substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"…"];
            }
	    menuItem = [[[NSMenuItem alloc] initWithTitle:message
					    target:self
					    action:@selector(loadSavedAway:)
					    keyEquivalent:@""] autorelease];
	}
	[menuItem setRepresentedObject:dict];
	[savedAwaysMenu addItem:menuItem];
    }
    return savedAwaysMenu;
}

@end
