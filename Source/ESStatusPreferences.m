//
//  ESStatusPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESStatusPreferences.h"


@implementation ESStatusPreferences

/*
 * @brief Category
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Status);
}
/*
 * @brief Label
 */
- (NSString *)label{
    return(AILocalizedString(@"Status",nil));
}

/*
 * @brief Nib name
 */
- (NSString *)nibName{
    return(@"StatusPreferences");
}

/*
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	
}

/*
 * @brief Preference view is closing
 */
- (void)viewWillClose
{

}

@end
