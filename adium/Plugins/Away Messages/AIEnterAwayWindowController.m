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
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define KEY_AWAY_SPELL_CHECKING		@"Custom Away"

#define ENTER_AWAY_WINDOW_NIB		@"EnterAwayWindow"		//Filename of the window nib
#define	KEY_ENTER_AWAY_WINDOW_FRAME	@"Enter Away Frame"
#define DEFAULT_AWAY_MESSAGE		@""
#define KEY_QUICK_AWAY_MESSAGE		@"Quick Away Message"

@interface AIEnterAwayWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
- (void)loadAwayMessages;
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array;
@end

@implementation AIEnterAwayWindowController

//Return a new contact list window controller
AIEnterAwayWindowController	*sharedInstance = nil;
+ (AIEnterAwayWindowController *)enterAwayWindowControllerForOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ENTER_AWAY_WINDOW_NIB owner:inOwner];
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
    [[owner preferenceController] setPreference:newAway forKey:KEY_QUICK_AWAY_MESSAGE group:PREF_GROUP_AWAY_MESSAGES];

    //Set the away
    [[owner accountController] setProperty:newAway forKey:@"AwayMessage" account:nil];

    //Save the away if requested
    if ([button_save state] == NSOnState)
    {
        NSMutableArray * tempArray;
        NSEnumerator * enumerator;
        NSDictionary * dict;
        BOOL notFound = YES;
        //Load the saved away messages
        tempArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];

        //Test for replacement of an existing away
        enumerator = [tempArray objectEnumerator];
        while( (dict = [enumerator nextObject]) && notFound)
        {
            NSString * storedTitle = [dict objectForKey:@"Title"];
            if ([storedTitle compare:[comboBox_title stringValue]] == 0)
            {
                int index = [tempArray indexOfObject:dict];
                NSMutableDictionary * newdict = [[dict mutableCopy] autorelease];
                [newdict setObject:[[textView_awayMessage textStorage] dataRepresentation] forKey:@"Message"];
                [tempArray replaceObjectAtIndex:index withObject:newdict];
                notFound = NO;
            }
        }

        if (notFound) { //never found one to replace then add it
            if(edited_title){
                [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Away", @"Type", [[textView_awayMessage textStorage] dataRepresentation], @"Message", [comboBox_title stringValue], @"Title", nil]];
            }else{
                [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Away", @"Type", [[textView_awayMessage textStorage] dataRepresentation], @"Message", nil]];
            }
        }



        //Save the away message array
        [[owner preferenceController] setPreference:tempArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];
    }

    //Close our window
    [self closeWindow:nil];
}


//Private ----------------------------------------------------------------
//init the window controller
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    owner = [inOwner retain];

    return(self);
}

//dealloc
- (void)dealloc
{
    [owner release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
    NSData	*lastAway;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_ENTER_AWAY_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

    //Restore the last used custom away
    lastAway = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_QUICK_AWAY_MESSAGE];
    if(lastAway){
        [textView_awayMessage setAttributedString:[NSAttributedString stringWithData:lastAway]];
    }else{
        [textView_awayMessage setString:DEFAULT_AWAY_MESSAGE];
    }

    [comboBox_title setStringValue:[textView_awayMessage string]];


    //Select the away text
    [textView_awayMessage setSelectedRange:NSMakeRange(0,[[textView_awayMessage textStorage] length])];

    //Restore spellcheck state
    [textView_awayMessage setContinuousSpellCheckingEnabled:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_AWAY_SPELL_CHECKING] boolValue]];

    //Configure our sending view
    [textView_awayMessage setTarget:self action:@selector(setAwayMessage:)];
    [textView_awayMessage setSendOnReturn:NO]; //Pref for these later :)
    [textView_awayMessage setSendOnEnter:YES]; //
    [textView_awayMessage setDelegate:self];
    edited_title = NO;

    [self loadAwayMessages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:NSComboBoxSelectionDidChangeNotification object:comboBox_title];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:comboBox_title];

    [[self window] makeFirstResponder:textView_awayMessage];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Save spellcheck state
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[textView_awayMessage isContinuousSpellCheckingEnabled]] forKey:KEY_AWAY_SPELL_CHECKING group:PREF_GROUP_SPELLING];

    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
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

- (void)textDidChange:(NSNotification *)notification
{
    if ([notification object] == textView_awayMessage) //User is editing an away message
    {
        if(!edited_title) //only do this if the user hasn't edited the title manually
        {
            [comboBox_title setStringValue:[textView_awayMessage string]];
        }
    }
    else if ([notification object] == comboBox_title) //User is editing the away message title
    {

        if([[comboBox_title stringValue] length] != 0){
            edited_title = YES;
	    [button_save setState:YES];
        }else{
            edited_title = NO;
        }
    }
}

//the combo box changed selection - set the message appropriately
- (void)selectionChanged:(NSNotification *)notification
{
    if ([comboBox_title indexOfSelectedItem] != -1)
    {
        NSDictionary * dict = [awayMessageArray objectAtIndex:[comboBox_title indexOfSelectedItem]];

        [textView_awayMessage setAttributedString:[dict objectForKey:@"Message"]];
        edited_title = YES;
        [button_save setState:NO];

        //make the text editing active
        [[self window] makeFirstResponder:textView_awayMessage];
    }
}

//User toggled 'save' checkbox
- (IBAction)toggleSave:(id)sender
{
    if([button_save state] == NSOnState){
        [[comboBox_title window] makeFirstResponder:comboBox_title];
    }else{
        [[textView_awayMessage window] makeFirstResponder:textView_awayMessage];
    }
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
    tempArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    if(tempArray){
        //Load the aways
        awayMessageArray = [self _loadAwaysFromArray:tempArray];

    }else{
        //If no aways exist, create an empty array
        awayMessageArray = [[NSMutableArray alloc] init];
    }

    NSEnumerator *enumerator = [awayMessageArray objectEnumerator];
    NSDictionary *dict;
    while (dict = [enumerator nextObject])
    {
        NSString * title = [dict objectForKey:@"Title"];
        if (title)
	    [comboBox_title addItemWithObjectValue:title];
	else
	{
	    NSString * message = [[dict objectForKey:@"Message"] string];
	    if (message) [comboBox_title addItemWithObjectValue:message];
	}
    }
}

//Save the away messages
- (void)saveAwayMessages
{
    NSArray	*tempArray;

    //Rebuild the away message array, converting all attributed string to NSData's that are suitable for saving
    tempArray = [self _saveArrayFromArray:awayMessageArray];

    //Save the away message array
    [[owner preferenceController] setPreference:tempArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];
}

@end
