/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIOutOfSyncWindowController.h"
#import <Adium/Adium.h>
#import "AIOutOfSyncEntry.h"

#define SYNC_WINDOW_NIB		@"OutOfSync"		//Filename of the out of sync window nib

/*    
    Array
        Dict
            "Account" - AIAccount
            "Entries" - NSMutableArray
                AIOutOfSyncEntry
*/

@interface AIOutOfSyncWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (void)addSyncConditionForAccount:(AIAccount *)inAccount handle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup;
- (void)refreshConditionTable;
@end

@implementation AIOutOfSyncWindowController

static AIOutOfSyncWindowController	*sharedInstance = nil;
+ (void)outOfSyncConditionForAccount:(AIAccount *)inAccount handle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:SYNC_WINDOW_NIB];
        [sharedInstance showWindow:nil];
    }

    [sharedInstance addSyncConditionForAccount:inAccount handle:inHandle serverGroup:inServerGroup];
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
    
    conditionArray = [[NSMutableArray alloc] init];

    return(self);
}

- (void)dealloc
{
    [conditionArray release]; conditionArray = nil;

    [super dealloc];
}

- (void)windowDidLoad
{
    [outlineView_conditions setIndentationPerLevel:10];
}

- (void)addSyncConditionForAccount:(AIAccount *)inAccount handle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup
{
    NSEnumerator	*enumerator;
    NSMutableDictionary	*dict;
    BOOL		exists = NO;

    //Find the existing dict for this account
    enumerator = [conditionArray objectEnumerator];
    while((dict = [enumerator nextObject])){
        if([dict objectForKey:@"Account"] == inAccount){
            exists = YES;
            break;
        }
    }

    //Create a new one if it doesn't exist
    if(!exists){
        //Create the dict
        dict = [[[NSMutableDictionary alloc] init] autorelease];
        [conditionArray addObject:dict];

        //Stuff it with the account and entry array
        [dict setObject:inAccount forKey:@"Account"];
        [dict setObject:[NSMutableArray array] forKey:@"Entries"];
    }

    //Add the entry
    [(NSMutableArray *)[dict objectForKey:@"Entries"] addObject:[AIOutOfSyncEntry entryWithHandle:inHandle serverGroup:inServerGroup]];
    
    [self refreshConditionTable];

    //Expand the account flippy triangle
    [outlineView_conditions expandItem:dict];
}

- (void)refreshConditionTable
{
    [outlineView_conditions reloadData];
}

- (IBAction)selectRadio:(id)sender
{
    [radio_useCurrentGroups setState:0];
    [radio_useNewGroups setState:0];
    [radio_allowDuplicates setState:0];

    [sender setState:1];
}

//Disconnect from all accounts with a sync condition
- (IBAction)disconnect:(id)sender
{
    NSEnumerator	*enumerator;
    NSMutableDictionary	*dict;

    //Disconnect every account with a sync condition
    enumerator = [conditionArray objectEnumerator];
    while((dict = [enumerator nextObject])){
        AIAccount	*account;

        if([account conformsToProtocol:@protocol(AIAccount_Status)]){
            //Disconnect
            [(AIAccount<AIAccount_Status> *)account disconnect];
        }
    }
}

//Sync all handles
- (IBAction)sync:(id)sender
{
    NSEnumerator	*enumerator;
    NSMutableDictionary	*dict;

    enumerator = [conditionArray objectEnumerator];
    while((dict = [enumerator nextObject])){
        AIAccount		*account = [dict objectForKey:@"Account"];
        NSEnumerator		*entryEnumerator;
        AIOutOfSyncEntry	*entry;

        entryEnumerator = [[dict objectForKey:@"Entries"] objectEnumerator];
        while((entry = [entryEnumerator nextObject])){
            
            //Remove the existing handles and re-add them into the correct groups
          //  if([radio_useCurrentGroups state]){ 

            if([account conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){ //Account supports groups
                [(AIAccount<AIAccount_GroupedContacts> *)account moveObject:[entry handle]
                                                                 fromGroup:[entry serverGroup]
                                                                   toGroup:[[entry handle] containingGroup]];
            }

          //  }else if([radio_useNewGroups state]){ //Apply locally            
                //Call moveHandle on the local handle to move it        
          //  }else{ //Allow Duplicates
          //  }
        }
    }
    
    //Flush the conditions
    [self closeWindow:nil];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([conditionArray objectAtIndex:index]);
    }else{
        return([[item objectForKey:@"Entries"] objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return(item != nil && [item isKindOfClass:[NSMutableDictionary class]]);
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    int	count;
    
    if(item == nil){
        count = [conditionArray count];
    
    }else{
        count = [(NSMutableArray *)[item objectForKey:@"Entries"] count];
    }

    return(count);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString	*identifier = [tableColumn identifier];

    if([item isKindOfClass:[NSMutableDictionary class]]){
        if([identifier compare:@"handle"] == 0){
            NSAttributedString	*string;
            
            string = [[NSAttributedString alloc] initWithString:[[item objectForKey:@"Account"] accountDescription] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:11],NSFontAttributeName,nil]];

            return([string autorelease]);

        }else{
            return(@"");
        }

    }else{
        if([identifier compare:@"handle"] == 0){
            return([[item handle] displayName]);
            
        }else if([identifier compare:@"local"] == 0){
            return([[[item handle] containingGroup] displayName]);
            
        }else{
            return([[item serverGroup] displayName]);
            
        }
    }
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease];
    sharedInstance = nil;

    return(YES);
}

@end







