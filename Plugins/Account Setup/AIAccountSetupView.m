//
//  AIAccountSetupView.m
//  Adium
//
//  Created by Adam Iser on 12/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIAccountSetupView.h"

@interface AIAccountSetupView (PRIVATE)
- (void)_initAccountSetupView;
@end

@implementation AIAccountSetupView

//Init
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initAccountSetupView];
    return(self);
}

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	[self _initAccountSetupView];
	return(self);
}

- (void)_initAccountSetupView
{
	adium = [[AIObject sharedAdiumInstance] retain];
}


//Dealloc
- (void)dealloc
{	
	[super dealloc];
}

//View will load
- (void)viewDidLoad
{

}

//View will close
- (void)viewWillClose
{
	
}

//Desired size of this view
- (NSSize)desiredSize
{
	return(NSMakeSize(0,0));
}

@end
