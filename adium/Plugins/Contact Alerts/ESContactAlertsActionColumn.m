//
//  ESContactAlertsActionColumn.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Aug 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESContactAlertsActionColumn.h"
#import "ESContactAlerts.h"
#import <AIUtilities/AIUtilities.h>

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

- (void)setPrefAlertsArray:(NSMutableArray *)inPrefAlertsArray
{
    prefAlertsArray = inPrefAlertsArray;
}

- (id)dataCellForRow:(int)row
{
    NSPopUpButtonCell			*dataCell;
    dataCell = [[AITableViewPopUpButtonCell alloc] init];

    if (row != -1)
    {
        ESContactAlerts				*instance;
        NSMenu					*actionMenu;
        instance = [prefAlertsArray objectAtIndex:row];

        actionMenu = [instance actionListMenu];

        [dataCell setMenu:actionMenu];
        [dataCell setControlSize:NSSmallControlSize];
        [dataCell setFont:[NSFont menuFontOfSize:11]];
        [dataCell setBordered:NO];
    }
 
    return dataCell;
}

@end
