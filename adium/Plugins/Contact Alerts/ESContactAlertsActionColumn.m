//
//  ESContactAlertsActionColumn.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Aug 09 2003.
//

#import "ESContactAlertsActionColumn.h"
#import "ESContactAlerts.h"

@implementation ESContactAlertsActionColumn

- (id)init
{
    [super init];

    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setInstance:(ESContactAlerts *)inInstance
{
    instance = inInstance;
}

- (id)dataCellForRow:(int)row
{
    NSPopUpButtonCell			*dataCell;
    dataCell = [[AITableViewPopUpButtonCell alloc] init];

    if (row != -1)
    {
        NSMenu			*actionMenu;
        
        actionMenu = [instance actionListMenu];

        [dataCell setMenu:actionMenu];
        [dataCell setControlSize:NSSmallControlSize];
        [dataCell setFont:[NSFont menuFontOfSize:11]];
        [dataCell setBordered:NO];
    }
 
    return dataCell;
}

@end
