//
//  ESGaimSimpleAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.
//

#import <Adium/AIAccountViewController.h>

@interface ESGaimSimpleAccountViewController : AIAccountViewController {
	IBOutlet	NSButton	*checkBox_publishStatus;
	IBOutlet	NSButton	*checkBox_useUDP;
}

@end
