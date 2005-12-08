//
//  AIDockIconPreviewView.h
//  Adium
//
//  Created by David Smith on 12/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIXtraPreviewView.h"
#import "AIImageGridXtraPreviewView.h"

@interface AIDockIconPreviewView : AIImageGridXtraPreviewView <AIXtraPreviewView>
{
	AIImageGridView * gridView;
	NSMutableArray * images;
}

@end
