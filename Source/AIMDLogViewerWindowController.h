//
//  AIMDLogViewerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AILogViewerWindowController.h"

@interface AIMDLogViewerWindowController : AILogViewerWindowController {
	NSMetadataQuery	*currentQuery;
	int				lastResult;
}

@end
