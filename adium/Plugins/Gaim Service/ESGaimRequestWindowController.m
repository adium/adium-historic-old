//
//  ESGaimRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Apr 14 2004.
//

#import "ESGaimRequestWindowController.h"

#define MULTILINE_WINDOW_NIB	@"GaimMultilineRequestWindow"
#define SINGLELINE_WINDOW_NIB   @"GaimSinglelineRequestWindow"

@implementation ESGaimRequestWindowController
 
+ (void)showInputWindowWithDict:(NSDictionary *)inInfoDict multiline:(BOOL)multiline masked:(BOOL)inMasked
{
	ESGaimRequestWindowController	*requestWindowController;
	
	requestWindowController = [[self alloc] initWithWindowNibName:(multiline ? MULTILINE_WINDOW_NIB : SINGLELINE_WINDOW_NIB)
														   masked:inMasked
														 withDict:inInfoDict];
	
	[requestWindowController showWindow:nil];
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName masked:(BOOL)inMasked withDict:(NSDictionary *)inInfoDict
{
    [super initWithWindowNibName:windowNibName];
	masked = inMasked;
	infoDict = [inInfoDict retain];
	
    return(self);
}


@end
