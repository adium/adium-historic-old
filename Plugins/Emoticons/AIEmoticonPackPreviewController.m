//
//  AIEmoticonPackPreviewController.m
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIEmoticonPackPreviewController.h"
#import "AIEmoticonPackPreviewView.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonsPlugin.h"
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
