//
//  AIBrowser.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIBrowser.h"
#import "AIBrowserColumn.h"

#define COLUMN_WIDTH 	140

@interface AIBrowser (PRIVATE)
- (void)_init;
- (AIBrowserColumn *)newColumnForObject:(id)object;
- (void)addColumn:(AIBrowserColumn *)column;
- (void)removeLastColumn;
@end

@implementation AIBrowser

- (id)init{
	[super init];
	[self _init];
	return(self);
}

- (id)initWithFrame:(NSRect)frameRect{
	[super initWithFrame:frameRect];
	[self _init];
	return(self);	
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	[super initWithCoder:aDecoder];
	[self _init];
	return(self);	
}

- (void)_init
{	
	dataSource = nil;
	columnArray = [[NSMutableArray alloc] init];
	
	//Start off w/ one column
	rootColumn = [[self newColumnForObject:nil] retain];
	[[rootColumn scrollView] setFrameOrigin:NSMakePoint(0, 0)];
	[self addSubview:[rootColumn scrollView]];
	
	
//	
//	scroll = [self _tableView];
//	[scroll setFrameOrigin:NSMakePoint(COLUMN_WIDTH+4, 0)];
//	[self addSubview:scroll];
//	[columnArray addObject:scroll];
//
//	scroll = [self _tableView];
//	[scroll setFrameOrigin:NSMakePoint(COLUMN_WIDTH*2+8, 0)];
//	[self addSubview:scroll];
//	[columnArray addObject:scroll];
}

- (AIBrowserColumn *)newColumnForObject:(id)object
{
	NSTableView		*table;
	NSTableColumn	*column;
	NSScrollView	*scroll;
	
	//Enclosing scroll
	scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, COLUMN_WIDTH, [self frame].size.height)];
	[scroll setAutoresizingMask:NSViewHeightSizable];
	[scroll setHasVerticalScroller:YES];
	
	//Table view
	table = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, [scroll contentSize].width, [scroll contentSize].height)];
//	column = [[NSTableColumn alloc] initWithIdentifier:nil];
//	[column setWidth:16];
//	[table addTableColumn:column];
	column = [[NSTableColumn alloc] initWithIdentifier:nil];
	[column setWidth:100];
	[table addTableColumn:column];
//	column = [[NSTableColumn alloc] initWithIdentifier:nil];
//	[column setWidth:16];
//	[table addTableColumn:column];
	
	[table setDelegate:self];
	[table setDataSource:self];
	[scroll setDocumentView:table];

	
	return([[[AIBrowserColumn alloc] initWithScrollView:scroll tableView:table representedObject:object] autorelease]);
}

- (AIBrowserColumn *)columnForTableView:(NSTableView *)inView
{
	NSEnumerator 	*enumerator = [columnArray objectEnumerator];
	AIBrowserColumn	*column;
	
	while(column = [enumerator nextObject]){
		if([column tableView] == inView) return(column);
	}
	
	return(nil);
}

- (void)addColumn:(AIBrowserColumn *)column
{
	NSPoint		position = NSMakePoint((([columnArray count] + 1) * (COLUMN_WIDTH + 4)), 0);
	
	[[column scrollView] setFrameOrigin:position];
	[self addSubview:[column scrollView]];
	[columnArray addObject:column];
	
	[self sizeToFit];
}
				   
- (void)removeLastColumn
{
	AIBrowserColumn	*column = [columnArray lastObject];
	
	[[column scrollView] removeFromSuperview];
	[columnArray removeObject:column];

	[self sizeToFit];
}

- (void)sizeToFit
{
	[self setFrameSize:NSMakeSize((([columnArray count] + 1) * (COLUMN_WIDTH + 4)) - 4, [self frame].size.height)];
	[self setNeedsDisplay:YES];
}



- (void)setDataSource:(id)inDataSource
{
	dataSource = inDataSource;
	[self reloadData];
}
- (id)dataSource{
	return(dataSource);
}

- (void)reloadData
{
	[[rootColumn tableView] reloadData];
	
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView		*table = [notification object];
	int				columnIndex;
	id 				selectedItem = nil;
		
	//Get this column's index and the selected item
	columnIndex = [columnArray indexOfObject:[self columnForTableView:table]];
	if(columnIndex == NSNotFound){
		columnIndex = 0;
	}else{
		columnIndex++;
	}

	if([table numberOfSelectedRows] != 0){
		selectedItem = [dataSource browserView:self
										 child:[table selectedRow]
										ofItem:[[self columnForTableView:table] representedObject]];
	}

	//Close down all table views after this one
	while(columnIndex < [columnArray count]){
		[self removeLastColumn];
	}
	
	//Add table view for the selected item
	if(selectedItem && [dataSource browserView:self isItemExpandable:selectedItem]){
		[self addColumn:[self newColumnForObject:selectedItem]];
	}
}

- (void)drawRect:(NSRect)rect
{
	[[NSColor orangeColor] set];
	[NSBezierPath fillRect:rect];
	[super drawRect:rect];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	AIBrowserColumn	*column = [self columnForTableView:tableView];
	id				item = (column == rootColumn ? nil : [column representedObject]);

	return([dataSource browserView:self numberOfChildrenOfItem:item]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	AIBrowserColumn	*column = [self columnForTableView:tableView];;
	id				item = [dataSource browserView:self child:row ofItem:[column representedObject]];
	
	return([dataSource browserView:self objectValueForTableColumn:tableColumn byItem:item]);
}


//- (id)browserView:(AIBrowser *)browserView child:(int)index ofItem:(id)item
//- (BOOL)browserView:(AIBrowser *)browserView isItemExpandable:(id)item
//- (int)browserView:(AIBrowser *)browserView numberOfChildrenOfItem:(id)item
//- (id)browserView:(AIBrowser *)browserView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
	

@end





