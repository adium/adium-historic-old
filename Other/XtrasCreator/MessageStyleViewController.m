//
//  MessageStyleViewController.m
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "MessageStyleViewController.h"


@implementation MessageStyleViewController

+ (id <ViewController>)controller
{
	MessageStyleViewController * c = [[MessageStyleViewController alloc] init];
	[NSBundle loadNibNamed:@"MessageStyleView" owner:c];
	return [c autorelease];
}

- (NSView *)view
{
	return view;
}

- (id) init
{
	if((self = [super init]))
	{
		
	}
	return self;
}

- (void) writeCustomFilesToPath:(NSString *)path
{
	path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Info.plist"];
	NSMutableDictionary * info = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	[info setObject:[DisplayNameForNoVariantField stringValue] forKey:@"DisplayNameForNoVariant"];
	[info setObject:[NSNumber numberWithInt:[[DefaultFontSizeField stringValue]intValue]] forKey:@"DefaultFontSize"];
	[info setObject:[DefaultFontSizeField stringValue] forKey:@"DefaultFontSize"];
	[info writeToFile:path atomically:YES];
}

@end
