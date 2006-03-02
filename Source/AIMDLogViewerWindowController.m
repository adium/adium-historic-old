//
//  AIMDLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AIMDLogViewerWindowController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"

@implementation AIMDLogViewerWindowController
- (void)windowDidLoad
{	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryUpdate:)
												 name:NSMetadataQueryGatheringProgressNotification
											   object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryDidFinish:)
												 name:NSMetadataQueryDidFinishGatheringNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryUpdate:)
												 name:NSMetadataQueryDidUpdateNotification
											   object:nil];

	[super windowDidLoad];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
	[self stopSearching];

	if (currentQuery) {
		[currentQuery stopQuery];
		[currentQuery release];
	}
	currentQuery = [[NSMetadataQuery alloc] init];
	
	//Once all searches have exited, we can start a new one
	if (clearCurrentResults) {
		[resultsLock lock];
		[selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	}
	
	//Only search within our log folder
	//XXX need to escape ? and * if they are typed
	[currentQuery setSearchScopes:[NSArray arrayWithObject:[NSURL fileURLWithPath:[AILoggerPlugin logBasePath]]]];
	NSPredicate *queryPredicate;
	NSPredicate	*contentTypePredicate = [NSPredicate predicateWithFormat:@"((kMDItemContentType = \"com.adiumx.log\") or (kMDItemContentType = \"com.adiumx.htmllog\"))"];
	NSPredicate	*additionalPredicate = nil;
	switch (searchMode) {
		case LOG_SEARCH_FROM:
			if ([activeSearchString length]) {
				additionalPredicate = [NSPredicate predicateWithFormat:@"com_adiumX_chatSource like[c] %@",[activeSearchString compactedString]];
			}
			
			break;
		case LOG_SEARCH_TO:
			if ([activeSearchString length]) {
				additionalPredicate = [NSPredicate predicateWithFormat:@"com_adiumX_chatDestination like[c] %@",[activeSearchString compactedString]];
			}
			
			break;
		case LOG_SEARCH_DATE:
		{
			NSDate *searchStringDate = [NSDate dateWithNaturalLanguageString:activeSearchString];

			additionalPredicate = [NSPredicate predicateWithFormat:@"kMDItemLastUsedDate like[c] %@",[NSString stringWithFormat:@"*%@*",[searchStringDate descriptionWithCalendarFormat:@"%y-%m-%d"
																																											   timeZone:nil 
																																												  locale:nil]]];
			break;
		}
		case LOG_SEARCH_CONTENT:
			if ([activeSearchString length]) {
				additionalPredicate = [NSPredicate predicateWithFormat:@"kMDItemTextContent like[c] %@",[NSString stringWithFormat:@"*%@*",activeSearchString]];
			}
			break;
	}

	
	if (additionalPredicate) {
		queryPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:contentTypePredicate, additionalPredicate, nil]];
	} else {
		queryPredicate = contentTypePredicate;
	}
	NSLog(@"Predicate is %@",queryPredicate);
	[currentQuery setPredicate:queryPredicate];
	lastResult = 0;
	[currentQuery startQuery];
	
	//Update the table periodically while the logs load.
	[refreshResultsTimer invalidate]; [refreshResultsTimer release];
#define	REFRESH_RESULTS_INTERVAL		0.5 //Interval between results refreshes while searching

	refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
															target:self
														  selector:@selector(refreshResults)
														  userInfo:nil
														   repeats:YES] retain];	
}

- (void)threadedQueryUpdate:(NSNumber *)inSearchID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMetadataQuery *myQuery = [currentQuery retain];
	//+1 for the trailing slash
	unsigned logBaseLength = [[AILoggerPlugin logBasePath] length] + 1;
	int searchID = [inSearchID intValue];

	//Process the results
	[myQuery disableUpdates];
	unsigned count = [myQuery resultCount];
	while ((lastResult < count) && (searchID == activeSearchID)) {
		NSString		*path = [[myQuery resultAtIndex:lastResult++] valueForAttribute:(NSString *)kMDItemPath];
		//Path is a full path; we want everything after the base path since the old logging system used relative paths
		path = [path substringFromIndex:logBaseLength];
		
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		AIChatLog		*theLog;
		
		/*	
			Add the log - if our index is currently out of date (for example, a log was just deleted) 
		 we may get a null log, so be careful.
		 */
		[resultsLock lock];
		theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
		if ((theLog != nil) && (![selectedLogArray containsObjectIdenticalTo:theLog]) && (searchID == activeSearchID)) {
			//			[theLog setRankingPercentage:outScoresArray[i]];
			//			NSLog(@"relevance is %@",[NSMetadataQueryResultContentRelevanceAttribute);
			[selectedLogArray addObject:theLog];
		}
		[resultsLock unlock];
	}
	
	[myQuery enableUpdates];
	[myQuery release];
	[pool release];
}
- (void)queryUpdate:(NSNotification *)inNotification
{
	[NSThread detachNewThreadSelector:@selector(threadedQueryUpdate:)
							 toTarget:self
						   withObject:[NSNumber numberWithInt:activeSearchID]];
}

- (void)queryDidFinish:(NSNotification *)inNotification
{
	[self searchComplete];
}

@end
