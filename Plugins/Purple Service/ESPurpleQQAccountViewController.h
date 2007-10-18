//
//  ESPurpleQQAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccountViewController.h>

@interface ESPurpleQQAccountViewController : AIAccountViewController {
	IBOutlet	NSButton	*checkBox_useTCP;
	IBOutlet	NSTextField *label_connection;
}

@end
