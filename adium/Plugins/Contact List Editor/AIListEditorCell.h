//
//  AIListEditorCell.h
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface AIListEditorCell : AIImageTextCell {
	AIListObject 	*listObject;
}

- (void)setRepresentedListObject:(AIListObject *)inObject;
- (AIListObject *)listObject;

@end
