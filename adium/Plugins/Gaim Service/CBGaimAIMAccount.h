//
//  CBGaimAIMAccount.h
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimOscarAccount.h"
#import "aim.h"

@interface CBGaimAIMAccount : CBGaimOscarAccount {

}

//Overriden from CBGAimOscarAccount
- (void)initAccount;
- (NSString *)serviceID;
- (NSString *)accountDescription;
- (id <AIAccountViewController>)accountView;
@end
