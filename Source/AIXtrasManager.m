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
	[NSBundle loadNibNamed:@"XtrasManager" owner:self];
	[self setSelectedCategory:categoryPopup];
}

- (void) xtrasChanged:(NSNotification *)not
{
	[self loadXtras];//OMG HAX
}

- (void) loadXtras
{
	if(xtrasCategories) [xtrasCategories release];
	xtrasCategories = [[NSMutableDictionary alloc] init];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIContactListDirectory, AIAllDomainsMask, YES)] forKey:@"Contact List Styles"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIMessageStylesDirectory, AIAllDomainsMask, YES)] forKey:@"Message View Styles"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIStatusIconsDirectory, AIAllDomainsMask, YES)] forKey:@"Status Icons"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AISoundsDirectory, AIAllDomainsMask, YES)] forKey:@"Sounds"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIDockIconsDirectory, AIAllDomainsMask, YES)] forKey:@"Dock Icons"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIEmoticonsDirectory, AIAllDomainsMask, YES)] forKey:@"Emoticons"];
	[xtrasCategories setObject:[self arrayOfXtrasAtPaths:AISearchPathForDirectoriesInDomains(AIScriptsDirectory, AIAllDomainsMask, YES)] forKey:@"Scripts"];
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
	[super dealloc];
}

- (IBAction) setSelectedCategory:(id)sender
{
	[categoryController setContent:[xtrasCategories objectForKey:[sender titleOfSelectedItem]]];
}

- (NSArray *)categoryNames
{
	return [xtrasCategories allKeys];
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

@end
