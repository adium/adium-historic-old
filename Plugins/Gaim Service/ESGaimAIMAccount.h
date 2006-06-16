//
//  ESGaimAIMAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "CBGaimOscarAccount.h"

@interface ESGaimAIMAccount : CBGaimOscarAccount {
	NSMutableDictionary	*directIMQueue;
}

@end
