//
//  BGThemeManageView.m
//  Adium
//
//  Created by Brian Ganninger on Sun Jan 11 2004.
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
	themes = nil;
	defaultThemePath = [[NSBundle bundleForClass:[self class]] pathForResource:THEME_ADIUM_DEFAULT ofType:@"AdiumTheme"];

    [table setDrawsAlternatingRows:YES];
    [table setTarget:self];
    [table setDoubleAction:@selector(applyTheme:)];
    [self buildThemesList];
    [[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self selector:@selector(themesChanged:) name:Themes_Changed object:nil];
}

-(void)dealloc
{
	[[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:self];
}

-(void)themesChanged:(NSNotification *)notification
{
    [self buildThemesList];
}

-(void)buildThemesList
{
    NSMutableArray *tempThemesList = [[[NSFileManager defaultManager] subpathsAtPath:THEME_PATH] mutableCopy];
    NSEnumerator *tempEnum = [tempThemesList objectEnumerator];
    NSString *object;
	
    while(object = [tempEnum nextObject]) {
		
        if([object hasPrefix:@"."]) { // remove hidden files from the list
            [tempThemesList removeObject:object];
        }
    }
	
	// HERE
	
	[tempThemesList insertObject:defaultThemePath atIndex:0];
	
    themeCount = [tempThemesList count];
    [themes release]; themes = tempThemesList;  // sync cleaned themes list to global variable
    [self configureControlDimming];
	
	[table reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return themeCount;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	
	NSDictionary *object;
	if( [[themes objectAtIndex:row] isEqualToString:defaultThemePath] ) {
		object = [NSDictionary dictionaryWithContentsOfFile:defaultThemePath];
	} else {
		object = [NSDictionary dictionaryWithContentsOfFile:[THEME_PATH stringByAppendingPathComponent:[themes objectAtIndex:row]]];
    }
	
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
		if( [[themes objectAtIndex:selectedRow] isEqualToString:defaultThemePath] ) {
			return defaultThemePath;
		} else {
			return [THEME_PATH stringByAppendingPathComponent:[themes objectAtIndex:selectedRow]];
		}
	} else {
		return nil;
	}
}

-(IBAction)removeTheme:(id)sender
{
    NSString *warningText = [NSString stringWithFormat:@"Do you really want to permanently delete %@?", [[self selectedTheme] lastPathComponent]];
    int returnCode = NSRunAlertPanel(@"Delete Theme", warningText, @"Delete", @"Cancel",nil);
     if(returnCode == 1)
     {
         NSString *selectedThemePath = [self selectedTheme];
         if (selectedThemePath) {
             [[NSFileManager defaultManager] removeFileAtPath:selectedThemePath handler:self];
             [self buildThemesList];
             [table reloadData];
             [self configureControlDimming];
         }
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
        //[applyButton setEnabled:NO];
    }
    else {
        [removeButton setEnabled:YES];
        //[applyButton setEnabled:YES];
    }
}

@end
