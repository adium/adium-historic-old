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

#define AWAY_MESSAGES_PREF_NIB		@"AwayMessagePrefs"	//Name of preference nib
#define AWAY_MESSAGES_PREF_TITLE	@"Away Messages"	//Title of the preference view

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
    //Add the new away
    [awayMessageArray addObject:@"New"];

    //Regresh our table view
    [tableView_aways loadNewRow];

    //Edit the away
}

- (IBAction)deleteAwayMessage:(id)sender
{

}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
    awayMessageArray = nil;

    //Load the pref view nib
    [NSBundle loadNibNamed:AWAY_MESSAGES_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:AWAY_MESSAGES_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
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


    //Load away messages
    [self loadAwayMessages];
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
    NSLog(@"numberOfRows");
    return([awayMessageArray count]);
}

- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow
{
    AIFlexibleTableCell	*cell;

    NSLog(@"cellForColumn");

    if(inCol == imageColumn){
        cell = [AIFlexibleTableCell cellWithString:@"[:)]"
                                             color:[NSColor blackColor]
                                              font:[NSFont systemFontOfSize:11]
                                         alignment:NSLeftTextAlignment
                                        background:[NSColor whiteColor]
                                          gradient:nil];
        
    }else if(inCol == messageColumn){
        cell = [AIFlexibleTableCell cellWithString:[NSString stringWithFormat:@"Sample Away Message #%i",inRow+1]
                                             color:[NSColor blackColor]
                                              font:[NSFont systemFontOfSize:11]
                                         alignment:NSLeftTextAlignment
                                        background:[NSColor whiteColor]
                                          gradient:nil];
        
    }
    

    return(cell);
}


@end









