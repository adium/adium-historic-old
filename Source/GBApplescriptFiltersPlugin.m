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

#import "AIContentController.h"
#import "AIMenuController.h"
#import "AIToolbarController.h"
#import "GBApplescriptFiltersPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <Adium/NDScriptData.h>
#import <Adium/NDComponentInstance.h>
#import <Adium/NSAppleEventDescriptor+NDScriptData.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIHTMLDecoder.h>

#define TITLE_INSERT_SCRIPT		AILocalizedString(@"Insert Script",nil)
#define SCRIPT_BUNDLE_EXTENSION	@"AdiumScripts"
#define SCRIPTS_PATH_NAME		@"Scripts"
#define SCRIPT_EXTENSION		@"scpt"
#define	SCRIPT_IDENTIFIER		@"InsertScript"

//#define APPLESCRIPT_FILTER_DEBUG

@interface GBApplescriptFiltersPlugin (PRIVATE)
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu;
- (void)_sortScriptsByTitle:(NSMutableArray *)sortArray;
- (id)_filterString:(NSString *)inString originalObject:(id)originalObject;
- (NSString *)_executeScript:(NSMutableDictionary *)infoDict withArguments:(NSArray *)arguments;
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSMutableDictionary *)infoDict inString:(NSString *)inString inAttributedString:(NSMutableAttributedString *)toObject;
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSMutableDictionary *)scriptDict;
- (void)buildScriptMenu;
- (void)registerToolbarItem;
@end

int _scriptTitleSort(id scriptA, id scriptB, void *context);
int _scriptKeywordLengthSort(id scriptA, id scriptB, void *context);

#ifdef APPLESCRIPT_FILTER_DEBUG
static int numExecuted = 0;
#endif

/*!
 * @class GBApplescriptFiltersPlugin
 * @brief Filter component to allow .AdiumScripts applescript-based filters for outgoing messages
 */
@implementation GBApplescriptFiltersPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//User scripts
	[[AIObject sharedAdiumInstance] createResourcePathForName:@"Scripts"];
	
	//We have an array of scripts for building the menu, and a dictionary of scripts used for the actual substition
	scriptArray = nil;
	flatScriptArray = nil;
	componentInstance = nil;
	
	//Prepare our script menu item (which will have the Scripts menu as its submenu)
	scriptMenuItem = [[NSMenuItem alloc] initWithTitle:TITLE_INSERT_SCRIPT 
												target:self
												action:@selector(dummyTarget:)
										 keyEquivalent:@""];

	//Perform substitutions on outgoing content in a thread
	[[adium contentController] registerContentFilter:self 
											  ofType:AIFilterContent
										   direction:AIFilterOutgoing
											threaded:YES];
	
	//Observe for installation of new scripts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];	
	
	//Start building the script menu
	scriptMenu = nil;
	[self buildScriptMenu]; //this also sets the submenu for the menu item.
	
	[[adium menuController] addMenuItem:scriptMenuItem toLocation:LOC_Edit_Additions];
	
	contextualScriptMenuItem = [scriptMenuItem copy];
	[[adium menuController] addContextualMenuItem:contextualScriptMenuItem toLocation:Context_TextView_Edit];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	[scriptArray release]; scriptArray = nil;
    [flatScriptArray release]; flatScriptArray = nil;
	[scriptMenuItem release]; scriptMenuItem = nil;
	[contextualScriptMenuItem release]; contextualScriptMenuItem = nil;
	
	[super dealloc];
}

/*!
 * @brief Xtras changes
 *
 * If the scripts xtras changed, rebuild our menus.
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumScripts"] == 0) {
		[self buildScriptMenu];
				
		[self registerToolbarItem];
		
		//Update our toolbar item's menu
		//[self toolbarWillAddItem:nil];
	}
}


//Script Loading -------------------------------------------------------------------------------------------------------
#pragma mark Script Loading
/*!
 * @brief Load our scripts
 *
 * This will clear out and then load from available scripts (external and internal) into flatScriptArray and scriptArray.
 */
- (void)loadScripts
{
	NSEnumerator	*enumerator;
	NSString 		*filePath;
	NSBundle		*scriptBundle;

	//
	[scriptArray release]; scriptArray = [[NSMutableArray alloc] init];
	[flatScriptArray release]; flatScriptArray = [[NSMutableArray alloc] init];
	
	// Load scripts
	enumerator = [[adium allResourcesForName:@"Scripts" withExtensions:SCRIPT_BUNDLE_EXTENSION] objectEnumerator];
	while ((filePath = [enumerator nextObject])) {
		if ((scriptBundle = [NSBundle bundleWithPath:filePath])) {
			
			NSString		*scriptsSetName;
			NSEnumerator	*scriptEnumerator;
			NSDictionary	*scriptDict;
			
			//Get the name of the set these scripts will go into
			scriptsSetName = [scriptBundle objectForInfoDictionaryKey:@"Set"];
			
			//Now enumerate each script the bundle claims as its own
			scriptEnumerator = [[scriptBundle objectForInfoDictionaryKey:@"Scripts"] objectEnumerator];
			
			while ((scriptDict = [scriptEnumerator nextObject])) {
				NSString		*scriptFileName, *scriptFilePath, *keyword, *title;
				NSArray			*arguments;
				NSURL			*scriptURL;
				NSNumber		*prefixOnlyNumber;
				NSNumber		*requiresUserInteractionNumber;
				
				if ((scriptFileName = [scriptDict objectForKey:@"File"]) &&
					(scriptFilePath = [scriptBundle pathForResource:scriptFileName
															 ofType:SCRIPT_EXTENSION])) {
					
					scriptURL = [NSURL fileURLWithPath:scriptFilePath];
					keyword = [scriptDict objectForKey:@"Keyword"];
					title = [scriptDict objectForKey:@"Title"];
					
					if (scriptURL && keyword && [keyword length] && title && [title length]) {
						NSMutableDictionary	*infoDict;
						
						arguments = [[scriptDict objectForKey:@"Arguments"] componentsSeparatedByString:@","];
						
						//Assume "Prefix Only" is NO unless told otherwise
						prefixOnlyNumber = [scriptDict objectForKey:@"Prefix Only"];
						if (!prefixOnlyNumber) prefixOnlyNumber = [NSNumber numberWithBool:NO];
						
						requiresUserInteractionNumber = [scriptDict objectForKey:@"Requires User Interaction"];
						if (!requiresUserInteractionNumber) requiresUserInteractionNumber = [NSNumber numberWithBool:NO];
						
						infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							scriptURL, @"Path", keyword, @"Keyword", title, @"Title", 
							prefixOnlyNumber, @"PrefixOnly", requiresUserInteractionNumber, @"RequiresUserInteraction",nil];
						
						//The bundle may not be part of (or for defining) a set of scripts
						if (scriptsSetName) {
							[infoDict setObject:scriptsSetName forKey:@"Set"];
						}
						//Arguments may be nil
						if (arguments) {
							[infoDict setObject:arguments forKey:@"Arguments"];
						}
						
						//Place the entry in our script arrays
						[scriptArray addObject:infoDict];
						[flatScriptArray addObject:infoDict];
						
						//Scripts must always be updated via polling
						[[adium contentController] registerFilterStringWhichRequiresPolling:keyword];
					}
				}
			}
		}		
	}
}


//Script Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Script Menu
/*!
 * @brief Build the script menu
 *
 * Loads the scrpts as necessary, sorts them, then builds menus for the menu bar, the contextual menu,
 * and the toolbar item.
 */
- (void)buildScriptMenu
{
	[self loadScripts];
	
	//Sort the scripts
	[scriptArray sortUsingFunction:_scriptTitleSort context:nil];
	[flatScriptArray sortUsingFunction:_scriptKeywordLengthSort context:nil];
	
	//Build the menu
	[scriptMenu release]; scriptMenu = [[NSMenu alloc] initWithTitle:TITLE_INSERT_SCRIPT];
	[self _appendScripts:scriptArray toMenu:scriptMenu];
	[scriptMenuItem setSubmenu:scriptMenu];
	[contextualScriptMenuItem setSubmenu:[[scriptMenu copy] autorelease]];
		
	[self registerToolbarItem];
}

/*!
 * @brief Sort first by set, then by title within sets
 */
int _scriptTitleSort(id scriptA, id scriptB, void *context) {
	NSComparisonResult result;
	
	NSString	*setA = [scriptA objectForKey:@"Set"];
	NSString	*setB = [scriptB objectForKey:@"Set"];
	
	if (setA && setB) {
		
		//If both are within sets, sort by set; if they are within the same set, sort by title
		if ((result = [setA caseInsensitiveCompare:setB]) == NSOrderedSame) {
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		}
	} else {
		//Sort by title if neither is in a set; otherwise sort the one in a set to the top
		
		if (!setA && !setB) {
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		
		} else if (!setA) {
			result = NSOrderedDescending;
		} else {
			result = NSOrderedAscending;
		}
	}
	
	return(result);
}

/*!
 * @brief Sort by descending length so the longest keywords are at the beginning of the array
 */
int _scriptKeywordLengthSort(id scriptA, id scriptB, void *context)
{
	NSComparisonResult result;
	
	unsigned int lengthA = [(NSString *)[scriptA objectForKey:@"Keyword"] length];
	unsigned int lengthB = [(NSString *)[scriptB objectForKey:@"Keyword"] length];
	if (lengthA > lengthB) {
		result = NSOrderedAscending;
	} else if (lengthA < lengthB) {
		result = NSOrderedDescending;
	} else {
		result = NSOrderedSame;
	}
	
	return result;
}

/*!
 * @brief Append an array of scripts to a menu
 *
 * @param scripts The scripts, each of which is represented by an NSDictionary instance
 * @param menu The menu to which to add the scripts
 */
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu
{
	NSEnumerator	*enumerator;
	NSDictionary	*appendDict;
	NSString		*lastSet = nil;
	NSString		*set;
	int				indentationLevel;
	
	enumerator = [scripts objectEnumerator];
	while ((appendDict = [enumerator nextObject])) {
		NSString	*title;
		NSMenuItem	*item;
		
		if ((set = [appendDict objectForKey:@"Set"])) {
			indentationLevel = 1;
			
			if (![set isEqualToString:lastSet]) {
				//We have a new set of scripts; create a section header for them
				item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:set
																			 target:nil
																			 action:nil
																	  keyEquivalent:@""] autorelease];
				if ([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:0];
				[menu addItem:item];
				
				[lastSet release]; lastSet = [set retain];
			}
		} else {
			//Scripts not in sets need not be indented
			indentationLevel = 0;
			[lastSet release]; lastSet = nil;
		}
	
		if ([appendDict objectForKey:@"Title"]) {
			title = [NSString stringWithFormat:@"%@ (%@)", [appendDict objectForKey:@"Title"], [appendDict objectForKey:@"Keyword"]];
		} else {
			title = [appendDict objectForKey:@"Keyword"];
		}
		
		item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title
																	 target:self
																	 action:@selector(selectScript:)
															  keyEquivalent:@""] autorelease];
		
		[item setRepresentedObject:appendDict];
		if ([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:indentationLevel];
		[menu addItem:item];
	}
}

/*!
 * @brief Insert a script's keyword into the text entry area
 *
 * This will be called by an NSMenuItem when it is clicked.
 */
- (IBAction)selectScript:(id)sender
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
	//Append our string into the responder if possible
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		NSArray		*arguments = [[sender representedObject] objectForKey:@"Arguments"];
		NSString	*replacementText = [[sender representedObject] objectForKey:@"Keyword"];
		
		[(NSTextView *)responder insertText:replacementText];
		
		//Append arg list to replacement string, to show the user what they can pass
		if (arguments) {
			NSEnumerator		*argumentEnumerator = [arguments objectEnumerator];
			NSDictionary		*originalTypingAttributes = [(NSTextView *)responder typingAttributes];
			NSMutableDictionary *italicizedTypingAttributes = [originalTypingAttributes mutableCopy];
			NSString			*anArgument;
			BOOL				insertedFirst = NO;
			
			[italicizedTypingAttributes setObject:[[NSFontManager sharedFontManager] convertFont:[originalTypingAttributes objectForKey:NSFontAttributeName]
																					 toHaveTrait:NSItalicFontMask]
										   forKey:NSFontAttributeName];
			
			[(NSTextView *)responder insertText:@"{"];
			
			//Will that be a five minute argument or the full half hour?
			while ((anArgument = [argumentEnumerator nextObject])) {
				//Insert a comma after each argument past the first
				if (insertedFirst) {
					[(NSTextView *)responder insertText:@","];					
				} else {
					insertedFirst = YES;
				}
				
				//Turn on the italics version, insert the argument, then go back to normal for either the comma or the ending
				[(NSTextView *)responder setTypingAttributes:italicizedTypingAttributes];
				[(NSTextView *)responder insertText:anArgument];
				[(NSTextView *)responder setTypingAttributes:originalTypingAttributes];
			}

			[(NSTextView *)responder insertText:@"}"];
			
			[italicizedTypingAttributes release];
		}
	}
}

/*!
 * @brief Fake target to allow validateMenuItem: to be called
 */
-(IBAction)dummyTarget:(id)sender{
}

/*!
 * @brief Validate menu item
 * Disable the insertion if a text field is not active
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ((menuItem == scriptMenuItem) || (menuItem == contextualScriptMenuItem)) {
		return(YES); //Always keep the submenu enabled so users can see the available scripts
	} else {
		NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (responder && [responder isKindOfClass:[NSText class]]) {
			return [(NSText *)responder isEditable];
		} else {
			return NO;
		}
	}
}


//Message Filtering ----------------------------------------------------------------------------------------------------
#pragma mark Message Filtering
/*!
 * @brief Filter messages for keywords to replace
 *
 * Replace any script keywords with the result of running the script (with arguments as appropriate)
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *filteredMessage = nil;
	NSString					*stringMessage;

	if ((stringMessage = [inAttributedString string])) {
		NSEnumerator				*enumerator;
		NSMutableDictionary			*infoDict;
		
		//Replace all keywords
		enumerator = [flatScriptArray objectEnumerator];
		while ((infoDict = [enumerator nextObject])) {
			NSString	*keyword = [infoDict objectForKey:@"Keyword"];
			BOOL		prefixOnly = [[infoDict objectForKey:@"PrefixOnly"] boolValue];

			if ((prefixOnly && ([stringMessage rangeOfString:keyword options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0)) ||
			   (!prefixOnly && [stringMessage rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)) {

				NSNumber	*shouldSendNumber;
				
				if (!filteredMessage) filteredMessage = [inAttributedString mutableCopy];
				[self _replaceKeyword:keyword withScript:infoDict inString:stringMessage inAttributedString:filteredMessage];
				stringMessage = [filteredMessage string]; //Update our plain text string, since it most likely changed
				
				shouldSendNumber = [infoDict objectForKey:@"ShouldSend"];
				if ((shouldSendNumber) &&
					(![shouldSendNumber boolValue]) &&
					([context isKindOfClass:[AIContentObject class]])) {
					[(AIContentObject *)context setSendContent:NO];
				}
			}
		}
	}
	
    return(filteredMessage ? [filteredMessage autorelease] : inAttributedString);
}

/*!
 * @brief Filter priority
 *
 * Filter earlier than the default
 */
- (float)filterPriority
{
	return HIGH_FILTER_PRIORITY;
}

/*!
 * @brief Perform a thorough variable replacing scan
 */
- (void)_replaceKeyword:(NSString *)keyword withScript:(NSMutableDictionary *)infoDict inString:(NSString *)inString inAttributedString:(NSMutableAttributedString *)attributedString
{
	NSScanner	*scanner;
	NSString	*arglessScriptResult = nil;
	int			offset = 0;
	
	if (inString) {
		scanner = [NSScanner scannerWithString:inString];
		//Scan for the keyword
		while (![scanner isAtEnd]) {
			[scanner scanUpToString:keyword intoString:nil];

			if (([scanner scanString:keyword intoString:nil]) &&
			   ([attributedString attribute:NSLinkAttributeName
									atIndex:([scanner scanLocation]-1) /* The scanner ends up one past the keyword */
							 effectiveRange:nil] == nil)) {
				//Scan the keyword and ensure it was not found within a link
				int 		keywordStart, keywordEnd;
				NSArray 	*argArray = nil;
				NSString	*argString;
				
				//Scan arguments
				keywordStart = [scanner scanLocation] - [keyword length];
				if ([scanner scanString:@"{" intoString:nil]) {
					if ([scanner scanUpToString:@"}" intoString:&argString]) {
						argArray = [self _argumentsFromString:argString forScript:infoDict];
						[scanner scanString:@"}" intoString:nil];
					}
				}
				keywordEnd = [scanner scanLocation];		

				if (keywordStart != 0 && [inString characterAtIndex:keywordStart - 1] == '\\') {
					//Ignore the script (It was escaped) and delete the escape character
					[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset - 1, 1) withString:@""];
					offset -= 1;
					
				} else {
					//Run the script.  Cache the result to speed up multiple instances of a single keyword
					NSString	*scriptResult = nil;
					unsigned	scriptResultLength;

					if ([argArray count] == 0 && arglessScriptResult) scriptResult = arglessScriptResult;
					if (!scriptResult) scriptResult = [self _executeScript:infoDict withArguments:argArray];
					if ([argArray count] == 0 && !arglessScriptResult) arglessScriptResult = scriptResult;
					
					//If the script fails, eat the keyword
					if (!scriptResult) scriptResult = @"";
					
					//Replace the substring with script result
					if (([scriptResult hasPrefix:@"<HTML>"])) {
						//Obtain the attributed string version of the HTML, passing our current attributes as the default ones
						NSAttributedString *attributedScriptResult = [AIHTMLDecoder decodeHTML:scriptResult
																		 withDefaultAttributes:[attributedString attributesAtIndex:(keywordStart + offset)
																													effectiveRange:nil]];
						[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset, keywordEnd - keywordStart)
														withAttributedString:attributedScriptResult];
						scriptResultLength = [attributedScriptResult length];
						
					} else {
						[attributedString replaceCharactersInRange:NSMakeRange(keywordStart + offset, keywordEnd - keywordStart)
														withString:scriptResult];
						
						scriptResultLength = [scriptResult length];
					}
					
					//Adjust for replaced text
					offset += scriptResultLength - (keywordEnd - keywordStart);
				}
			}
		}
	}
}

/*!
 * @brief Determine the arguments for a script execution
 *
 * @param inString The string of potential arguments
 * @param scriptDict The script being executed
 *
 * @result An NSArray of NSString instances
 */
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSMutableDictionary *)scriptDict
{
	NSArray			*scriptArguments = [scriptDict objectForKey:@"Arguments"];
	NSMutableArray	*argArray = [NSMutableArray array];
	NSArray			*inStringComponents = [inString componentsSeparatedByString:@","];
	
	unsigned		i = 0;
	unsigned		count = (scriptArguments ? [scriptArguments count] : 0);
	unsigned		inStringComponentsCount = [inStringComponents count];
	
	//Add each argument of inString to argArray so long as the number of arguments is less
	//than the number of expected arguments for the script and the number of supplied arguments
	while ((i < count) && (i < inStringComponentsCount)) {
		[argArray addObject:[inStringComponents objectAtIndex:i]];
		i++;
	}
	
	//If more components were passed than were actually requested, the last argument gets the
	//remainder
	if (i < inStringComponentsCount) {
		NSRange	remainingRange;
		
		//i was incremented to end the while loop if i > 0, so subtract 1 to reexamine the last object
		remainingRange.location = ((i > 0) ? i-1 : 0);
		remainingRange.length = (inStringComponentsCount - remainingRange.location);

		if (remainingRange.location >= 0) {
			NSString	*lastArgument;

			//Remove that last, incomplete argument if it was added
			if ([argArray count]) [argArray removeLastObject];

			//Create the last argument by joining all remaining comma-separated arguments with a comma
			lastArgument = [[inStringComponents subarrayWithRange:remainingRange] componentsJoinedByString:@","];

			[argArray addObject:lastArgument];
		}
	}
	
	return(argArray);
}

/*!
 * @brief Execute the script, returning its output
 */
- (NSString *)_executeScript:(NSMutableDictionary *)infoDict withArguments:(NSArray *)arguments
{
	NDScriptContext			*scriptContext;
	NSAppleEventDescriptor	*resultDescriptor;
	NSString				*result = nil;

	//Attempt to use a cached script
	scriptContext = [infoDict objectForKey:@"NDScriptContext"];
	
	//If none is found, load and cache
	if (!scriptContext) {
		//We run from a thread, so we need a unique componentInstance, as the shared one is NOT threadsafe. Each script
		//does not need one; we can reuse the same one for every script called from this thread.
		if (!componentInstance) {
			componentInstance = [[NDComponentInstance componentInstance] retain];

			//We want to receive the sendAppleEvent calls below for scripts running with our componentInstance
			[componentInstance setAppleEventSendTarget:self currentProcessOnly:YES];

			/*
			 We don't want any funny business happening while the applescript runs; if we don't set an activeTarget,
			 the thread will appear open and invocations will come out of order.  If we wanted to disregard ordering,
			 we'd get a huge perceived performance boost when running lengthy applescripts by removing this... but
			 message order definitely does matter, so we must wait until Message 1 is done and displayed before doing
			 Message 2.
			 */
			[componentInstance setActiveTarget:self];
		}


		//Load the script
		scriptContext = [NDScriptContext scriptDataWithContentsOfURL:[infoDict objectForKey:@"Path"]
												   componentInstance:componentInstance];

		if (scriptContext) {
			[infoDict setObject:scriptContext
						 forKey:@"NDScriptContext"];
		}
	}

#ifdef APPLESCRIPT_FILTER_DEBUG
	numExecuted++;
	NSLog(@"%i: Executing %@",numExecuted,[infoDict objectForKey:@"Title"]);
	[scriptContext executeSubroutineNamed:@"substitute" argumentsArray:arguments];
	NSLog(@"%i: Finished.",numExecuted);
#else
	[scriptContext executeSubroutineNamed:@"substitute" argumentsArray:arguments];
#endif
	
	resultDescriptor = [scriptContext resultAppleEventDescriptor];
	
	if (resultDescriptor) {
		result = [resultDescriptor stringValue];
	}

	return(result);
}

/*!
 * @brief Receive apple events while running an applescript
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)appleEventDescriptor 
								  sendMode:(AESendMode)sendMode 
							  sendPriority:(AESendPriority)sendPriority
							timeOutInTicks:(long)timeOutInTicks
								  idleProc:(AEIdleUPP)idleProc
								filterProc:(AEFilterUPP)filterProc
{
	NSAppleEventDescriptor	*eventDescriptor;

#ifdef APPLESCRIPT_FILTER_DEBUG
	NSLog(@"%i (mainthread %i): appleEvent: %@",numExecuted,handleOnMainThread,appleEventDescriptor);
#endif

	NSInvocation			*invocation;
	SEL						selector;
	
	selector = @selector(sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:);
	
	invocation = [NSInvocation invocationWithMethodSignature:[componentInstance methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:componentInstance];
	
	[invocation setArgument:&appleEventDescriptor atIndex:2];
	[invocation setArgument:&sendMode atIndex:3];
	[invocation setArgument:&sendPriority atIndex:4];
	[invocation setArgument:&timeOutInTicks atIndex:5];
	[invocation setArgument:&idleProc atIndex:6];
	[invocation setArgument:&filterProc atIndex:7];
	
	[invocation performSelectorOnMainThread:@selector(invoke)
								 withObject:nil
							  waitUntilDone:YES];
	[invocation getReturnValue:&eventDescriptor];

	return(eventDescriptor);
}

- (BOOL)appleScriptActive
{
#ifdef APPLESCRIPT_FILTER_DEBUG
	NSLog(@"%i: Active.",numExecuted);
#endif
	return(YES);
}

#pragma mark Toolbar item
/*!
 * @brief Register our insert script toolbar item
 */
- (void)registerToolbarItem
{
	MVMenuButton *button;
	
	//Unregister the existing toolbar item first
	if (toolbarItem) {
		[[adium toolbarController] unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		[toolbarItem release]; toolbarItem = nil;
	}
	
	//Register our toolbar item
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];
	[button setImage:[NSImage imageNamed:@"scriptToolbar" forClass:[self class]]];
	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:SCRIPT_IDENTIFIER
														   label:AILocalizedString(@"Scripts",nil)
													paletteLabel:TITLE_INSERT_SCRIPT
														 toolTip:AILocalizedString(@"Insert a script",nil)
														  target:self
												 settingSelector:@selector(setView:)
													 itemContent:button
														  action:@selector(selectScript:)
															menu:nil] retain];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief After the toolbar has added the item we can set up the submenus
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if (!notification || ([[item itemIdentifier] isEqualToString:SCRIPT_IDENTIFIER])) {
		NSMenu		*menu = [[[scriptMenuItem submenu] copy] autorelease];
		
		//Add menu to view
		[[item view] setMenu:menu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
		[mItem setSubmenu:menu];
		[mItem setTitle:[menu title]];
		[item setMenuFormRepresentation:mItem];
	}
}

@end
