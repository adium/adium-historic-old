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

@interface BGThemeManageView (PRIVATE)
- (void)configureControlDimming;
@end

@implementation BGThemeManageView

-(void)awakeFromNib
{        
    [self buildThemesList];
    [table setDrawsAlternatingRows:YES];
    [table setTarget:self];
    [table setDoubleAction:@selector(showPreview:)];   
    [[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self selector:@selector(themesChanged:) name:Themes_Changed object:nil];
    [table reloadData];
    [self configureControlDimming];
}

-(void)themesChanged:(NSNotification *)notification
{
    [self buildThemesList];
    [self configureControlDimming];
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
	int selectedRow = [table selectedRow];
	if (selectedRow != -1) {
		return [THEME_PATH stringByAppendingPathComponent:[themes objectAtIndex:selectedRow]];
	} else {
		return nil;
	}
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
	NSString *selectedThemePath = [self selectedTheme];
	if (selectedThemePath) {
		[[NSFileManager defaultManager] removeFileAtPath:selectedThemePath handler:self];
		[self buildThemesList];
		[table reloadData];
                [self configureControlDimming];
	}
}

-(IBAction)applyTheme:(id)sender
{
    if([themes count] == 0)
    {
        NSRunAlertPanel(@"No themes present",@"To apply a theme please install one and select it first.",@"OK",nil,nil);
    }
    else
    {  
        // pass the plugin the selected theme's name and it will go from there
        [themesPlugin createThemeNamed:@"Last Theme Used" by:@"Adium" version:@""];
        [themesPlugin applyTheme:[self selectedTheme]];
    }
}

-(void)setPlugin:(BGThemesPlugin *)newPlugin
{
    themesPlugin = newPlugin;
}

// -------- private -------------

// Enable/disable controls depending on presence of themes
- (void)configureControlDimming
{
    if ([themes count] == 0) { // themes aren't present
        [removeButton setEnabled:NO];
        [applyButton setEnabled:NO];
    }
    else {
        [removeButton setEnabled:YES];
        [applyButton setEnabled:YES];
    }
}

@end
