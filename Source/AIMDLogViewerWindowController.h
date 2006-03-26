//
//  AIMDLogViewerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AIAbstractLogViewerWindowController.h"

@interface AIMDLogViewerWindowController : AIAbstractLogViewerWindowController {
	NSMetadataQuery	*currentQuery;
	int				lastResult;
	
	IBOutlet	NSTableView	*tableView_fromAccounts;
	IBOutlet	NSTableView	*tableView_toContacts;
	IBOutlet	NSTableView	*tableView_dates;
}

@end
