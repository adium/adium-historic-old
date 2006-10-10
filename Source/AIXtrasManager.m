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
#import "AIPathUtilities.h"
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIGradientCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <Adium/AIDockControllerProtocol.h>

#import "AIXtraPreviewController.h"

#define ADIUM_XTRAS_PAGE					AILocalizedString(@"http://www.adiumxtras.com/","Adium xtras page. Localized only if a translated version exists.")

@implementation AIXtrasManager

static AIXtrasManager *manager;

+ (AIXtrasManager *) sharedManager
{
	return manager;
}

- (void)installPlugin
{
	manager = self;
}

- (void)showXtras
{
	[self loadXtras];

	if(![window isVisible]) {
		showInfo = NO;
		
		[[adium notificationCenter] addObserver:self
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

		[deleteButton setLocalizedString:AILocalizedStringFromTable(@"Delete", @"Buttons", nil)];
		[button_getMoreXtras setLocalizedString:AILocalizedStringFromTable(@"Get More Xtras", @"Buttons", "Button in the Xtras Manager to go to adiumxtras.com to get more adiumxtras")];

		[self setCategory:nil];
	}
		
	[window makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[adium notificationCenter] removeObserver:self
										  name:Adium_Xtras_Changed
										object:nil];
	
	[categories release]; categories = nil;
}


- (void)xtrasChanged:(NSNotification *)not
{
	//Clear our cache of loaded Xtras
	[self loadXtras];
	
	//Now redisplay our current category, in case it changed
	[self setCategory:nil];
}

int categorySort(id categoryA, id categoryB, void * context)
{
	return [[categoryA objectForKey:@"Name"] caseInsensitiveCompare:[categoryB objectForKey:@"Name"]];
}

- (void)loadXtras
{
	[categories release];
	categories = [[NSMutableArray alloc] init];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIMessageStylesDirectory], @"Directory",
		AILocalizedString(@"Message Styles", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumMessageStyle"], @"Image", nil]];

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIContactListDirectory], @"Directory",
		AILocalizedString(@"Contact List Themes", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumListTheme"], @"Image", nil]];
	

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIStatusIconsDirectory], @"Directory",
		AILocalizedString(@"Status Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumStatusIcons"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AISoundsDirectory], @"Directory",
		AILocalizedString(@"Sound Sets", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumSoundset"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIDockIconsDirectory], @"Directory",
		AILocalizedString(@"Dock Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumIcon"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIEmoticonsDirectory], @"Directory",
		AILocalizedString(@"Emoticons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumEmoticonset"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIScriptsDirectory], @"Directory",
		AILocalizedString(@"Scripts", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumScripts"], @"Image", nil]];

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:AIServiceIconsDirectory], @"Directory",
		AILocalizedString(@"Service Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumServiceIcons"], @"Image", nil]];
	
	[categories sortUsingFunction:categorySort context:NULL];
}

- (NSArray *)arrayOfXtrasAtPaths:(NSArray *)paths
{
	NSMutableArray	*contents = [NSMutableArray array];
	NSEnumerator	*dirEnu;
	NSString		*path, *xtraName;
	NSFileManager	*manager = [NSFileManager defaultManager];

	dirEnu = [paths objectEnumerator];
	while ((path = [dirEnu nextObject])) {
		NSEnumerator	*xEnu;

		xEnu = [[manager directoryContentsAtPath:path] objectEnumerator];
		while ((xtraName = [xEnu nextObject])) {
			if (![xtraName hasPrefix:@"."]) {
				[contents addObject:[AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:xtraName]]]];
			}
		}
	}

	return contents;
}

- (void)dealloc
{
	[categories release];

	[super dealloc];
}

- (NSArray *)xtrasForCategoryAtIndex:(int)inIndex
{
	if (inIndex == -1) return nil;

	NSDictionary	*xtrasDict = [categories objectAtIndex:inIndex];
	NSArray			*xtras;
	
	if (!(xtras = [xtrasDict objectForKey:@"Xtras"])) {
		xtras = [self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains([[xtrasDict objectForKey:@"Directory"] intValue],
																			  AIAllDomainsMask & ~AIInternalDomainMask,
																			  YES)];
		NSMutableDictionary *newDictionary = [xtrasDict mutableCopy];
		[newDictionary setObject:xtras forKey:@"Xtras"];
		[categories replaceObjectAtIndex:inIndex
							  withObject:newDictionary];
		[newDictionary release];
	}
	
	return xtras;
}

- (IBAction)setCategory:(id)sender
{
	[selectedCategory autorelease];
	selectedCategory = [[self xtrasForCategoryAtIndex:[sidebar selectedRow]] retain];

	[xtraList selectRow:0 byExtendingSelection:NO];
	[xtraList reloadData];

	[self updatePreview];
}

- (void)updatePreview
{
	AIXtraInfo *xtra = nil;

	if ([selectedCategory count] > 0 && [xtraList selectedRow] != -1) {
		xtra = [selectedCategory objectAtIndex:[xtraList selectedRow]];
	}

	if (xtra) {
		//[showInfoControl setHidden:NO];
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
			else if ([xtraType isEqualToString:AIXtraTypeServiceIcons]) {
				[NSBundle loadNibNamed:@"ServiceIconPreviewView" owner:self];
			}
			else { //catchall behavior is to just show the readme
				[NSBundle loadNibNamed:@"XtraInfoView" owner:self];
				[showInfoControl setHidden:YES];
			}*/
		}
		if (previewController/* && previewContainerView*/) {
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
}

- (IBAction) setShowsInfo:(id)sender
{
	showInfo = ([sender selectedSegment] != 0);

	[self updatePreview];
}

- (void)deleteXtrasAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		NSFileManager * manager = [NSFileManager defaultManager];
		NSIndexSet * indices = [xtraList selectedRowIndexes];
		NSMutableSet * pathExtensions = [NSMutableSet set];
		NSString * path;
		for (int i = [indices lastIndex]; i >= 0; i--) {
			if ([indices containsIndex:i]) {
				path = [[selectedCategory objectAtIndex:i] path];
				[pathExtensions addObject:[path pathExtension]];
				[manager trashFileAtPath:path];
			}
		}
		[xtraList selectRow:0 byExtendingSelection:NO];
		[selectedCategory removeObjectsAtIndexes:indices];
		[xtraList reloadData];
		/*
		 XXX this is ugly. We should use the AIXtraInfo's type instead of the path extension
		*/
		NSEnumerator * extEnu = [pathExtensions objectEnumerator];
		while ((path = [extEnu nextObject])) { //usually this will only run once
			[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed
													  object:path];
		}
	}
}

- (IBAction) deleteXtra:(id)sender
{
	int selectionCount = [[xtraList selectedRowIndexes] count];

	NSAlert * warning = [NSAlert alertWithMessageText:((selectionCount > 1) ?
													   [NSString stringWithFormat:AILocalizedString(@"Delete %i Xtras?", nil), selectionCount] :
													   AILocalizedString(@"Delete Xtra?", nil))
										defaultButton:AILocalizedString(@"Delete", nil)
									  alternateButton:AILocalizedString(@"Cancel", nil)
										  otherButton:nil
							informativeTextWithFormat:((selectionCount > 1) ?
													   AILocalizedString(@"The selected Xtras will be moved to the Trash.", nil) :
													   AILocalizedString(@"The selected Xtra will be moved to the Trash.", nil))];
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
		[cell setImage:[[categories objectAtIndex:row] objectForKey:@"Image"]];
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
		return [categories count];
	}
	else {
		return [selectedCategory count];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == sidebar) {
		return [[categories objectAtIndex:row] objectForKey:@"Name"];
	} else {
		NSString * name = [[selectedCategory objectAtIndex:row] name];
		return (name != nil) ? name : @"";
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == xtraList) {
		//int	selectedRow = [xtraList selectedRow];
		//if ((selectedRow >= 0) && (selectedRow < [selectedCategory count])) {
			//AIXtraInfo *xtraInfo  = [AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[[selectedCategory objectAtIndex:selectedRow] path]]];
			if ([[xtraList selectedRowIndexes] count] > 0)
				[deleteButton setEnabled:YES];
		//	if ([[xtraList selectedRowIndexes] count] == 1)
		//		[previewController setXtra:xtraInfo];
		//	else
		//		[deleteButton setEnabled:NO];
		//}
		
	} else if ([aNotification object] == sidebar) {
		[self setCategory:nil];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteXtra:tableView];
}

@end
