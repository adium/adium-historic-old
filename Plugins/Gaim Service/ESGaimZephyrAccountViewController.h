//
//  ESGaimZephyrAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 8/12/04.
//

#include "AIAccountViewController.h"

@interface ESGaimZephyrAccountViewController : AIAccountViewController {
	IBOutlet	NSButton	*checkBox_exportAnyone;
	IBOutlet	NSButton	*checkBox_exportSubs;
	IBOutlet	NSTextField	*textField_exposure;
	IBOutlet	NSTextField	*textField_encoding;
}

@end
