//
//  BGThemeManageView.m
//  Adium
//
//  Created by Brian Ganninger on Sun Jan 11 2004.
//
#import "BGThemeManageView.h"
#import "BGThemesPlugin.h"

#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define THEME_FOLDER_NAME @"Themes"
#define THEME_PATH  [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:THEME_FOLDER_NAME]
#define THEMES_ARE_DIRECTORIES NO

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
    NSMutableArray     *tempThemesList = [NSMutableArray arrayWithCapacity:0];

    if(defaultThemePath){
        [tempThemesList addObject:defaultThemePath];
    }

    NSFileManager      *mgr            = [NSFileManager defaultManager];
    NSArray            *resourcesPaths = [[AIObject sharedAdiumInstance] resourcePathsForName:THEME_FOLDER_NAME];
    NSEnumerator       *tempEnum       = [resourcesPaths objectEnumerator];
    NSString           *curPath;
    NSAutoreleasePool  *pool           = [[NSAutoreleasePool alloc] init];
    while(curPath = [tempEnum nextObject]) {
        NSMutableArray *subpaths       = [[[mgr subpathsAtPath:curPath] mutableCopy] autorelease];
        NSEnumerator   *themeEnum      = [subpaths objectEnumerator];
	
        while(curPath = [themeEnum nextObject]) {
            if([curPath hasPrefix:@"."]) {
                //remove hidden files from the list
                [subpaths removeObject:curPath];
            }
        }

        [tempThemesList addObjectsFromArray:subpaths];
    }
    [pool release];

    themeCount = [tempThemesList count];
    [themes release]; themes = [tempThemesList retain];  // sync cleaned themes list to global variable
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
		NSArray            *resourcesPaths = [[AIObject sharedAdiumInstance] resourcePathsForName:THEME_FOLDER_NAME];
		NSEnumerator       *tempEnum       = [resourcesPaths objectEnumerator];
		NSString           *curResPath;
		NSString           *filePath = nil;
		NSFileManager      *mgr            = [NSFileManager defaultManager];
		BOOL                isDirectory;

		while(curResPath = [tempEnum nextObject]) {
			filePath = [curResPath stringByAppendingPathComponent:[themes objectAtIndex:row]];
			if([mgr fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory) {
				//winner!
				break;
			} else {
				filePath = nil;
			}
		}

		if(filePath) {
			object = [NSDictionary dictionaryWithContentsOfFile:filePath];
		} else {
			object = nil;
		}
	}

	if(object) {
		// a good programmer would set this to return an italicized version when it's backup :)
		if([[tableColumn identifier] isEqualToString:@"themeName"]) {
			return [object objectForKey:@"themeName"];
		} else if([[tableColumn identifier] isEqualToString:@"themeAuthor"]) {
			return [object objectForKey:@"themeAuthor"];
		} else if([[tableColumn identifier] isEqualToString:@"themeVersion"]) {
			return [object objectForKey:@"themeVersion"];
		} else {
			return nil;
		}
	} else {
        return nil;
    }
}

-(NSString *)selectedTheme
{
	int selectedRow = [table selectedRow];

	if (selectedRow != -1) {
		NSString *selection = [themes objectAtIndex:selectedRow];

		if( [selection isEqualToString:defaultThemePath] ) {
			return defaultThemePath;
		} else {
			NSFileManager *mgr = [NSFileManager defaultManager];
			BOOL isDir;
			NSString *curFolder, *curFile;
			NSEnumerator *resPathsEnum = [[[AIObject sharedAdiumInstance] resourcePathsForName:THEME_FOLDER_NAME] objectEnumerator];

			while(curFolder = [resPathsEnum nextObject]) {
				curFile = [curFolder stringByAppendingPathComponent:selection];
				if([mgr fileExistsAtPath:curFile isDirectory:&isDir] && isDir == THEMES_ARE_DIRECTORIES) {
					break;
				}
			}
			if(curFolder == nil) curFile = nil; //curFolder == nil if we exhausted the loop instead of breaking

			return curFile;
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
