//
//  ESContactAlertsActionColumn.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Aug 09 2003.
//
#import "ESContactAlerts.h"

@interface ESContactAlertsActionColumn : NSTableColumn {
    ESContactAlerts *	instance;
}

- (void)setInstance:(ESContactAlerts *)inInstance;

@end
