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

#define LOG_IMPORT_NIB				@"LogImport"

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
    //Center
    [[self window] center];
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
    [self autorelease];

    return(YES);
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}


//Import logs from Adium 1.x
- (void)importAdium1xLogs
{
    NSString		*newLogFolder;
    NSString		*oldUserFolder;
    NSEnumerator	*userEnumerator;
    NSString		*userFolder;

    //Configure and show the window
    [self window]; //Make sure the window is loaded
    [textField_Goal setStringValue:@"Importing Adium 1.x Logs"];
    [textField_Progress setStringValue:@"Preparing to import"];
    [progress_working startAnimation:nil];
    [self showWindow:nil];

    //We scan through the log folder, and build an array of files that need copying,
    //and where they need copying to.  The files are actually copied from within a timer
    //so as not to lock up the interface
    sourcePathArray = [[NSMutableArray alloc] init];
    destPathArray = [[NSMutableArray alloc] init];
    
    //
    oldUserFolder = [@"~/Library/Application Support/Adium/Users" stringByExpandingTildeInPath];
    newLogFolder = [[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];

    //For every user
    userEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:oldUserFolder] objectEnumerator];
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
    [NSTimer scheduledTimerWithTimeInterval:0.00001
                                     target:self
                                   selector:@selector(_importAdium1xLogsCopyTimer:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)_importAdium1xLogsCopyTimer:(NSTimer *)timer
{
    NSString	*sourcePath = [sourcePathEnumerator nextObject];
    NSString	*destPath = [destPathEnumerator nextObject];

//    NSLog(@"%@\r  to %@",sourcePath,destPath);
    if(sourcePath && destPath){
        [textField_Progress setStringValue:[NSString stringWithFormat:@"Copying %@", [destPath lastPathComponent]]];

        //Copy the file
        [AIFileUtilities createDirectory:[destPath stringByDeletingLastPathComponent]];
        [[NSFileManager defaultManager] copyPath:sourcePath toPath:destPath handler:nil];
        
    }else{ //Import complete
        [timer invalidate];
        [self closeWindow:nil];
        [sourcePathArray release]; sourcePathArray = nil;
        [destPathArray release]; destPathArray = nil;
        [sourcePathEnumerator release]; sourcePathEnumerator = nil;
        [destPathEnumerator release]; destPathEnumerator = nil;
    }
}



@end
