//
//  ESGaimRequestWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Apr 14 2004.
//

#import "CBGaimServicePlugin.h"

@interface ESGaimRequestWindowController : AIWindowController {
	BOOL			masked;
	NSDictionary	*infoDict;
}

+ (void)showInputWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline masked:(BOOL)masked;
- (id)initWithWindowNibName:(NSString *)windowNibName masked:(BOOL)inMasked withDict:(NSDictionary *)inInfoDict;

@end
