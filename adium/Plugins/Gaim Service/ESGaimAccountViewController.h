//
//  ESGaimAccountView.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

@interface ESGaimAccountViewController : AIAccountViewController {
    IBOutlet    NSTabView       *view_auxiliaryGaimAccountTabView;
}

-(NSString *)auxiliaryGaimAccountViewTabsNib;

@end
