//
//  CBOldPrefsImporterAppController.m
//  Adium
//
//  Created by Colin Barrett on Sun Aug 24 2003.
//

#import "CBOldPrefsImporterAppController.h"
#import <AIUtilities/AIUtilities.h>
#include <unistd.h>

#define ADIUM_1X_LOGS_PATH	@"~/Library/Application Support/Adium/Users"

@interface CBOldPrefsImporterAppController(PRIVATE)
- (void)importAliases;
- (void)importContacts;
@end

@implementation CBOldPrefsImporterAppController

- (void)awakeFromNib
{
    [popUpButton_account removeItemAtIndex:0];
    [popUpButton_user removeItemAtIndex:0];
    
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setUsesThreadedAnimation:YES];
    
    NSString				*file;
    NSString				*dirPath = [@"~/Library/Application Support/Adium/Users" stringByExpandingTildeInPath];
    NSDirectoryEnumerator   *enumer = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
        
    while(file = [enumer nextObject])
    {
        [enumer skipDescendents];
        if([[[enumer fileAttributes] objectForKey:@"NSFileType"] isEqual:@"NSFileTypeDirectory"])
            [popUpButton_account addItemWithTitle:file];
    }
        
    dirPath = [@"~/Library/Application Support/Adium 2.0/Users" stringByExpandingTildeInPath];
    enumer = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
        
    while(file = [enumer nextObject])
    {
        [enumer skipDescendents];
        if([[[enumer fileAttributes] objectForKey:@"NSFileType"] isEqual:@"NSFileTypeDirectory"])
            [popUpButton_user addItemWithTitle:file];
    }
    
    [window_main makeKeyAndOrderFront:nil];
    
    //No Adium 1.x prefs
    if([popUpButton_account numberOfItems] == 0){
	NSBeginAlertSheet(@"Nothing to import", @"Quit", nil, nil, window_main, NSApp, @selector(terminate:), nil, nil, @"I cannot find any Adium 1.x preferences to import.");
    }
    
    //No Adium 2.0 prefs
    if([popUpButton_user numberOfItems] == 0){
	NSBeginAlertSheet(@"Run Adium 2 first", @"Quit", nil, nil, window_main, NSApp, @selector(terminate:), nil, nil, @"You must run Adium 2 before any settings can be imported");
    }
    
    //Multiple Adium 2.0 users
    if([popUpButton_user numberOfItems] > 1)
    {
	[NSApp beginSheet:theSheet
    modalForWindow:window_main
     modalDelegate:self
    didEndSelector:nil
       contextInfo:nil];
    }
}


//
- (BOOL)ensureAdiumIsClosed
{
    NSArray	    *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    NSEnumerator    *enumerator;
    NSDictionary    *appDict;
    
    enumerator = [apps objectEnumerator];
    while(appDict = [enumerator nextObject]){
	if([[appDict objectForKey:@"NSApplicationName"] rangeOfString:@"Adium"].location != NSNotFound &&
           [[appDict objectForKey:@"NSApplicationName"] rangeOfString:@"Importer"].location == NSNotFound){
	    //Alert
	    NSBeginAlertSheet(@"Adium is running", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"Please close all copies of Adium before importing.");

	    //Return NO
	    return(NO);
	}
    }
    
    return(YES);
}

//
- (IBAction)sheetButton:(id)sender
{
    [[sender window] orderOut:self];
    [NSApp endSheet:[sender window] returnCode:YES];
}

//
- (IBAction)importContacts:(id)sender
{
    [NSApp beginSheet:importListSheet
       modalForWindow:window_main
	modalDelegate:self
       didEndSelector:nil
	  contextInfo:nil];
}

//
- (IBAction)importLogs:(id)sender
{
    NSString	    *importingFromAccount = [popUpButton_account titleOfSelectedItem];
    NSString	    *importingForAccount = [popUpButton_user titleOfSelectedItem];
    NSString	    *newLogFolder;
    NSString	    *oldUserFolder;
    
    if([self ensureAdiumIsClosed]){
	//
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	//We scan through the log folder, and copy each log as we come across it
	oldUserFolder = [ADIUM_1X_LOGS_PATH stringByExpandingTildeInPath];
	newLogFolder = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/Logs", importingForAccount] stringByExpandingTildeInPath];
	
	//Do it
	NSString	    *oldLogFolder;
	NSEnumerator    *logEnumerator;
	NSString	    *subFolder;
	
	//For every contact they messaged
	oldLogFolder = [[oldUserFolder stringByAppendingPathComponent:importingFromAccount] stringByAppendingPathComponent:@"Logs"];
	logEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:oldLogFolder] objectEnumerator];
	while((subFolder = [logEnumerator nextObject])){
	    NSString		*subFolderPath;
	    NSEnumerator	*fileEnumerator;
	    NSString		*fileName;
	    
	    //For every log file they have
	    subFolderPath = [oldLogFolder stringByAppendingPathComponent:subFolder];
	    fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:subFolderPath] objectEnumerator];
	    while((fileName = [fileEnumerator nextObject])){
		NSString	*newPath = [NSString stringWithFormat:@"%@/AIM.%@/%@", newLogFolder, importingFromAccount, subFolder];
		
		//Update status
		[currentTask setStringValue:[NSString stringWithFormat:@"Copying %@", fileName]];
		[currentTask display];
		[progressIndicator animate:nil];
		[progressIndicator display];
		
		//Copy the file
		[AIFileUtilities createDirectory:newPath];
		[[NSFileManager defaultManager] copyPath:[subFolderPath stringByAppendingPathComponent:fileName] 
										  toPath:[newPath stringByAppendingPathComponent:fileName] 
										 handler:nil];
	    }
	}
	
	//
	[progressIndicator stopAnimation:nil];
	[progressIndicator setNeedsDisplay:YES];
	[currentTask setStringValue:@"Log import complete."];
    }
}

//
- (IBAction)importAliases:(id)sender
{
    NSString    *importingFromAccount = [popUpButton_account titleOfSelectedItem];
    NSString    *importingForAccount = [popUpButton_user titleOfSelectedItem];
    
    if([self ensureAdiumIsClosed]){
	//
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	//Open the Adium 1.x buddy list
	NSString *path = [[NSString stringWithFormat:@"~/Library/Application Support/Adium/Users/%@/BuddyList.plist", importingFromAccount] stringByExpandingTildeInPath];
	NSDictionary *buddyList = [[NSDictionary alloc] initWithContentsOfFile:path];
	
	//Scan through all the buddies and groups
	int numGroups = [[buddyList objectForKey:@"numGroups"] intValue];
	int i,j;
	for(i = 0; i < numGroups; i++)
	{
	    NSDictionary *group = [buddyList objectForKey:
		[NSString stringWithFormat:@"group %d", i]];
	    
	    int numContacts = [[group objectForKey:@"numberOfBuddies"] intValue];
	    for(j = 0; j < numContacts; j++)
	    {
		if(![[group objectForKey:[NSString stringWithFormat:@"alias %d", j]] isEqual:@""])
		{
		    NSString    *screenname = [[[group objectForKey:[NSString stringWithFormat:@"buddy %d", j]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
		    
		    //Update our progress display
		    [currentTask setStringValue:[NSString stringWithFormat:@"Importing alias for %@", screenname]];
		    [currentTask display];
		    [progressIndicator animate:nil];
		    [progressIndicator display];
		    
		    //Open the 2.0 object specific preference file for this contact
		    NSString			*prefPath = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/ByObject/AIM.%@.plist", importingForAccount, screenname] stringByExpandingTildeInPath];
		    NSMutableDictionary *prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
		    if(!prefDict) prefDict = [NSMutableDictionary dictionary];
		    
		    //Add the alias key to it
		    [prefDict setObject:[group objectForKey:[NSString stringWithFormat:@"alias %d", j]] forKey:@"Alias"];
		    
		    //Save our changes
		    [AIFileUtilities createDirectory:[prefPath stringByDeletingLastPathComponent]];
		    [prefDict writeToFile:prefPath atomically:YES];
		}
	    }
	}
	
	//clean up
	[buddyList release];
	
	//
	[progressIndicator stopAnimation:nil];
	[progressIndicator setNeedsDisplay:YES];
	[currentTask setStringValue:@"Alias import complete."];
    }
}


/*- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)code contextInfo:(void *)info
{
    if(code)
    {
        [progressIndicator setIndeterminate:YES];
        [progressIndicator startAnimation:self];
        [button_import setEnabled:NO];
        [popUpButton_account setEnabled:NO];
        
        if([checkBox_contacts state] == NSOnState
            && [popUpButton_account selectedItem])
        {
            [self importContacts];
        }
        if([checkBox_aliases state] == NSOnState
            && [popUpButton_account selectedItem])
        {
            [self importAliases];
        }
        
        [currentTask setStringValue:@""];
        [progressIndicator stopAnimation:nil];
        [progressIndicator setIndeterminate:NO];
        [button_import setEnabled:YES];
        [popUpButton_account setEnabled:YES];
    }
}*/

/*- (void)importContacts
{
    
}*/

/*- (void)importAliases;
{
}*/

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
