//
//  AIAwayMessagePreferences.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIAwayMessagePreferences.h"
#import "AIAwayMessagesPlugin.h"
#import "AIAwayStatusWindowController.h"

#define AWAY_MESSAGES_PREF_NIB		@"AwayMessagePrefs"	//Name of preference nib
#define AWAY_MESSAGES_PREF_TITLE	@"Away Messages"	//Title of the preference view
#define AWAY_MESSAGE_WINDOW_PREF_TITLE	@"Away Status Window" //Title of preference view
#define AWAY_NEW_MESSAGE_STRING		@"(New Away Message)"
#define AWAY_LIST_IMAGE			@"AwayIcon"		//Away list image filename

@interface AIAwayMessagePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)loadAwayMessages;
- (void)saveAwayMessages;
- (int)numberOfRows;
- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow;
@end

@implementation AIAwayMessagePreferences

+ (AIAwayMessagePreferences *)awayMessagePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

- (IBAction)newAwayMessage:(id)sender
{
    NSAttributedString	*newAway = [[[NSAttributedString alloc] initWithString:AWAY_NEW_MESSAGE_STRING attributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]] autorelease];

    //Add the new away
    [awayMessageArray addObject:newAway];

    //Regresh our table view and edit the row
    [tableView_aways loadNewRow];
    [tableView_aways editRow:[awayMessageArray count]-1 column:messageColumn];
}

- (IBAction)deleteAwayMessage:(id)sender
{
    [awayMessageArray removeObjectAtIndex:[tableView_aways selectedRow]];

    //Save changes and reload our view
    [self saveAwayMessages];
    [tableView_aways reloadData];
}

- (IBAction)toggleShowAway:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SHOW_AWAY_STATUS_WINDOW
                                              group:PREF_GROUP_AWAY_STATUS_WINDOW];
    
    //Enable the "float away" and "hide on deactivate" checkboxes if this one is checked
    [checkBox_floatAway setEnabled:[checkBox_showAway state]];
    [checkBox_hideInBackground setEnabled:[checkBox_showAway state]];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];
        
}

- (IBAction)toggleFloatAway:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_FLOAT_AWAY_STATUS_WINDOW
                                          group:PREF_GROUP_AWAY_STATUS_WINDOW];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];
    
}
- (IBAction)toggleHideInBackground:(id)sender
{
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW
                                          group:PREF_GROUP_AWAY_STATUS_WINDOW];

    // Force a live update of the window status
    [AIAwayStatusWindowController updateAwayStatusWindow];
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
    awayMessageArray = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AWAY_STATUS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_AWAY_STATUS_WINDOW];
    
    //Load the pref view nib
    [NSBundle loadNibNamed:AWAY_MESSAGES_PREF_NIB owner:self];

    //Load our image
    awayImage = [[AIImageUtilities imageNamed:AWAY_LIST_IMAGE forClass:[self class]] retain];
    
    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:AWAY_MESSAGES_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Install Away Status Window preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:AWAY_MESSAGE_WINDOW_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_awayWindowPrefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our aways
    [self loadAwayMessages];

    //Configure our view
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    //Setup our table view
    [tableView_aways setDelegate:self];
    [tableView_aways setContentBottomAligned:NO];

    imageColumn = [[AIFlexibleTableColumn alloc] init];
    [tableView_aways addColumn:imageColumn];

    messageColumn = [[AIFlexibleTableColumn alloc] init];
    [messageColumn setFlexibleWidth:YES];
    [tableView_aways addColumn:messageColumn];

    [tableView_aways reloadData];

    // Set the values of the checkboxes
    [checkBox_showAway setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_SHOW_AWAY_STATUS_WINDOW] boolValue]];

    [checkBox_floatAway setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_FLOAT_AWAY_STATUS_WINDOW] boolValue]];

    [checkBox_hideInBackground setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW] boolValue]];

    // Enable or disable checkboxes based on the "show away" checkbox
    [checkBox_floatAway setEnabled:[checkBox_showAway state]];
    [checkBox_hideInBackground setEnabled:[checkBox_showAway state]];
}

//Load the away messages into awayMessageArray
- (void)loadAwayMessages
{
    NSArray		*dataArray;
    NSEnumerator	*enumerator;
    NSData		*awayData;

    //
    if(awayMessageArray){
        [awayMessageArray release]; awayMessageArray = nil;
    }
    awayMessageArray = [[NSMutableArray alloc] init];

    //Load the aways
    dataArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    enumerator = [dataArray objectEnumerator];
    while((awayData = [enumerator nextObject])){
        [awayMessageArray addObject:[NSAttributedString stringWithData:awayData]];
    }    
}

//Save the away messages
- (void)saveAwayMessages
{
    NSEnumerator	*enumerator;
    NSAttributedString	*awayString;
    NSMutableArray	*dataArray = [[[NSMutableArray alloc] init] autorelease];

    //
    enumerator = [awayMessageArray objectEnumerator];
    while((awayString = [enumerator nextObject])){
        [dataArray addObject:[awayString dataRepresentation]];
    }

    //Save
    [[owner preferenceController] setPreference:dataArray forKey:KEY_SAVED_AWAYS group:PREF_GROUP_AWAY_MESSAGES];
}


//Flexible Table View Delegate ----------------------------------------------------
- (int)numberOfRows
{
    return([awayMessageArray count]);
}

- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    AIFlexibleTableCell	*cell;

    if(inCol == imageColumn){
        cell = [AIFlexibleTableImageCell cellWithImage:awayImage];
        [cell setBackgroundColor:[NSColor whiteColor]];
        [cell setDividerColor:[NSColor lightGrayColor]];
        [cell setPaddingLeft:1 top:2 right:1 bottom:1];
        
    }else if(inCol == messageColumn){
        cell = [AIFlexibleTableTextCell cellWithAttributedString:[awayMessageArray objectAtIndex:inRow]];
        [cell setBackgroundColor:[NSColor whiteColor]];
        [cell setDividerColor:[NSColor lightGrayColor]];
        [cell setPaddingLeft:1 top:1 right:1 bottom:1];

    }
    

    return(cell);
}

- (BOOL)shouldEditTableColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    if(inCol == messageColumn){
        return(YES);
    }else{
        return(NO);
    }
}

- (void)setObjectValue:(id)object forTableColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    if(inCol == messageColumn){
        [awayMessageArray replaceObjectAtIndex:inRow withObject:object];
    }

    [self saveAwayMessages];
//    [tableView_aways reloadData];
}

- (BOOL)shouldSelectRow:(int)inRow
{
    //Enable/disable the delete button correctly
    [button_delete setEnabled:(inRow != -1)];
    
    return(YES);
}

@end




