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

#import "AILogImporter.h"
#import "AILoggerPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

#define LOG_IMPORT_NIB		@"LogImport"
#define ADIUM_1X_LOGS_PATH	@"~/Library/Application Support/Adium/Users"


@interface AILogImporter (PRIVATE)
- (NSArray *)availableUsers;
@end

@implementation AILogImporter

+ (id)logImporterWithOwner:(id)inOwner
{
    return([[self alloc] initWithWindowNibName:LOG_IMPORT_NIB owner:inOwner]);
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    //init
    owner = [inOwner retain];
    [super initWithWindowNibName:windowNibName owner:self];

    //
    sourcePathArray = nil;
    destPathArray = nil;
    sourcePathEnumerator = nil;
    destPathEnumerator = nil;
    usersToImport = nil;
    availableUsers = nil;
    
    
    return(self);
}

//
- (void)dealloc
{
    [owner release];
    [importTimer release];
    [sourcePathArray release];
    [destPathArray release];
    [sourcePathEnumerator release];
    [destPathEnumerator release];
    [usersToImport release];
    [availableUsers release];
    
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Center
    [[self window] center];

    //Config table view
    NSButtonCell	*newCell;
    newCell = [[[NSButtonCell alloc] init] autorelease];
    [newCell setButtonType:NSSwitchButton];
    [newCell setControlSize:NSSmallControlSize];
    [newCell setTitle:@""];
    [newCell setRefusesFirstResponder:YES];
    [[[tableView_userList tableColumns] objectAtIndex:0] setDataCell:newCell];

    //Fetch the list of available logs
    availableUsers = [[self availableUsers] retain];
    usersToImport = [[NSMutableArray alloc] init];
    
    [tableView_userList reloadData];
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
    //Stop any importing
    [importTimer invalidate];
    [self autorelease];

    return(YES);
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}


//Available Users Table View ----------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([availableUsers count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:@"check"] == 0){
        if([usersToImport containsObject:[availableUsers objectAtIndex:row]]){
            return([NSNumber numberWithBool:YES]);
        }else{
            return([NSNumber numberWithBool:NO]);
        }
    }else{
        return([availableUsers objectAtIndex:row]);
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*user = [availableUsers objectAtIndex:row];
    
    if([object intValue] == 0){
        [usersToImport removeObject:user];
    }else{
        [usersToImport addObject:user];
    }    
}


//Importing ------------------------------------------------------------------------------------
//Returns an array of users available for import
- (NSArray *)availableUsers
{	
    NSString		*oldUserFolder;
    NSMutableArray	*userArray;
    NSEnumerator	*enumerator;
    NSArray		*directoryContents;
    NSString		*folderName;
    
    //Get the user list
    oldUserFolder = [ADIUM_1X_LOGS_PATH stringByExpandingTildeInPath];
    directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:oldUserFolder];
    userArray = [NSMutableArray array];
    
    //Remove any hidden files
    enumerator = [directoryContents objectEnumerator];
    while((folderName = [enumerator nextObject])){
        if(![folderName hasPrefix:@"."]){
            [userArray addObject:folderName];
        }
    }

    return(userArray);
}

//Import the selected logs from Adium 1.x
- (IBAction)importLogs:(id)sender
{
    NSString		*newLogFolder;
    NSString		*oldUserFolder;
    NSEnumerator	*userEnumerator;
    NSString		*userFolder;

    //Configure and show the window
    [textField_Goal setStringValue:@"Importing Adium 1.x Logs"];
    [textField_Progress setStringValue:@"Preparing to import"];
    [progress_working startAnimation:nil];
    [panel_progress center];
    [panel_progress makeKeyAndOrderFront:nil];

    //We scan through the log folder, and build an array of files that need copying,
    //and where they need copying to.  The files are actually copied from within a timer
    //so as not to lock up the interface
    sourcePathArray = [[NSMutableArray alloc] init];
    destPathArray = [[NSMutableArray alloc] init];
    
    //
    oldUserFolder = [ADIUM_1X_LOGS_PATH stringByExpandingTildeInPath];
    newLogFolder = [[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];

    //For every selected user
    userEnumerator = [usersToImport objectEnumerator];
    while((userFolder = [userEnumerator nextObject])){
        NSString	*oldLogFolder;
        NSEnumerator	*logEnumerator;
        NSString	*subFolder;

        //For every contact they messaged
        oldLogFolder = [[oldUserFolder stringByAppendingPathComponent:userFolder] stringByAppendingPathComponent:@"Logs"];
        logEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:oldLogFolder] objectEnumerator];
        while((subFolder = [logEnumerator nextObject])){
            NSString		*subFolderPath;
            NSEnumerator	*fileEnumerator;
            NSString		*fileName;

            //For every log file they have
            subFolderPath = [oldLogFolder stringByAppendingPathComponent:subFolder];
            fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:subFolderPath] objectEnumerator];
            while((fileName = [fileEnumerator nextObject])){
                NSString	*newPath = [NSString stringWithFormat:@"%@/AIM.%@/%@", newLogFolder, userFolder, subFolder];

                [sourcePathArray addObject:[subFolderPath stringByAppendingPathComponent:fileName]];
                [destPathArray addObject:[newPath stringByAppendingPathComponent:fileName]];
            }
        }
    }

    //Install the copy timer
    sourcePathEnumerator = [[sourcePathArray objectEnumerator] retain];
    destPathEnumerator = [[destPathArray objectEnumerator] retain];
    importTimer = [[NSTimer scheduledTimerWithTimeInterval:0.00001
                                                   target:self
                                                 selector:@selector(_importAdium1xLogsCopyTimer:)
                                                 userInfo:nil
                                                  repeats:YES] retain];
    
    //Hide the import window
    [[self window] orderOut:nil];
}

- (void)_importAdium1xLogsCopyTimer:(NSTimer *)timer
{
    NSString	*sourcePath = [sourcePathEnumerator nextObject];
    NSString	*destPath = [destPathEnumerator nextObject];

    if(sourcePath && destPath){
        [textField_Progress setStringValue:[NSString stringWithFormat:@"Copying %@", [destPath lastPathComponent]]];

        //Copy the file
        [AIFileUtilities createDirectory:[destPath stringByDeletingLastPathComponent]];
        [[NSFileManager defaultManager] copyPath:sourcePath toPath:destPath handler:nil];
        
    }else{ //Import complete
        [self closeWindow:nil];
    }
}



@end
