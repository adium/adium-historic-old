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

#import "AIEmoticonPackPreviewController.h"
#import "AIEmoticonPackPreviewView.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonController.h"
#import "AIEmoticonPreferences.h"

@interface AIEmoticonPackPreviewController (PRIVATE)
- (id)initForPack:(AIEmoticonPack *)inPack withPlugin:(AIEmoticonsPlugin *)inPlugin preferences:(AIEmoticonPreferences *)inPreferences;
@end

@implementation AIEmoticonPackPreviewController

+ (id)previewControllerForPack:(AIEmoticonPack *)inPack withPlugin:(AIEmoticonsPlugin *)inPlugin preferences:(AIEmoticonPreferences *)inPreferences
{
	return([[[self alloc] initForPack:inPack withPlugin:inPlugin preferences:inPreferences] autorelease]);
}

- (id)initForPack:(AIEmoticonPack *)inPack withPlugin:(AIEmoticonsPlugin *)inPlugin preferences:(AIEmoticonPreferences *)inPreferences
{
	if(self = [super init]){
		emoticonPack = [inPack retain];
		plugin = [inPlugin retain];
		preferences = [inPreferences retain];

		[NSBundle loadNibNamed:@"EmoticonPackPreview" owner:self];
	}
	
	return self;
}

- (void)dealloc
{
	[emoticonPack release];
	[plugin release];
	[preferences release];
	[previewView release];

	[super dealloc];
}

- (IBAction)togglePack:(id)sender
{
	[plugin setEmoticonPack:emoticonPack enabled:![emoticonPack isEnabled]];
	[preferences toggledPackController:self];
}

- (void)awakeFromNib
{
	[checkBox_enablePack setState:[emoticonPack isEnabled]];
	[previewView setEmoticonPack:emoticonPack];
}

- (NSView *)view
{
	return(previewView);
}

- (AIEmoticonPack *)emoticonPack
{
	return emoticonPack;	
}

@end
