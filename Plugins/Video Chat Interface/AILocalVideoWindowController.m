//
//  AILocalVideoWindowController.m
//  Adium
//
//  Created by Adam Iser on 12/5/04.
//

#import "AILocalVideoWindowController.h"

@implementation AILocalVideoWindowController

AILocalVideoWindowController	*sharedLocalVideoWindowInstance = nil;

+ (void)showLocalVideoWindow
{
	if(!sharedLocalVideoWindowInstance){
		sharedLocalVideoWindowInstance = [[self alloc] initWithWindowNibName:@"LocalVideoWindow"];
		[sharedLocalVideoWindowInstance showWindow:nil];
	}
}

//
- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[super initWithWindowNibName:windowNibName];

	//Observe local video
	localVideo = [[AIVideoCapture alloc] initWithSize:NSMakeSize(320,240)
									  captureInterval:(1.0/24.0)
											 delegate:self];
	[localVideo beginCapturingVideo];
	
	return(self);
}

//
- (void)dealloc
{
	[localVideo stopCapturingVideo];
	[localVideo release];
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[[self window] setAspectRatio:[[self window] frame].size];
	[[self window] setBackgroundColor:[NSColor blackColor]];
}

//Close our shared instance
- (BOOL)windowShouldClose:(id)sender
{
	[sharedLocalVideoWindowInstance autorelease];
	sharedLocalVideoWindowInstance = nil;
	
	return(YES);
}

//Update video frame
- (void)videoCapture:(AIVideoCapture *)videoCapture frameReady:(NSImage *)image
{
	[videoImageView setImage:image];
}

@end
