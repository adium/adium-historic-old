//
//  AIListThemePreviewCell.h
//  Adium
//
//  Created by Adam Iser on 8/11/04.
//

@interface AIListThemePreviewCell : AIGradientCell {
	NSArray			*colorKeyArray;
	NSDictionary	*themeDict;
}

- (void)setThemeDict:(NSDictionary *)inDict;

@end
