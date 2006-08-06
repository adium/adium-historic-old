//
//  RAFjoscarDebugController.m
//  Adium
//
//  Created by Augie Fackler on 12/28/05.
//

#import "RAFjoscarDebugController.h"
#import "RAFjoscarDebugWindowController.h"
#import "AIMenuController.h"
#import "AIAdium.h"
#import "AIPreferenceController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringUtilities.h>

#include <fcntl.h>  //open(2)
#include <unistd.h> //close(2)
#include <errno.h>  //errno
#include <string.h> //strerror(3)

#define	CACHED_DEBUG_LOGS		100		//Number of logs to keep at any given time
#define	KEY_JOSCAR_DEBUG_WINDOW_OPEN	@"joscar Debug Window Open"

@implementation RAFjoscarDebugController

#ifdef DEBUG_BUILD

static RAFjoscarDebugController *sharedDebugController = nil;

- (id)init
{
	if (!sharedDebugController) {
		if ((sharedDebugController = [super init])) {
			debugLogArray = [[NSMutableArray alloc] initWithCapacity:100];
		}
	}
	return sharedDebugController;
}

- (void)activateDebugController
{
	NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"joscar Debug Window",nil)
																				target:self
																				action:@selector(showDebugWindow:)
																		 keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_About];
	[menuItem release];
	
	//Restore the debug window if it was open when we quit last time
	if ([[[adium preferenceController] preferenceForKey:KEY_JOSCAR_DEBUG_WINDOW_OPEN
												  group:GROUP_JOSCAR_DEBUG] boolValue]) {
		[RAFjoscarDebugWindowController showDebugWindow];
	}
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_JOSCAR_DEBUG];
}	

+ (RAFjoscarDebugController *)sharedDebugController
{
	return sharedDebugController;
}

- (void)dealloc
{
	//Save the open state of the debug window
	[[adium preferenceController] setPreference:([RAFjoscarDebugWindowController debugWindowIsOpen] ?
												 [NSNumber numberWithBool:YES] :
												 nil)
										 forKey:KEY_JOSCAR_DEBUG_WINDOW_OPEN
										  group:GROUP_JOSCAR_DEBUG];
	
	[debugLogArray release];
	if (debugLogFile) {
		[debugLogFile closeFile];
		[debugLogFile release];
	}
	
	sharedDebugController = nil;
	
	[super dealloc];
}


- (void)showDebugWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[RAFjoscarDebugWindowController showDebugWindow];
}

- (void)addMessage:(NSString *)actualMessage
{
	if ((![actualMessage hasSuffix:@"\n"]) && (![actualMessage hasSuffix:@"\r"])) {
		actualMessage = [actualMessage stringByAppendingString:@"\n"];
	}
	
	[debugLogArray addObject:actualMessage];
	
	if (debugLogFile) {
		[debugLogFile writeData:[actualMessage dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	//Keep debugLogArray to a reasonable size
	if ([debugLogArray count] > CACHED_DEBUG_LOGS) [debugLogArray removeObjectAtIndex:0];
	
	[RAFjoscarDebugWindowController addedDebugMessage:actualMessage];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || [key isEqualToString:KEY_JOSCAR_DEBUG_WRITE_LOG]) {
		BOOL	writeLogs = [[prefDict objectForKey:KEY_JOSCAR_DEBUG_WRITE_LOG] boolValue];
		if (writeLogs) {
			[self debugLogFile];
			
		} else {
			[debugLogFile release]; debugLogFile = nil;
		}
	}
}

- (NSArray *)debugLogArray
{
	return debugLogArray;
}
- (void)clearDebugLogArray
{
	[debugLogArray removeAllObjects]; 
}

- (NSFileHandle *)debugLogFile
{
	if (!debugLogFile) {
		NSFileManager *mgr = [NSFileManager defaultManager];
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		NSString *folder, *dateString, *filename, *pathname;
		unsigned counter = 0;
		int fd;
		
		//make sure the containing folder for debug logs exists.
		folder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		folder = [folder stringByAppendingPathComponent:@"Logs"];
		folder = [folder stringByAppendingPathComponent:@"Adium joscar Debug"];
		BOOL success = [mgr createDirectoryAtPath:folder attributes:nil];
		if((!success) && (errno != EEXIST)) {
			/*raise an exception if the folder could not be created,
			*	but not if that was because it already exists.
			*/
			NSAssert2(success, @"Could not create folder %@: %s", folder, strerror(errno));
		}
		
		/*get today's date, for the filename.
			*the date is in YYYY-MM-DD format. duplicates are disambiguated with
			*' 1', ' 2', ' 3', etc. appendages.
			*/
		filename = dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%d"];
		while([mgr fileExistsAtPath:(pathname = [folder stringByAppendingPathComponent:[filename stringByAppendingPathExtension:@"log"]])]) {
			filename = [dateString stringByAppendingFormat:@" %u", ++counter];
		}
		
		//create (if necessary) and open the file as writable, in append mode.
		fd = open([pathname fileSystemRepresentation], O_CREAT | O_WRONLY | O_APPEND, 0644);
		NSAssert2(fd > -1, @"could not create %@ nor open it for writing: %s", pathname, strerror(errno));
		
		//note: the file handle takes ownership of fd.
		/*
		 * From the docs:  "The object creating an NSFileHandle using this method owns fileDescriptor and is responsible for its disposition."
		 * which seems to indicate that the file handle does not take ownership of fd. Just for the record. -eds
		 */
		debugLogFile = [[NSFileHandle alloc] initWithFileDescriptor:fd];
		if(!debugLogFile) close(fd);
		NSAssert1(debugLogFile != nil, @"could not create file handle for %@", pathname);
		
		//write header (separates this session from previous sessions).
		[debugLogFile writeData:[[NSString stringWithFormat:@"Opened debug log at %@\n", date] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return debugLogFile;
}

#else
- (void)controllerDidLoad {};
- (void)controllerWillClose {};
#endif /* DEBUG_BUILD */

@end
