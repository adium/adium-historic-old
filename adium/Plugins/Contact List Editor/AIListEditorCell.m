//
//  AIListEditorCell.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListEditorCell.h"


@implementation AIListEditorCell

- (id)init
{
    [super init];

	listObject = nil;
	
    return(self);
}

- (void)dealloc
{	
	[listObject release];
    [super dealloc];
}

- (void)setRepresentedListObject:(AIListObject *)inObject
{
	if(inObject != listObject){
		[listObject release];
		listObject = [inObject retain];		
	}
}

- (AIListObject *)listObject
{
	return(listObject);
}


@end
