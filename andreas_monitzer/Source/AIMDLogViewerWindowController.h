//
//  AIMDLogViewerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AIAbstractLogViewerWindowController.h"

@interface AIMDLogViewerWindowController : AIAbstractLogViewerWindowController {
	IBOutlet	NSDatePicker	*datePicker;
	
	SKSearchRef currentSearch;
}

- (IBAction)selectDate:(id)sender;

@end
