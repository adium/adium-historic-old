//
//CBOldPrefsImporterAppController.m
//Adium
//
//Created by Colin Barrett on Sun Aug 24 2003.
//

#import "CBOldPrefsImporterAppController.h"
#import <AIUtilities/AIUtilities.h>
#import "AIContentController.h"
#include <unistd.h>

#define ADIUM_1X_LOGS_PATH	@"~/Library/Application Support/Adium/Users"

//Stupid Proteus status codes..
#define PROTEUS_AWAY_STATUS     7


@interface CBOldPrefsImporterAppController(PRIVATE)
- (void)importAliases;
- (void)importContacts;
@end

@implementation CBOldPrefsImporterAppController

- (void)awakeFromNib
{
    [contentController initController];
    [popUpButton_account removeItemAtIndex:0];
    [popUpButton_user removeItemAtIndex:0];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setUsesThreadedAnimation:YES];
        
	
    NSString				*file;
    NSString				*dirPath = [@"~/Library/Application Support/Adium/Users" stringByExpandingTildeInPath];
    NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
	
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
	
	//Here comes the other client stuff yeah yeah yeah!!
	NSMenuItem  *item;
	NSImage     *icon;
	NSString *path;
	NSString *settingsPath;
	NSFileManager *manager = [NSFileManager defaultManager];
	[popUpButton_Clients removeItemAtIndex:0];
	
	path = [[NSString alloc]init];
	path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iChat"];
	settingsPath = [[NSString stringWithString:@"~/Library/Preferences/com.apple.iChat.plist"] stringByExpandingTildeInPath];
	
	if([manager fileExistsAtPath:settingsPath]){
		
		[popUpButton_Clients addItemWithTitle:@"iChat"];
		item = (NSMenuItem *)[popUpButton_Clients lastItem];
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:NSMakeSize(16,16)];
		[item setImage:icon];
	}

	path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Proteus"];
	settingsPath = [@"~/Library/Application Support/Proteus/" stringByExpandingTildeInPath];
	if([manager fileExistsAtPath:settingsPath]){
		[popUpButton_Clients addItemWithTitle:@"Proteus"];
		item = (NSMenuItem *)[popUpButton_Clients lastItem];
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:NSMakeSize(16,16)];
		[item setImage:icon];
		[item setEnabled:NO];
	}
	
	path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Fire"];
	settingsPath = [@"~/Library/Application Support/Fire/" stringByExpandingTildeInPath];
	if([manager fileExistsAtPath:settingsPath]){
		[popUpButton_Clients addItemWithTitle:@"Fire"];
		item = (NSMenuItem *)[popUpButton_Clients lastItem];
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setSize:NSMakeSize(16,16)];
		[item setImage:icon];
		[item setEnabled:NO];
	}
}

- (void)dealloc
{
    [contentController closeController];
}

- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*mutableArray = [NSMutableArray array];
    
    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _loadAwaysFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];
            
        }else if([type isEqualToString:@"Away"]){
            NSMutableDictionary     *newDict = [NSMutableDictionary dictionary];
            NSString                *title = [dict objectForKey:@"Title"];
            NSData                  *autoresponse = [dict objectForKey:@"Autoresponse"];
            
            [newDict setObject:@"Away" forKey:@"Type"];
            [newDict setObject:[NSAttributedString stringWithData:[dict objectForKey:@"Message"]] forKey:@"Message"];
            
            if(title && [title length]){
                [newDict setObject:title forKey:@"Title"];
            }
            
            if(autoresponse){
                [newDict setObject:[NSAttributedString stringWithData:autoresponse] forKey:@"Autoresponse"];
            }
            
            [mutableArray addObject:newDict];
        }
    }
    return(mutableArray);
}

//Recursively build a savable away message array (replacing NSAttributedString with NSData)
- (NSArray *)_saveArrayFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*saveArray = [NSMutableArray array];
    
    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];
        
        if([type isEqualToString:@"Group"]){
            [saveArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _saveArrayFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];
            
        }else if([type isEqualToString:@"Away"]){
            NSMutableDictionary     *newDict = [NSMutableDictionary dictionary];
            NSString                *title = [dict objectForKey:@"Title"];
            NSData                  *autoresponse = [[dict objectForKey:@"Autoresponse"] dataRepresentation];
            
            [newDict setObject:@"Away" forKey:@"Type"];
            [newDict setObject:[[dict objectForKey:@"Message"] dataRepresentation] forKey:@"Message"];
            
            if(title && [title length]){
                [newDict setObject:title forKey:@"Title"];
            }
            
            if(autoresponse){
                [newDict setObject:autoresponse forKey:@"Autoresponse"];
            }
            
            [saveArray addObject:newDict];
        }
    }
    
    return(saveArray);
}
//
- (BOOL)ensureAdiumIsClosed
{
	NSArray	*apps = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator*enumerator;
	NSDictionary*appDict;
	
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
	if([self ensureAdiumIsClosed]){
		
		NSString		*importingFromAccount = [popUpButton_account titleOfSelectedItem];
		NSString		*importingForAccount = [popUpButton_user titleOfSelectedItem];
		NSString		*newLogFolder;
		NSString		*oldUserFolder;
		NSString		*oldLogFolder;
		NSEnumerator	*logEnumerator;
		NSString		*subFolder;
		
		NSFileManager   *defaultFileManager = [NSFileManager defaultManager];
		
		//
		[progressIndicator setIndeterminate:YES];
		[progressIndicator startAnimation:nil];
		
		//We scan through the log folder, and copy each log as we come across it
		oldUserFolder = [ADIUM_1X_LOGS_PATH stringByExpandingTildeInPath];
		newLogFolder = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/Logs", importingForAccount] stringByExpandingTildeInPath];
		
		//Do it
					
		//For every contact they messaged
		oldLogFolder = [[oldUserFolder stringByAppendingPathComponent:importingFromAccount] stringByAppendingPathComponent:@"Logs"];
		logEnumerator = [[defaultFileManager directoryContentsAtPath:oldLogFolder] objectEnumerator];
		while((subFolder = [logEnumerator nextObject])){
			NSString		*subFolderPath;
			NSEnumerator	*fileEnumerator;
			NSString		*fileName;
			
			//For every log file they have
			subFolderPath = [oldLogFolder stringByAppendingPathComponent:subFolder];
			fileEnumerator = [[defaultFileManager directoryContentsAtPath:subFolderPath] objectEnumerator];
			while((fileName = [fileEnumerator nextObject])){
				NSString	*newPath = [NSString stringWithFormat:@"%@/AIM.%@/%@", newLogFolder, importingFromAccount, subFolder];
				
				//Update status
				[currentTask setStringValue:[NSString stringWithFormat:@"Copying %@", fileName]];
				[currentTask display];
				[progressIndicator animate:nil];
				[progressIndicator display];
				
				//Copy the file
				[defaultFileManager createDirectoriesForPath:newPath];
				[defaultFileManager copyPath:[subFolderPath stringByAppendingPathComponent:fileName] 
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
- (IBAction)importAliases:(id)sender
{
	NSString *importingFromAccount = [popUpButton_account titleOfSelectedItem];
	NSString *importingForAccount = [popUpButton_user titleOfSelectedItem];
	
	if([self ensureAdiumIsClosed]){
		//
		[progressIndicator setIndeterminate:YES];
		[progressIndicator startAnimation:nil];
		
		//Open the Adium 1.x buddy list
		NSString		*path = nil;
		NSString		*listAccount = importingFromAccount;
		NSDictionary	*buddyList = nil;
		// Load the appropriate buddy list
		while (buddyList == nil && listAccount != nil) {
			path = [[NSString stringWithFormat:@"~/Library/Application Support/Adium/Users/%@/BuddyList.plist", listAccount] stringByExpandingTildeInPath];
			buddyList = [NSDictionary dictionaryWithContentsOfFile:path];
			
			// If this user shares another user's buddy list, get that one.
			if ([buddyList objectForKey:@"shareBuddyListWith"] != nil) {
				// Get list sharer
				listAccount = [buddyList objectForKey:@"shareBuddyListWith"];
				
				// Bust endless loops
				if ([listAccount isEqualToString:importingFromAccount]) {
					//Alert
					NSBeginAlertSheet(@"Shared buddy list problem", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"An unforseen problem with buddy lists endlessly sharing each other has occurred.Ê If you do not know the cause, please contact an Adium developer.");
					[currentTask setStringValue:@"Alias import failed."];
					
					listAccount = nil;
				}
			}
		}
		
		if (listAccount && buddyList){
			//Scan through all the buddies and groups
			int				numGroups = [[buddyList objectForKey:@"numGroups"] intValue];
			int				i,j;
			NSFileManager   *defaultFileManager = [NSFileManager defaultManager];
			
			for(i = 0; i < numGroups; i++){
				NSDictionary *group = [buddyList objectForKey:[NSString stringWithFormat:@"group %d", i]];
				int numContacts = [[group objectForKey:@"numberOfBuddies"] intValue];
				
				for(j = 0; j < numContacts; j++){
					
					NSString	*alias = [group objectForKey:[NSString stringWithFormat:@"alias %d", j]];
					if(alias && ![alias isEqualToString:@""]){
						NSString			*screenname;
						NSString			*prefPath;
						NSMutableDictionary *prefDict;
						
						screenname = [[[group objectForKey:[NSString stringWithFormat:@"buddy %d", j]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
						
						//Update our progress display
						[currentTask setStringValue:[NSString stringWithFormat:@"Importing alias for %@", screenname]];
						[currentTask display];
						[progressIndicator animate:nil];
						[progressIndicator display];
						
						//Open the 2.0 object specific preference file for this contact
						prefPath = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/ByObject/AIM.%@.plist", importingForAccount, screenname] stringByExpandingTildeInPath];
						prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
						if(!prefDict) prefDict = [NSMutableDictionary dictionary];
						
						//Add the alias key to it
						[prefDict setObject:alias forKey:@"Alias"];
						
						//Save our changes
						[defaultFileManager createDirectoriesForPath:[prefPath stringByDeletingLastPathComponent]];
						
						[prefDict writeToFile:prefPath atomically:YES];
					}
				}
			}

			//
			[currentTask setStringValue:@"Alias import complete."];
		}
		[progressIndicator stopAnimation:nil];
		[progressIndicator setNeedsDisplay:YES];
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


#pragma mark -
#pragma mark Other Client Shtuff

- (IBAction)importAwayMessages:(id)sender
{
    if([self ensureAdiumIsClosed]){
        NSString *whichClient;
        whichClient = [popUpButton_Clients titleOfSelectedItem];
    
        if(whichClient == @"iChat"){
            [self importiChatAways];
        }
        else if(whichClient == @"Proteus"){
            [self importProteusAways];
        }
        else if(whichClient == @"Fire"){
            [self importFireAways];
        }
    }
}

- (void)importiChatAways
{
    [spinner_importProgress setHidden:NO];
    [spinner_importProgress startAnimation:nil];
    [spinner_importProgress display];
    NSAttributedString *newAwayString;
    NSMutableDictionary	*newAwayDict;
    NSString *importingForAccount = [NSString stringWithString:[popUpButton_user titleOfSelectedItem]];
   
    // Create array of iChat away messages
    NSString *iChatPath = [NSString stringWithString:[@"~/Library/Preferences/com.apple.iChat.plist" stringByExpandingTildeInPath]];
    NSDictionary *iChatDict = [NSDictionary dictionaryWithContentsOfFile:iChatPath];
    NSArray *iChatMessageArray = [iChatDict objectForKey:@"CustomAwayMessages"];
        
    // Create an array of Adium's away messages
    NSString *awayMessagePath = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/Away Messages.plist", importingForAccount] stringByExpandingTildeInPath];
    NSMutableDictionary *adiumDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:awayMessagePath];
            
    NSArray *tempArray = [NSArray arrayWithArray:[adiumDictionary objectForKey:@"Saved Away Messages"]];
    NSMutableArray *AdiumMessageArray = [[self _loadAwaysFromArray:tempArray] retain];
    // Or, create a blank list if we've never saved one before
    if (AdiumMessageArray == nil)
        AdiumMessageArray = [NSMutableArray array];
    
        
    // Loop through each iChat away message
    NSEnumerator *iChatEnumerator = [iChatMessageArray objectEnumerator];
    NSEnumerator *AdiumEnumerator = NULL;
    NSDictionary *AdiumMessage; 
    NSString *iChatMsgTitle, *iChatMsgContent;
    NSString *AdiumMsgTitle, *AdiumMsgContent;
    BOOL messageAlreadyExists;
        
    while(iChatMsgContent = [iChatEnumerator nextObject])
        {
            
            // Create a title for the message by truncating it
            iChatMsgTitle = [iChatMsgContent stringWithEllipsisByTruncatingToLength:25];
            
            // Loop through each Adium away message and compare it to the current iChat message
            AdiumEnumerator = [AdiumMessageArray objectEnumerator];
            messageAlreadyExists = NO;
            
            while(AdiumMessage = [AdiumEnumerator nextObject])
            {
                AdiumMsgTitle = [AdiumMessage objectForKey:@"Title"];
                AdiumMsgContent = [AdiumMessage objectForKey:@"Message"];
                
                // If either the title or the content matches, we assume it's already been imported...
                if ( AdiumMessage && ([AdiumMsgTitle isEqualToString:iChatMsgTitle] || [AdiumMsgContent isEqual:iChatMsgContent])) {
                    messageAlreadyExists = YES;
                    break;
                }
            }
            
            // If the message isn't already in Adium's list, add it
            if (!messageAlreadyExists) {
                
                // Casting like a drunk fisherman...
                newAwayString = [[[NSAttributedString alloc] initWithString:iChatMsgContent 
                                                                 attributes:[[self contentController] defaultFormattingAttributes]] autorelease];
                
                // Add the away message to the array... hallelujah!
                
                newAwayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Away",@"Type",newAwayString,@"Message", iChatMsgTitle, @"Title", nil];
                
                
                [AdiumMessageArray addObject:newAwayDict];
            }
        }
    NSArray *finalArray = [self _saveArrayFromArray:AdiumMessageArray];
    [adiumDictionary setObject:finalArray forKey:@"Saved Away Messages"];
    NSDictionary *finalDict = [NSDictionary dictionaryWithDictionary:adiumDictionary];
    [spinner_importProgress stopAnimation:nil];
    [spinner_importProgress setHidden:YES];
        
    if([finalDict writeToFile:[awayMessagePath stringByExpandingTildeInPath] atomically:YES])
    {
        NSLog(@"Success");
        NSBeginAlertSheet(@"iChat messages imported successfully.", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"Your iChat away messages have been imported and are now available in Adium.");
    }
    else
    {
        NSLog(@"Fail");
        NSBeginAlertSheet(@"Import failed", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"The import process has encountered an error. Please make sure your permissions are set correctly and try again. If you continue to have problems, please contact an Adium developer.");
    }
        
    
}

- (void)importProteusAways
{
    NSLog(@"Proteus");
}

- (void)importFireAways
{
    NSLog(@"Fire");
    [spinner_importProgress setHidden:NO];
    [spinner_importProgress startAnimation:nil];
    [spinner_importProgress display];
    NSAttributedString *newAwayString;
    NSMutableDictionary	*newAwayDict;
    NSString *importingForAccount = [NSString stringWithString:[popUpButton_user titleOfSelectedItem]];
    
    //Create an array of Fire Away Messages
    NSString *firePath = [NSString stringWithString:[@"~/Library/Application Support/Fire/FireConfiguration.plist" stringByExpandingTildeInPath]];
       
    NSDictionary *fireDict = [NSDictionary dictionaryWithContentsOfFile:firePath];
    NSDictionary *fireMessageDict = [fireDict objectForKey:@"awayMessages"];
    
    
    // Create an array of Adium's away messages
    NSString *awayMessagePath = [[NSString stringWithFormat:@"~/Library/Application Support/Adium 2.0/Users/%@/Away Messages.plist", importingForAccount] stringByExpandingTildeInPath];
    NSMutableDictionary *adiumDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:awayMessagePath];
    NSArray *tempArray = [NSArray arrayWithArray:[adiumDictionary objectForKey:@"Saved Away Messages"]];
    NSMutableArray *AdiumMessageArray = [[self _loadAwaysFromArray:tempArray] retain];
    // Or, create a blank list if we've never saved one before
    if (AdiumMessageArray == nil)
        AdiumMessageArray = [NSMutableArray array];
    
    
    // Loop through each Fire away message    
    NSEnumerator *AdiumEnumerator = NULL;
    NSDictionary *AdiumMessage; 
    NSDictionary *fireMessage, *fireCurrentMessage;
    NSString *AdiumMsgTitle, *AdiumMsgContent;
    NSString *fireMsgTitle, *fireMsgContent;
    BOOL messageAlreadyExists;
    
    //Get us an array of all the keys in the dictionary
    NSArray *fireKeyArray = [[NSArray alloc] initWithArray:[fireMessageDict allKeys]];
              
    NSEnumerator *fireEnumerator = [fireKeyArray objectEnumerator];
    while(fireMsgTitle = [fireEnumerator nextObject])
    {
        fireMessage = [fireMessageDict objectForKey:fireMsgTitle];
        
        fireMsgContent = [fireMessage objectForKey:@"message"];
        NSLog(fireMsgTitle);
        NSLog(fireMsgContent);
        
        // Loop through each Adium away message and compare it to the current Fire message
        AdiumEnumerator = [AdiumMessageArray objectEnumerator];
        messageAlreadyExists = NO;
        
        while(AdiumMessage = [AdiumEnumerator nextObject])
        {
            // If either the title or the content matches, we assume it's already been imported...
            if ( AdiumMessage && ([AdiumMsgTitle isEqualToString:fireMsgTitle] || [AdiumMsgContent isEqual:fireMsgContent])) {
                messageAlreadyExists = YES;
                break;
            }
        }
        
        
        // If the message isn't already in Adium's list, add it
        if (!messageAlreadyExists) 
        {
            
            // Casting like a drunk fisherman...
            newAwayString = [[[NSAttributedString alloc] initWithString:fireMsgContent 
                                                             attributes:[[self contentController] defaultFormattingAttributes]] autorelease];
            
            // Add the away message to the array... hallelujah!
            
            newAwayDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Away",@"Type",newAwayString,@"Message", fireMsgTitle, @"Title", nil];
            
            
            [AdiumMessageArray addObject:newAwayDict];
        }
        
    }
    NSArray *finalArray = [self _saveArrayFromArray:AdiumMessageArray];
    [adiumDictionary setObject:finalArray forKey:@"Saved Away Messages"];
    NSDictionary *finalDict = [NSDictionary dictionaryWithDictionary:adiumDictionary];
    [spinner_importProgress stopAnimation:nil];
    [spinner_importProgress setHidden:YES];
    
    if([finalDict writeToFile:[awayMessagePath stringByExpandingTildeInPath] atomically:YES])
    {
        NSLog(@"Success");
        NSBeginAlertSheet(@"Fire messages imported successfully.", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"Your Fire away messages have been imported and are now available in Adium.");
    }
    else
    {
        NSLog(@"Fail");
        NSBeginAlertSheet(@"Import failed", @"OK", nil, nil, window_main, nil, nil, nil, nil, @"The import process has encountered an error. Please make sure your permissions are set correctly and try again. If you continue to have problems, please contact an Adium developer.");
    }
  }

    
    
    

#pragma mark -
#pragma mark Application Delegate Methods & Other Ugly Stuff(tm)

- (AIContentController *)contentController{
    return(contentController);
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
