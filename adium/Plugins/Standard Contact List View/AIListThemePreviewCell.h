//
//  AIListThemePreviewCell.h
//  Adium
//
//  Created by Adam Iser on 8/11/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

@interface AIListThemePreviewCell : AIGradientCell {
	NSArray			*colorKeyArray;
	NSDictionary	*themeDict;
}

- (void)setThemeDict:(NSDictionary *)inDict;

@end
