/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AILogViewerWindowController.h"
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AIChatLog.h"
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

@implementation AILogViewerWindowController

Boolean ContentResultsFilter (SKIndexRef inIndex,
                              SKDocumentRef inDocument,
                              void *inContext)
{
	return [(AILogViewerWindowController *)inContext searchShouldDisplayDocument:inDocument
																  pathComponents:nil
																		testDate:YES];
}

//Perform a content search of the indexed logs
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID onSearchIndex:(SKIndexRef)logSearchIndex
{		
	SKSearchGroupRef	searchGroup;
	CFArrayRef			indexArray;
	SKSearchResultsRef	searchResults;
	int					resultCount;    
	UInt32				lastUpdate = TickCount();
	void				*indexPtr = &logSearchIndex;
	
	//We utilize the logIndexAccessLock so we have exclusive access to the logs
	NSLock			*logAccessLock = [plugin logAccessLock];
	
	//Perform the content search
	[logAccessLock lock];
	indexArray = CFArrayCreate(NULL, indexPtr, 1, &kCFTypeArrayCallBacks);
	searchGroup = SKSearchGroupCreate(indexArray);
	
	/* Our logs are stored as HTML.  Non-ASCII characters are therefore HTML-encoded.  We need to have an
	 * encoded version of our search string with which to search when doing a content-based search, as that's
	 * how they are on disk.
	 */
	searchString = [AIHTMLDecoder encodeHTML:[[[NSAttributedString alloc] initWithString:searchString] autorelease]
									 headers:NO 
									fontTags:NO 
						  includingColorTags:NO
							   closeFontTags:NO 
								   styleTags:NO
				  closeStyleTagsOnFontChange:NO
							  encodeNonASCII:YES 
								encodeSpaces:NO
								  imagesPath:nil 
						   attachmentsAsText:YES 
				   onlyIncludeOutgoingImages:NO 
							  simpleTagsOnly:NO
							  bodyBackground:NO];
	
	searchResults = SKSearchResultsCreateWithQuery(
												   searchGroup,
												   (CFStringRef)searchString,
												   kSKSearchRanked,
												   LOG_CONTENT_SEARCH_MAX_RESULTS,
												   (void *)self,	/* Must have a context for the ContentResultsFilter */
												   &ContentResultsFilter	/* Determines if a given document should be included */
												   );
	
	//Process the results
	if ((resultCount = SKSearchResultsGetCount(searchResults))) {
		SKDocumentRef   *outDocumentsArray = malloc(sizeof(SKDocumentRef) * LOG_RESULT_CLUMP_SIZE);
		float		*outScoresArray = malloc(sizeof(float) * LOG_RESULT_CLUMP_SIZE);
		NSRange		resultRange = NSMakeRange(0, resultCount);
		
		//Read the results in LOG_RESULT_CLUMP_SIZE at a time
		while (resultRange.location < resultCount && (searchID == activeSearchID)) {
			int		count;
			int		i;
			
			//Get the next LOG_RESULT_CLUMP_SIZE results
			count = SKSearchResultsGetInfoInRange(searchResults,
												  CFRangeMake(resultRange.location, LOG_RESULT_CLUMP_SIZE),
												  outDocumentsArray,
												  NULL,
												  outScoresArray);
			
			//Process the results
			for (i = 0; (i < count) && (searchID == activeSearchID); i++) {
				CFURLRef	url = SKDocumentCopyURL(outDocumentsArray[i]);
				CFStringRef logPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
				NSArray		*pathComponents = [(NSString *)logPath pathComponents];
				unsigned int numPathComponents = [pathComponents count];
				
				NSString	*toPath = [NSString stringWithFormat:@"%@/%@",
					[pathComponents objectAtIndex:numPathComponents-3],
					[pathComponents objectAtIndex:numPathComponents-2]];
				NSString	*path = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
				AIChatLog	*theLog;
				
				/*	
					Add the log - if our index is currently out of date (for example, a log was just deleted) 
				 we may get a null log, so be careful.
				 */
				[resultsLock lock];
				theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
				if ((theLog != nil) && (![currentSearchResults containsObjectIdenticalTo:theLog])) {
					[theLog setRankingPercentage:outScoresArray[i]];
					[currentSearchResults addObject:theLog];
				}
				[resultsLock unlock];
				
				CFRelease(logPath);
				CFRelease(url);
			}	 
			
			//Update our status
			if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
				[self updateProgressDisplay];
				lastUpdate = TickCount();
			}
			
			resultRange.location += LOG_RESULT_CLUMP_SIZE;
			resultRange.length -= LOG_RESULT_CLUMP_SIZE;
		}
		
		free(outDocumentsArray);
		free(outScoresArray);
	}
	
	CFRelease(indexArray);
	CFRelease(searchGroup);
	CFRelease(searchResults);
	
	//Release the logsLock so the plugin can return to regularly scheduled programming
	[logAccessLock unlock];
}

- (NSString *)dateItemNibName
{
	return @"LogViewerDateFilter-Panther";
}

@end

