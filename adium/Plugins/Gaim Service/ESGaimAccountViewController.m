//
//  ESGaimAccountView.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimAccountViewController.h"


@implementation ESGaimAccountViewController

//Nib to load
- (NSString *)nibName{
    return(@"GaimAccountView");    
}

//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
	//Load and add our auxiliary view and tabs if present
    NSString *auxiliaryNib = [self auxiliaryGaimAccountViewTabsNib];
    if (auxiliaryNib) {
        [NSBundle loadNibNamed:auxiliaryNib owner:self];
        
		//Add all auxiliary tabs
        [self loadAuxiliaryTabsFromTabView:view_auxiliaryGaimAccountTabView];
    }
}

//No auxiliary tabs by default
- (NSString *)auxiliaryGaimAccountViewTabsNib
{
    return nil;
}
@end
