//
//  CSCurrentChatsListViewController.m
//  Adium
//
//  Created by Chris Serino on Thu Jan 01 2004.
//

#import "CSCurrentChatsListViewController.h"
#import "AIMessageViewController.h"

#define CURRENT_CHATS_NIB @"Current Chats List"

@interface CSCurrentChatsListViewController (PRIVATE)

- (void)_tableClicked;

@end

@implementation CSCurrentChatsListViewController

#pragma mark Initiation

-(id)init
{   
	if (self = [super init]) {
		messageViewControllerArray = [[NSMutableArray array] retain];
		
		[NSBundle loadNibNamed:CURRENT_CHATS_NIB owner:self];
		[[adium notificationCenter] addObserver:view selector:@selector(reloadData) name:ListObject_AttributesChanged object:nil];
	}
	
	return self;
}

-(void)dealloc
{
	[messageViewControllerArray release];
	[[adium notificationCenter] removeObserver:view];
	
	[super dealloc];
}

#pragma mark NIB Handling

- (void)awakeFromNib
{
	[view setTarget:self];
	[view setAction:@selector(_tableClicked)];
}

#pragma mark Message View Controller Handlers
- (BOOL)messageViewControllerHasBeenCreatedForChat:(AIChat*)inChat
{
	NSEnumerator *messageViewControllerEnumerator;
	AIMessageViewController *currentMessageViewController;
	
	if ([messageViewControllerArray count] <= 0) return NO;
	
	messageViewControllerEnumerator = [messageViewControllerArray objectEnumerator];
	while (currentMessageViewController = [messageViewControllerEnumerator nextObject]) {
		if ([currentMessageViewController chat] == inChat) return YES;
	}
	return NO;
}

- (AIMessageViewController*)messageViewControllerForChat:(AIChat*)inChat
{
	AIMessageViewController *currentMessageViewController;
	if ([self messageViewControllerHasBeenCreatedForChat:inChat]) {
		NSEnumerator *messageViewControllerEnumerator = [messageViewControllerArray objectEnumerator];
		
		while (currentMessageViewController = [messageViewControllerEnumerator nextObject]) {
			NSLog(@"Looking through");
			if ([currentMessageViewController chat] == inChat) break;
		}
		NSLog(@"Message view was found");
	} else {
		currentMessageViewController = [[AIMessageViewController messageViewControllerForChat:inChat] retain];
		[messageViewControllerArray addObject:currentMessageViewController];
		[view reloadData];
		NSLog(@"Message view was created, not found");
	}
	return (currentMessageViewController);
}

- (int)count
{
	return [messageViewControllerArray count];
}

#pragma mark Chat handlers

- (void)openChat:(AIChat*)inChat
{
	[self messageViewControllerForChat:inChat];
}
- (void)setChat:(AIChat*)inChat
{
	[view selectRow:[messageViewControllerArray indexOfObject:[self messageViewControllerForChat:inChat]] byExtendingSelection:NO];
}

- (void)closeChat:(AIChat*)inChat
{
	[messageViewControllerArray removeObject:[self messageViewControllerForChat:inChat]];
	
	[view reloadData];
	[self _tableClicked];
}

- (AIChat*)activeChat
{
	int selectedRow = [view selectedRow];
	if (selectedRow >=0 && selectedRow < [messageViewControllerArray count])
		return ([[messageViewControllerArray objectAtIndex:selectedRow] chat]);
	return nil;
}

#pragma mark View

- (AIAlternatingRowTableView*)view
{
	return (view);
}

#pragma mark Private

- (void)_tableClicked
{
	int	selectedRow = [view selectedRow];
	NSLog(@"Table Clicked: %d", selectedRow);
    if(selectedRow >=0 && selectedRow < [messageViewControllerArray count]){
        [[adium interfaceController] setActiveChat:[self activeChat]];
    }
}

#pragma mark Table View Delegate Methods

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self _tableClicked];
}

#pragma mark Table View Data Source Methods
//Delete the selected row
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [[adium interfaceController] closeChat:[[messageViewControllerArray objectAtIndex:[view selectedRow]] chat]]; //Delete them
}

//Return the number of accounts
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([messageViewControllerArray count]);
}

//Return the account description or image
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	AIListObject	*inObject = [[[[messageViewControllerArray objectAtIndex:row] chat] participatingListObjects] objectAtIndex:0];
	NSString		*displayName = [inObject displayName];
    int currentUnviewed = [inObject integerStatusObjectForKey:@"UnviewedContent"];
	
    return((currentUnviewed > 0) ? [NSString stringWithFormat:@"%@ (%d)",displayName,currentUnviewed] : displayName);
}

/*
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragAccount = [accountArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE] owner:self];
    [pboard setString:@"Account" forType:ACCOUNT_DRAG_TYPE];
    
    return(YES);
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE]];
	
    if([avaliableType compare:@"AIAccount"] == 0){
        int	newIndex;
        
        //Select the moved account
        newIndex = [[adium accountController] moveAccount:tempDragAccount toIndex:row];
        [tableView_accountList selectRow:newIndex byExtendingSelection:NO];
		
        return(YES);
    }else{
        return(NO);
    }
}*/

@end
