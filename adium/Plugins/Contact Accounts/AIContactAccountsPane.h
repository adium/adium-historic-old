//
//  AIContactAccountsPane.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIContactAccountsPane : AIContactInfoPane {
	IBOutlet	AIAlternatingRowTableView	*tableView_accounts;

	AIListObject			*listObject;
	NSArray					*accounts;
}

@end
