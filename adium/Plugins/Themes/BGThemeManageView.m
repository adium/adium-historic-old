//
//  BGThemeManageView.m
//  Adium XCode
//
//  Created by Brian Ganninger on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
#import "BGThemeManageView.h"
#import "BGThemesPlugin.h"

#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define THEME_PATH  [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Themes"]

@implementation BGThemeManageView

-(void)awakeFromNib
{        
    [self buildThemesList];
    [table setDrawsAlternatingRows:YES];
    [table setTarget:self];
    [table setDoubleAction:@selector(showPreview:)];   
    [[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self selector:@selector(themesChanged:) name:Themes_Changed object:nil];
    [table reloadData];
}

-(void)themesChanged:(NSNotification *)notification
{
    [self buildThemesList];
}

-(void)buildThemesList
{
    NSMutableArray *tempThemesList = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] subpathsAtPath:THEME_PATH]];
    NSEnumerator *tempEnum = [tempThemesList objectEnumerator];
    NSString *object;
    while(object = [tempEnum nextObject])
    {  
        if([object hasPrefix:@"."]) // remove hidden files from the list
        {
            [tempThemesList removeObject:object];
        }
    }  
    themeCount = [tempThemesList count];
    themes = (NSArray *)[tempThemesList copy]; // sync cleaned themes list to global variable
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return themeCount;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSDictionary *object = [NSDictionary dictionaryWithContentsOfFile:[THEME_PATH stringByAppendingPathComponent:[themes objectAtIndex:row]]];
    
    // a good programmer would set this to return an italicized version when it's backup :)
    if([[tableColumn identifier] isEqualToString:@"themeName"])
    {
        return [object objectForKey:@"themeName"];
    }
    else if([[tableColumn identifier] isEqualToString:@"themeAuthor"])
    {
        return [object objectForKey:@"themeAuthor"];
    }
    else if([[tableColumn identifier] isEqualToString:@"themeVersion"])
    {
        return [object objectForKey:@"themeVersion"];
    }
    else
    {
        return nil;
    }
}

-(NSString *)selectedTheme
{
    return [THEME_PATH stringByAppendingPathComponent:[themes objectAtIndex:[table selectedRow]]];
}

-(void)showPreview:(id)sender
{
    // get selected row's item and then set it :)
    NSDictionary *previewedTheme = [NSDictionary dictionaryWithContentsOfFile:[self selectedTheme]];
    [previewName setObjectValue:[NSString stringWithFormat:@"Now previewing \'%@\' by %@",[previewedTheme objectForKey:@"themeName"],[previewedTheme objectForKey:@"themeAuthor"]]];
    [previewWindow makeKeyAndOrderFront:previewWindow];
}

-(IBAction)removeTheme:(id)sender
{
    // bam! we get rid of that nasty theme ASAP... so quick there's no status update!
    [[NSFileManager defaultManager] removeFileAtPath:[self selectedTheme] handler:self];
    [self buildThemesList];
    [table reloadData];
}

-(IBAction)applyTheme:(id)sender
{
    // pass the plugin the selected theme's name and it will go from there
    [themesPlugin createThemeNamed:@"Last Theme Used" by:@"Adium" version:@"1.0"];
    [themesPlugin applyTheme:[self selectedTheme]];
}

-(void)setPlugin:(BGThemesPlugin *)newPlugin
{
    themesPlugin = newPlugin;
}

@end
