/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIXtrasManager.h"
#import "AIXtraInfo.h"
#import "AIAdium.h"
#import "AIPathUtilities.h"
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIGradientCell.h>
#import <AIUtilities/AIImageAdditions.h>

#define ADIUM_XTRAS_PAGE					AILocalizedString(@"http://www.adiumxtras.com/","Adium xtras page. Localized only if a translated version exists.")

@implementation AIXtrasManager

+ (AIXtrasManager *) sharedManager
{
	static AIXtrasManager * manager;
	if(!manager)
		manager = [[self alloc] init];
	return manager;
}

- (void) showXtras
{
	[[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self
															selector:@selector(xtrasChanged:)
																name:Adium_Xtras_Changed
															  object:nil];
	[self loadXtras];
	selectionIndex = 0;
	[NSBundle loadNibNamed:@"XtrasManager" owner:self];
	
	AIImageTextCell			*cell;
	//Configure our tableViews
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[cell setDrawsGradientHighlight:YES];
	[[sidebar tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
	
	[self setSelectedCategoryIndex:[NSIndexSet indexSetWithIndex:0]];
	
	[window makeKeyAndOrderFront:nil];
}

- (void) xtrasChanged:(NSNotification *)not
{
	[self loadXtras];//OMG HAX
}

static NSImage * listThemeImage;
static NSImage * messageStyleImage;
static NSImage * statusIconImage;
static NSImage * soundSetImage;
static NSImage * dockIconImage;
static NSImage * emoticonSetImage;
static NSImage * scriptImage;

- (void) loadXtras
{
	if (!listThemeImage) {
		listThemeImage = [NSImage imageNamed:@"AdiumListTheme"];
		messageStyleImage = [NSImage imageNamed:@"AdiumMessageStyle"];
		statusIconImage = [NSImage imageNamed:@"AdiumStatusIcons"];
		soundSetImage = [NSImage imageNamed:@"AdiumSoundset"];
		dockIconImage = [NSImage imageNamed:@"AdiumIcon"];
		emoticonSetImage = [NSImage imageNamed:@"AdiumEmoticonset"];
		scriptImage = [NSImage imageNamed:@"AdiumScripts"];
	}
	if (xtrasCategories) {
		[xtrasCategories autorelease];
		[categoryNames autorelease];
		[categoryImages autorelease];
	}
	xtrasCategories = [[NSMutableArray alloc] init];
	categoryNames = [[NSMutableArray alloc] init];
	categoryImages = [[NSMutableArray alloc] init];
	
	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIContactListDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Contact List Themes"];
	[categoryImages addObject:listThemeImage];
	
	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIMessageStylesDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Message Styles"];
	[categoryImages addObject:messageStyleImage];

	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIStatusIconsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Status Icons"];
	[categoryImages addObject:statusIconImage];

	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AISoundsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Sound Sets"];
	[categoryImages addObject:soundSetImage];

	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIDockIconsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Dock Icons"];
	[categoryImages addObject:dockIconImage];

	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIEmoticonsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Emoticons"];
	[categoryImages addObject:emoticonSetImage];

	[xtrasCategories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIScriptsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Scripts"];
	[categoryImages addObject:scriptImage];
}

- (NSArray *) arrayOfXtrasAtPaths:(NSArray *)paths
{
	NSMutableArray * contents = [[NSMutableArray alloc] init];
	NSEnumerator * dirEnu = [paths objectEnumerator];
	NSString * path;
	NSEnumerator * xEnu;
	NSString * xtraName;
	while((path = [dirEnu nextObject]))
	{
		xEnu = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		while((xtraName = [xEnu nextObject]))
		{
			if([xtraName isEqualToString:@".DS_Store"]) continue;
			[contents addObject:[AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:xtraName]]]];
		}
	}
	return contents;
}

- (void) dealloc
{
	[xtrasCategories release];
	[categoryNames release];
	[super dealloc];
}

- (NSIndexSet *)selectedCategoryIndex
{
	return [NSIndexSet indexSetWithIndex:selectionIndex];
}

- (IBAction) setCategory:(id)sender
{
	[self setSelectedCategoryIndex:[sidebar selectedRowIndexes]];
}

- (void) setSelectedCategoryIndex:(NSIndexSet *)index
{
	if([index count] > 0)
	{
		selectionIndex = [index firstIndex];
		[categoryController setContent:[xtrasCategories objectAtIndex:selectionIndex]];
	}
}

- (void)deleteXtrasAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		NSFileManager * manager = [NSFileManager defaultManager];
		NSEnumerator * selectionEnu = [[categoryController selectedObjects] objectEnumerator];
		AIXtraInfo * xtra;
		while((xtra = [selectionEnu nextObject]))
		{
			[manager removeFileAtPath:[xtra path] handler:nil];
		}
		[categoryController remove:nil];
	}
}


- (IBAction) deleteXtra:(id)sender
{
	NSAlert * warning = [NSAlert alertWithMessageText:@"Delete Xtra(s)?"
										defaultButton:@"Delete"
									  alternateButton:@"Don't Delete"
										  otherButton:nil
							informativeTextWithFormat:@"The selected Xtra(s) will be deleted permanently. This cannot be undone."];
	[warning beginSheetModalForWindow:window
						modalDelegate:self
					   didEndSelector:@selector(deleteXtrasAlertDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction) browseXtras:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_XTRAS_PAGE]];
}

- (IBAction) checkForUpdates:(id)sender
{
	
}

+ (void) createXtraBundleAtPath:(NSString *)path 
{
	NSFileManager * manager = [NSFileManager defaultManager];
	NSString * name = [[path lastPathComponent] stringByDeletingPathExtension];
	if(![manager fileExistsAtPath:path])
	{
		[manager createDirectoryAtPath:path attributes:[NSDictionary dictionary]];
		path = [path stringByAppendingPathComponent:@"Contents"];
		[manager createDirectoryAtPath:path attributes:[NSDictionary dictionary]];
		[[NSDictionary dictionaryWithObjectsAndKeys:
			@"English", kCFBundleDevelopmentRegionKey,
			name, kCFBundleNameKey,
			@"AdIM", @"CFBundlePackageType",
			[@"com.adiumx." stringByAppendingString:name], kCFBundleIdentifierKey,
			[NSNumber numberWithInt:1], @"XtraBundleVersion",
			@"1.0", kCFBundleInfoDictionaryVersionKey,
			nil] writeToFile:[path stringByAppendingPathComponent:@"Info.plist"] atomically:YES];
		path = [path stringByAppendingPathComponent:@"Resources"];
		[manager createDirectoryAtPath:path attributes:[NSDictionary dictionary]];
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[cell setImage:[categoryImages objectAtIndex:row]];
	[cell setSubString:nil];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [categoryNames count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [categoryNames objectAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if (row >= 0 && row < [categoryNames count]) {		
		[self setSelectedCategoryIndex:[NSIndexSet indexSetWithIndex:row]];
		return YES;
    } else
		return NO;
}

@end
