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
#import <AIUtilities/AIArrayAdditions.h>

#import "AIXtraPreviewController.h"

#define ADIUM_XTRAS_PAGE					AILocalizedString(@"http://www.adiumxtras.com/","Adium xtras page. Localized only if a translated version exists.")

@implementation AIXtrasManager

static AIXtrasManager * manager;

+ (AIXtrasManager *) sharedManager
{
	return manager;
}

- (void) installPlugin
{
	manager = self;
}

- (void) showXtras
{
	[self loadXtras];

	if(![window isVisible]) {
		showInfo = NO;
		
		[[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self
																selector:@selector(xtrasChanged:)
																	name:Adium_Xtras_Changed
																  object:nil];
		[NSBundle loadNibNamed:@"XtrasManager" owner:self];
		
		AIImageTextCell			*cell;
		//Configure our tableViews
		cell = [[AIImageTextCell alloc] init];
		[cell setFont:[NSFont systemFontOfSize:12]];
		[cell setDrawsGradientHighlight:YES];
		[[sidebar tableColumnWithIdentifier:@"name"] setDataCell:cell];
		[cell release];
		
		cell = [[AIImageTextCell alloc] init];
		[cell setFont:[NSFont systemFontOfSize:12]];
		[cell setDrawsGradientHighlight:YES];
		[[xtraList tableColumnWithIdentifier:@"xtras"] setDataCell:cell];
		[cell release];
		
		[previewContainerView setHasVerticalScroller:YES];
		[previewContainerView setAutohidesScrollers:YES];
		[previewContainerView setBorderType:NSBezelBorder];
		
		[self setCategory:nil];
	}
	[self setCategory:nil];//Hax. This shouldn't be needed, but it is.
		
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
	if (categories) {
		[categories autorelease];
		[categoryNames autorelease];
		[categoryImages autorelease];
	}
	categories = [[NSMutableArray alloc] init];
	categoryNames = [[NSMutableArray alloc] init];
	categoryImages = [[NSMutableArray alloc] init];
	
	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIMessageStylesDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Message Styles"];
	[categoryImages addObject:messageStyleImage];
	
	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIContactListDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Contact List Themes"];
	[categoryImages addObject:listThemeImage];

	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIStatusIconsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Status Icons"];
	[categoryImages addObject:statusIconImage];

	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AISoundsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Sound Sets"];
	[categoryImages addObject:soundSetImage];

	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIDockIconsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Dock Icons"];
	[categoryImages addObject:dockIconImage];

	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIEmoticonsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Emoticons"];
	[categoryImages addObject:emoticonSetImage];

	[categories addObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIScriptsDirectory, AIAllDomainsMask, YES)]];
	[categoryNames addObject:@"Scripts"];
	[categoryImages addObject:scriptImage];
}

- (NSArray *) arrayOfXtrasAtPaths:(NSArray *)paths
{
	NSMutableArray * contents = [NSMutableArray array];
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
	[categories release];
	[categoryNames release];
	[super dealloc];
}

- (IBAction) setCategory:(id)sender
{
	[selectedCategory autorelease];
	selectedCategory = [[categories objectAtIndex:[sidebar selectedRow]]retain];
	[xtraList selectRow:0 byExtendingSelection:NO];
	[xtraList reloadData];
	[self updatePreview];
}

- (void) updatePreview
{
	AIXtraInfo * xtra = [selectedCategory objectAtIndex:[xtraList selectedRow]];
	[showInfoControl setHidden:NO];
	if(showInfo)
		[NSBundle loadNibNamed:@"XtraInfoView" owner:self];
	else {
		[NSBundle loadNibNamed:@"XtraPreviewImageView" owner:self];
	/*	NSString * xtraType = [xtra type];
		
		if ([xtraType isEqualToString:AIXtraTypeEmoticons])
			[NSBundle loadNibNamed:@"EmoticonPreviewView" owner:self];
		else if ([xtraType isEqualToString:AIXtraTypeDockIcon])
			[NSBundle loadNibNamed:@"DockIconPreviewView" owner:self];
		else if ([xtraType isEqualToString:AIXtraTypeMessageStyle])
			[NSBundle loadNibNamed:@"WebkitMessageStylePreviewView" owner:self];
		else if ([xtraType isEqualToString:AIXtraTypeStatusIcons]) {
			[NSBundle loadNibNamed:@"StatusIconPreviewView" owner:self];
		}
		else { //catchall behavior is to just show the readme
			[NSBundle loadNibNamed:@"XtraInfoView" owner:self];
			[showInfoControl setHidden:YES];
		}*/
	}
	if(previewController/* && previewContainerView*/)
	{
		NSView *pv = [previewController previewView];
		NSSize docSize = [previewContainerView documentVisibleRect].size;
		NSRect viewFrame = [pv frame];
		viewFrame.size.width = docSize.width;
		if([pv respondsToSelector:@selector(image)]) viewFrame.size.height = [[(NSImageView *)pv image]size].height;
		if(viewFrame.size.height < docSize.height) viewFrame.size.height = docSize.height;
		[pv setFrameSize:viewFrame.size];
		[previewContainerView setDocumentView:pv];
		[previewController setXtra:xtra];
		[previewContainerView setNeedsDisplay:YES];
	}	
}

- (IBAction) setShowsInfo:(id)sender
{
	if([sender selectedSegment] == 0)
		showInfo = NO;
	else
		showInfo = YES;
	[self updatePreview];
}

- (void)deleteXtrasAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertDefaultReturn)
	{
		NSFileManager * manager = [NSFileManager defaultManager];
		NSIndexSet * indices = [xtraList selectedRowIndexes];
		NSMutableSet * pathExtensions = [NSMutableSet set];
		NSString * path;
		for (int i = [indices lastIndex]; i >= 0; i--) {
			if ([indices containsIndex:i]) {
				path = [[selectedCategory objectAtIndex:i] path];
				[pathExtensions addObject:[path pathExtension]];
				[manager removeFileAtPath:path handler:nil];
			}
		}
		[xtraList selectRow:0 byExtendingSelection:NO];
		[selectedCategory removeObjectsAtIndexes:indices];
		[xtraList reloadData];
		/*
		 XXX this is ugly. We should use the AIXtraInfo's type instead of the path extension
		*/
		NSEnumerator * extEnu = [pathExtensions objectEnumerator];
		while((path = [extEnu nextObject])) //usually this will only run once
		{
			[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed
													  object:path];
		}
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

+ (BOOL) createXtraBundleAtPath:(NSString *)path 
{
	NSString *contentsPath  = [path stringByAppendingPathComponent:@"Contents"];
	NSString *resourcesPath = [contentsPath stringByAppendingPathComponent:@"Resources"];
	NSString *infoPlistPath = [contentsPath stringByAppendingPathComponent:@"Info.plist"];

	NSFileManager * manager = [NSFileManager defaultManager];
	NSString * name = [[path lastPathComponent] stringByDeletingPathExtension];
	if (![manager fileExistsAtPath:path]) {
		[manager createDirectoryAtPath:path attributes:nil];
		[manager createDirectoryAtPath:contentsPath attributes:nil];

		//Info.plist
		[[NSDictionary dictionaryWithObjectsAndKeys:
			@"English", kCFBundleDevelopmentRegionKey,
			name, kCFBundleNameKey,
			@"AdIM", @"CFBundlePackageType",
			[@"com.adiumx." stringByAppendingString:name], kCFBundleIdentifierKey,
			[NSNumber numberWithInt:1], @"XtraBundleVersion",
			@"1.0", kCFBundleInfoDictionaryVersionKey,
			nil] writeToFile:infoPlistPath atomically:YES];

		//Resources
		[manager createDirectoryAtPath:resourcesPath attributes:nil];
	}

	BOOL isDir = NO, success;
	success = [manager fileExistsAtPath:resourcesPath isDirectory:&isDir] && isDir;
	if (success)
		success = [manager fileExistsAtPath:infoPlistPath isDirectory:&isDir] && !isDir;
	return success;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == sidebar) {
		[cell setImage:[categoryImages objectAtIndex:row]];
		[cell setSubString:nil];
	}
	else {
		[cell setImage:[[selectedCategory objectAtIndex:row] icon]];
		[cell setSubString:nil];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == sidebar) {
		return [categoryNames count];
	}
	else {
		return [selectedCategory count];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == sidebar) {
		return [categoryNames objectAtIndex:row];
	}
	else {
		NSString * name = [[selectedCategory objectAtIndex:row] name];
		return (name != nil) ? name : @"";
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == xtraList) {
		AIXtraInfo *xtraInfo  = [AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[[selectedCategory objectAtIndex:[xtraList selectedRow]] path]]];
		if ([[xtraList selectedRowIndexes] count] == 1) {
			[previewController setXtra:xtraInfo];
		}
	}
	else if ([aNotification object] == sidebar) {
		[self setCategory:nil];
	}
}

@end
