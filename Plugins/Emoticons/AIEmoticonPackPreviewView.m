//
//  AIEmoticonPackPreviewView.m
//  Adium
//
//  Created by Evan Schoenberg on 1/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIEmoticonPackPreviewView.h"
#import "AIEmoticonPack.h"

//Max size + bottom margin should equal previewView's height
#define EMOTICON_MAX_SIZE           20
#define EMOTICON_SPACING            4

#define EMOTICON_LEFT_MARGIN        2		//Left padding of cell
#define EMOTICON_BOTTOM_MARGIN      2

static  float   distanceBetweenEmoticons = 0;

@implementation AIEmoticonPackPreviewView

- (void)setEmoticonPack:(AIEmoticonPack *)inEmoticonPack
{
	emoticonPack = [inEmoticonPack retain];
}

- (void)dealloc
{
	[emoticonPack release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSRect	cellFrame = [view_preview frame];
	NSRect	nameFrame = [view_name frame];
	
	[super drawRect:rect];
	
	if(NSIntersectsRect(rect,nameFrame)){
		//Display the title, truncating as necessary
		NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				lineBreakMode:NSLineBreakByTruncatingTail];
		[paragraphStyle setMaximumLineHeight:nameFrame.size.height];

		[[emoticonPack name] drawInRect:nameFrame
						 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
							 paragraphStyle, NSParagraphStyleAttributeName,
							 [NSFont systemFontOfSize:12], NSFontAttributeName/*, 
							 SELECTED_TEXT_COLOR, NSForegroundColorAttributeName*/, nil]];
	}

	if(NSIntersectsRect(rect,cellFrame)){		
		NSEnumerator    *enumerator;
		AIEmoticon      *emoticon;
		float			x = 0;

		//Display a few preview emoticons
		enumerator = [[emoticonPack emoticons] objectEnumerator];
		while((x < cellFrame.size.width) && (emoticon = [enumerator nextObject])){
			NSImage *image = [emoticon image];
			NSSize  imageSize = [image size];
			NSRect  destRect;
			
			//Scale the emoticon, preserving its proportions.
			if(imageSize.width > EMOTICON_MAX_SIZE){
				destRect.size.width = EMOTICON_MAX_SIZE;
				destRect.size.height = imageSize.height * (EMOTICON_MAX_SIZE / imageSize.width);
			}else if(imageSize.height > EMOTICON_MAX_SIZE){
				destRect.size.width = imageSize.width * (EMOTICON_MAX_SIZE / imageSize.height);
				destRect.size.height = EMOTICON_MAX_SIZE;
			}else{
				destRect.size.width = imageSize.width;
				destRect.size.height = imageSize.height;            
			}
			
			//Position it
			destRect.origin.x = cellFrame.origin.x + x;
			destRect.origin.y = cellFrame.origin.y + EMOTICON_BOTTOM_MARGIN;

			//If there is enough room, draw the image
			if((destRect.origin.x + destRect.size.width) < (cellFrame.origin.x + cellFrame.size.width)){
				[image drawInRect:destRect
						 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
						operation:NSCompositeSourceOver
						 fraction:1.0];
			}
			
			//Move over for the next emoticon, leaving some space
			float desiredIncrease = destRect.size.width + EMOTICON_SPACING;
			if (distanceBetweenEmoticons < desiredIncrease)
				distanceBetweenEmoticons = desiredIncrease;
			x += distanceBetweenEmoticons;
		}
	}
}

@end
