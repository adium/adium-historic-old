//
//  AIBrowser.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIBrowser.h"

#define COLUMN_WIDTH 	140

@interface AIBrowser (PRIVATE)
- (void)_init;
- (NSScrollView *)_tableView;
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
	representedObjects = [[NSMutableArray alloc] init];
	
	//Start off w/ one column	
	rootColumn = [self _tableView];
	[rootColumn setFrameOrigin:NSMakePoint(0, 0)];
	[self addSubview:rootColumn];
	
	
	
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

- (NSScrollView *)_tableView
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
	column = [[NSTableColumn alloc] initWithIdentifier:nil];
	[column setWidth:16];
	[table addTableColumn:column];
	column = [[NSTableColumn alloc] initWithIdentifier:nil];
	[column setWidth:80];
	[table addTableColumn:column];
	column = [[NSTableColumn alloc] initWithIdentifier:nil];
	[column setWidth:16];
	[table addTableColumn:column];

	
	
	
	
	[table setDelegate:self];
	[table setDataSource:self];
	[scroll setDocumentView:table];

	return(scroll);
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
	[[rootColumn documentView] reloadData];
	
}

//- (void)drawRect:(NSRect)rect
//{
//	[[NSColor orangeColor] set];
//	[NSBezierPath fillRect:rect];
//	[super drawRect:rect];
//}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSScrollView	*column = [tableView enclosingScrollView];
	id				item = (column == rootColumn ? nil : [dataSource outlineView:self numberOfChildrenOfItem:nil]);

	return([dataSource outlineView:self numberOfChildrenOfItem:item]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSScrollView	*column = [tableView enclosingScrollView];
	id				parent = (column == rootColumn ? nil : [dataSource outlineView:self numberOfChildrenOfItem:nil]);
	id				item = [dataSource outlineView:self child:row ofItem:parent];
	
	return([dataSource outlineView:self objectValueForTableColumn:tableColumn byItem:item]);
}


//- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
//- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
//- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
//- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
	

@end





