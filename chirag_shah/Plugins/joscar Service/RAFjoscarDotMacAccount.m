//
//  RAFjoscarDotMacAccount.m
//  Adium
//
//  Created by Augie Fackler on 1/10/06.
//

#import "RAFjoscarDotMacAccount.h"


@implementation RAFjoscarDotMacAccount

- (NSString *)serversideUID
{
	NSString	 *userNameWithMacDotCom;
	
	if (([UID rangeOfString:@"@mac.com"
					options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound)) {
		userNameWithMacDotCom = UID;
	} else {
		userNameWithMacDotCom = [UID stringByAppendingString:@"@mac.com"];
	}

	return userNameWithMacDotCom;
}

/*
 * @brief A formatted UID which may include additional necessary identifying information.
 *
 * For example, an AIM account (tekjew) and a .Mac account (tekjew@mac.com, entered only as tekjew) may appear identical
 * without service information (tekjew). The explicit formatted UID is therefore tekjew@mac.com
 */
- (NSString *)explicitFormattedUID
{
	return [self serversideUID];
}

@end
