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
    [[owner accountController] setStatusObject:newAway forKey:@"AwayMessage" account:nil];

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

    //Select the away text
    [textView_awayMessage setSelectedRange:NSMakeRange(0,[[textView_awayMessage textStorage] length])];

    //Restore spellcheck state
    [textView_awayMessage setContinuousSpellCheckingEnabled:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_AWAY_SPELL_CHECKING] boolValue]];

    //Configure our sending view
    [textView_awayMessage setTarget:self action:@selector(setAwayMessage:)];
    [textView_awayMessage setSendOnReturn:NO]; //Pref for these later :)
    [textView_awayMessage setSendOnEnter:YES]; //
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

@end
