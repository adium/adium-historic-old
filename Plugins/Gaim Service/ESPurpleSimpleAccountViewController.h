//
//  ESPurpleSimpleAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import <Adium/AIAccountViewController.h>

@interface ESPurpleSimpleAccountViewController : AIAccountViewController {
	IBOutlet	NSButton	*checkBox_publishStatus;
	IBOutlet	NSButton	*checkBox_useUDP;
}

@end
