//
//  AILogViewerWindowController.m
//  Adium
//
//  Created by Adam Iser on Sat Apr 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AILogViewerWindowController.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AILoggerPlugin.h"

#define LOG_VIEWER_NIB				@"LogViewer"
#define KEY_LOG_VIEWER_WINDOW_FRAME		@"Log Viewer Frame"
#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LOG_VIEWER_GROUP_STATE		@"Log Viewer Group State"	//Expand/Collapse state of groups


@interface AILogViewerWindowController (PRIVATE)
- (void)_scanAvailableLogs;
- (void)_makeActiveLogsForServiceID:(NSString *)inServiceID UID:(NSString *)inUID;
- (NSDate *)dateFromFileName:(NSString *)fileName;
@end
int _sortLogArray(NSDictionary *objectA, NSDictionary *objectB, void *context);

@implementation AILogViewerWindowController

//
static AILogViewerWindowController *sharedInstance = nil;
+ (id)logViewerWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:LOG_VIEWER_NIB owner:inOwner];
    }

    return(sharedInstance);
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    //init
    owner = [inOwner retain];

    availableLogArray = nil;
    selectedLogArray = nil;
    
    [super initWithWindowNibName:windowNibName owner:self];


    return(self);
}

//
- (void)dealloc
{
    [owner release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_LOG_VIEWER_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

    //Colors and alternating rows
    [outlineView_contacts setBackgroundColor:[NSColor colorWithCalibratedRed:(250.0/255.0) green:(250.0/255.0) blue:(250.0/255.0) alpha:1.0]];
    [outlineView_contacts setDrawsAlternatingRows:YES];
    [outlineView_contacts setAlternatingRowColor:[NSColor colorWithCalibratedRed:(231.0/255.0) green:(243.0/255.0) blue:(255.0/255.0) alpha:1.0]];
    [outlineView_contacts setNeedsDisplay:YES];

    //Scan the user's logs    
    [self _scanAvailableLogs];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_LOG_VIEWER_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}


- (void)_scanAvailableLogs
{
    NSString		*logFolderPath = [[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
    NSString		*accountFolderPath;
    NSEnumerator	*userEnumerator, *accountEnumerator;
    NSString		*accountFolderName, *folderName;
    NSEnumerator	*enumerator;
    NSDictionary	*dictionary;

    NSMutableDictionary	*groupDict = [NSMutableDictionary dictionary];
    NSMutableDictionary	*contactDict = [NSMutableDictionary dictionary];
    
    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/)
    accountEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:logFolderPath] objectEnumerator];
    while((accountFolderName = [accountEnumerator nextObject])){
        NSRange		periodRange;
        NSString	*accountUID, *serviceID;

        //Get the account UID and ServiceID
        periodRange = [accountFolderName rangeOfString:@"."];
        serviceID = [accountFolderName substringToIndex:periodRange.location];
        accountUID = [accountFolderName substringFromIndex:periodRange.location + 1];

        //Process each user folder (/Logs/SERVICE.ACCOUNT_NAME/CONTACT_NAME/)
        accountFolderPath = [[logFolderPath stringByAppendingPathComponent:accountFolderName] stringByExpandingTildeInPath];
	userEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:accountFolderPath] objectEnumerator];
        while((folderName = [userEnumerator nextObject])){
            NSString		*serverGroup = nil;
            AIServiceType	*serviceType;
            NSString		*contactKey;
            
            //Find the group this contact is in on our contact list
            serviceType = [[owner accountController] serviceTypeWithID:serviceID];
            if(serviceType){
                AIListContact	*contact = [[owner contactController] contactInGroup:nil withService:serviceType UID:folderName];
                if(contact){
                    serverGroup = [[contact containingGroup] UID];
                }
            }
            if(!serverGroup) serverGroup = @"Strangers"; //Default group
            
            //Make sure this groups is in our available group dict
            if(![groupDict objectForKey:serverGroup]){
                [groupDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:serverGroup, @"UID", [NSMutableArray array], @"Contents", nil] forKey:serverGroup];
            }

            //Make sure the handle is in our available handle array
            contactKey = [NSString stringWithFormat:@"%@.%@", serviceID, folderName];
            if(![contactDict objectForKey:contactKey]){
                [contactDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:folderName, @"UID", serviceID, @"ServiceID", serverGroup, @"Group", nil] forKey:contactKey];
            }
        }
    }


    //Build a sorted available log array from our dictionaries
    //Yes, it'd be easier to just use arrays above, but using dictionaries (and transfering the results to an array) gives us a very nice speed boost.
    [availableLogArray release];
    availableLogArray = [[NSMutableArray alloc] init];

    //Fill all groups
    enumerator = [[contactDict allValues] objectEnumerator];
    while(dictionary = [enumerator nextObject]){
        [[[groupDict objectForKey:[dictionary objectForKey:@"Group"]] objectForKey:@"Contents"] addObject:dictionary]; //Add the contact to the group
    }

    //Sort group contents and add them to the main array
    enumerator = [[groupDict allValues] objectEnumerator];
    while(dictionary = [enumerator nextObject]){
        [[dictionary objectForKey:@"Contents"] sortUsingFunction:_sortLogArray context:nil]; //Sort the group
        [availableLogArray addObject:dictionary]; //Add it to our available log array
    }

    //Sort the main array
    [availableLogArray sortUsingFunction:_sortLogArray context:nil];
    [outlineView_contacts reloadData];
}

int _sortLogArray(NSDictionary *objectA, NSDictionary *objectB, void *context)
{
    NSString	*nameA = [objectA objectForKey:@"UID"];
    NSString	*nameB = [objectB objectForKey:@"UID"];

    return([nameA compare:nameB]);
}

- (void)_makeActiveLogsForServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
    NSString		*logFolderPath = [[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
    NSString		*accountFolderPath, *subFolderPath;
    NSEnumerator	*userEnumerator, *accountEnumerator, *fileEnumerator;
    NSString		*accountFolderName, *folderName, *fileName;

    //Flush old selected array
    [selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
    
    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/)
    accountEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:logFolderPath] objectEnumerator];
    while((accountFolderName = [accountEnumerator nextObject])){
        NSRange		periodRange;
        NSString	*accountUID, *serviceID;

        //Get the account UID and ServiceID
        periodRange = [accountFolderName rangeOfString:@"."];
        serviceID = [accountFolderName substringToIndex:periodRange.location];
        accountUID = [accountFolderName substringFromIndex:periodRange.location + 1];

        //Scan any account folders with matching serviceID
        if([inServiceID compare:serviceID] == 0){
            
            //Process each user folder (/Logs/SERVICE.ACCOUNT_NAME/CONTACT_NAME/)
            accountFolderPath = [logFolderPath stringByAppendingPathComponent:accountFolderName];
            userEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:accountFolderPath] objectEnumerator];
            while((folderName = [userEnumerator nextObject])){

                //Scan any account folder with matching UID
                if([folderName compare:inUID] == 0){
                    subFolderPath = [accountFolderPath stringByAppendingPathComponent:folderName];
                    fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:subFolderPath] objectEnumerator];
                    while((fileName = [fileEnumerator nextObject])){
                        NSDate	*logDate = [self dateFromFileName:fileName];

                        if(logDate){
                            [selectedLogArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                logDate, @"Date",
                                folderName, @"To",
                                accountUID, @"From",
                                [subFolderPath stringByAppendingPathComponent:fileName], @"Path",
                                nil]];
                        }
                        
                    }                    
                }
            }
        }
    }

    [tableView_results reloadData];
}

- (NSDate *)dateFromFileName:(NSString *)fileName
{
    NSScanner	*scanner = [NSScanner scannerWithString:fileName];
    NSString	*year = nil, *month = nil, *day = nil;

    //Year
    [scanner scanUpToString:@"(" intoString:nil];
    [scanner scanString:@"(" intoString:nil];
    [scanner scanUpToString:@"|" intoString:&year];
    [scanner scanString:@"|" intoString:nil];

    //Month
    [scanner scanUpToString:@"|" intoString:&month];
    [scanner scanString:@"|" intoString:nil];

    //Day
    [scanner scanUpToString:@")" intoString:&day];
    [scanner scanString:@")" intoString:nil];

    //Construct and return a date
    if(year && month && day){
        return([NSCalendarDate dateWithYear:[year intValue] month:[month intValue] day:[day intValue] hour:0 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]]);
    }else{
        return(nil);
    }
}

- (void)displayLogAtPath:(NSString *)path
{
    NSAttributedString	*logText;
    
    //Load the log
    logText = [[[NSAttributedString alloc] initWithString:[NSString stringWithContentsOfFile:path]] autorelease];
    [[textView_content textStorage] setAttributedString:logText];

    //Scroll to the top
    [textView_content scrollRangeToVisible:NSMakeRange(0,0)];
    
}


// Contact list outline view
// -----------------------------------
// required
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([availableLogArray objectAtIndex:index]);
    }else{
        return([[item objectForKey:@"Contents"] objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item objectForKey:@"Contents"]){
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([availableLogArray count]);
    }else if([item isKindOfClass:[NSDictionary class]]){
        return([[item objectForKey:@"Contents"] count]);
    }else{
        return(0);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return([item objectForKey:@"UID"]);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    int	row = [outlineView_contacts selectedRow];

    if(row != NSNotFound){
        NSDictionary	*contactDict = [outlineView_contacts itemAtRow:row];

        [self _makeActiveLogsForServiceID:[contactDict objectForKey:@"ServiceID"]
                                      UID:[contactDict objectForKey:@"UID"]];
        
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
    NSMutableDictionary	*groupStateDict = [[preferenceDict objectForKey:KEY_LOG_VIEWER_GROUP_STATE] mutableCopy];

    if(!groupStateDict) groupStateDict = [[NSMutableDictionary alloc] init];

    //Save the group new state
    [groupStateDict setObject:[NSNumber numberWithBool:state]
                       forKey:[item objectForKey:@"UID"]];

    [[owner preferenceController] setPreference:groupStateDict forKey:KEY_LOG_VIEWER_GROUP_STATE group:PREF_GROUP_CONTACT_LIST];
    [groupStateDict release];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
    NSMutableDictionary	*groupStateDict = [preferenceDict objectForKey:KEY_LOG_VIEWER_GROUP_STATE];
    NSNumber		*expandedNum;

    //Lookup the group's saved state
    expandedNum = [groupStateDict objectForKey:[item objectForKey:@"UID"]];

    //Correctly expand/collapse the group
    if(!expandedNum || [expandedNum boolValue] == YES){ //Default to expanded
        return(YES);
    }else{
        return(NO);
    }
}



// Log Matches table view
// -----------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([selectedLogArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    NSString	*value = nil;
    
    if([identifier compare:@"to"] == 0){
        value = [[selectedLogArray objectAtIndex:row] objectForKey:@"To"];
        
    }else if([identifier compare:@"from"] == 0){
        value = [[selectedLogArray objectAtIndex:row] objectForKey:@"From"];

    }else if([identifier compare:@"date"] == 0){
        value = [[[selectedLogArray objectAtIndex:row] objectForKey:@"Date"] descriptionWithCalendarFormat:@"%B %d, %Y"];
        
    }
    
    return(value);
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    int	row = [tableView_results selectedRow];

    if(row != NSNotFound){
        NSDictionary	*logDict = [selectedLogArray objectAtIndex:row];

        [self displayLogAtPath:[logDict objectForKey:@"Path"]];
    }
}

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    // check to see if this column was already the selected one and if so invert the sort function.
    // if there already was a sorted column, remove the indicator image from it.
    // set the indicator image in the newly selected column.
    // set the highlighted table column.
    // set the sort function based on what column was clicked.
    // deselect all selected rows.
    // resort the data
    // reload the data
    // reapply the selection...
}

@end
