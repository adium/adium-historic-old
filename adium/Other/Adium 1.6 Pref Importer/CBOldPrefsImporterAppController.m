//
//  CBOldPrefsImporterAppController.m
//  Adium
//
//  Created by Colin Barrett on Sun Aug 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBOldPrefsImporterAppController.h"
#include <unistd.h>

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
    
    NSString *file;
    NSString *dirPath = [@"~/Library/Application Support/Adium/Users" stringByExpandingTildeInPath];
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
}

- (IBAction)import:(id)sender
{
    if(([checkBox_aliases state] != NSOnState
        && [checkBox_contacts state] != NSOnState)
        || ![popUpButton_account selectedItem])
        NSBeep();
    else
    {
        if([popUpButton_user numberOfItems] > 1)
        {
            [NSApp beginSheet:theSheet
                modalForWindow:window_main
                modalDelegate:self
                didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
                contextInfo:nil];
        }
        else
        {
            [self sheetDidEnd:nil returnCode:1 contextInfo:nil];
        }
    }
}

- (IBAction)sheetButton:(id)sender
{
    [theSheet orderOut:self];
    [NSApp endSheet:theSheet returnCode:(sender == button_OK)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)code contextInfo:(void *)info
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
}

- (void)importContacts
{
    
}

- (void)importAliases;
{
    //Read the plist
    NSString *path = [[NSString stringWithFormat:
        @"~/Library/Application Support/Adium/Users/%@/BuddyList.plist", 
        [popUpButton_account titleOfSelectedItem]] stringByExpandingTildeInPath];
    NSDictionary *buddyList = [[NSDictionary alloc] initWithContentsOfFile:path];

    //create aliasDict
    NSMutableDictionary *aliasDict = [[NSMutableDictionary alloc] init];
    int numGroups = [[buddyList objectForKey:@"numGroups"] intValue];
    int i,j;
    for(i = 0; i < numGroups; i++)
    {
        NSDictionary *group = [buddyList objectForKey:
            [NSString stringWithFormat:@"group %d", i]];
                        
        int numContacts = [[group objectForKey:@"numberOfBuddies"] intValue];
        for(j = 0; j < numContacts; j++)
        {
            if(![[group objectForKey:[NSString stringWithFormat:@"alias %d", j]]
                    isEqual:@""])
            {
                NSString *screenname = [[[group objectForKey:
                            [NSString stringWithFormat:@"buddy %d", j]]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                        lowercaseString];
                        
                [currentTask setStringValue:
                    [NSString stringWithFormat:@"Importing alias for %@", screenname]];
                                
                [aliasDict 
                    setObject:[NSDictionary dictionaryWithObject:
                            [group objectForKey:[NSString stringWithFormat:@"alias %d", j]]                    
                        forKey:@"Alias"]
                    forKey:[NSString stringWithFormat:@"(AIM.%@)", screenname]];
            }
        }
    }
    
    path = [[NSString stringWithFormat:
        @"~/Library/Application Support/Adium 2.0/Users/%@/Aliases.plist", 
        [popUpButton_user titleOfSelectedItem]] stringByExpandingTildeInPath];
    
    NSMutableDictionary *newPrefs;
    if(!(newPrefs = [[NSMutableDictionary alloc] initWithContentsOfFile:path]))
        newPrefs = [[NSMutableDictionary alloc] init];
        
    [newPrefs addEntriesFromDictionary:aliasDict];
    if(![newPrefs writeToFile:path atomically:YES])
    {
        NSBeginAlertSheet(@"An Error Has Occured", @"OK", nil, nil, window_main, nil, NULL, NULL, nil, @"There was an error saving %@", path);
    }
    
    //clean up
    [buddyList release];
    [aliasDict release];
    [newPrefs release];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}
@end
