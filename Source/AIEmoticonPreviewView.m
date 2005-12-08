//
//  AIEmoticonPreviewView.m
//  Adium
//
//  Created by David Smith on 12/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIEmoticonPreviewView.h"
#import "AIEmoticonPack.h"
#import "AIEmoticon.h"

@implementation AIEmoticonPreviewView

- (void) setXtraPath:(NSString *)path
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	NSArray * emoticons = [[AIEmoticonPack emoticonPackFromPath:path] emoticons];
	NSEnumerator * e = [emoticons objectEnumerator];
	NSImage * image;
	NSSize size;
	NSSize maxEmoticonSize = NSZeroSize;
	AIEmoticon * emote;
	while((emote = [e nextObject]))
	{
		image = [emote image];
		if(image) {
			[images addObject:image];
			size = [image size];
			maxEmoticonSize.width = (size.width > maxEmoticonSize.width) ? size.width : maxEmoticonSize.width;	
			maxEmoticonSize.height = (size.height > maxEmoticonSize.height) ? size.height : maxEmoticonSize.height;

		}
	}
	[gridView setImageSize:maxEmoticonSize];
#warning this is SUCH a hack
	[(NSSplitView *)[[self superview] superview] adjustSubviews];
}


@end
