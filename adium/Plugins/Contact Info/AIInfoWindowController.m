//
//  AITextProfileWindowController.m
//  Adium
//
//  Created by Adam Iser on Tue Jun 10 2003.
//

#import "AIInfoWindowController.h"

#define KEY_TEXT_PROFILE_WINDOW_FRAME	@"Text Profile Window"
#define INFO_WINDOW_NIB					@"ContactInfo"
#define InfoIndentA						80
#define InfoIndentB						85
#define REFRESH_RATE                    300

@interface AIInfoWindowController (PRIVATE)
- (void)displayInfo:(NSAttributedString *)infoString;
@end

@implementation AIInfoWindowController

//Open a new info window
static AIInfoWindowController   *sharedInfoWindowInstance = nil;
static AIListObject				*activeListObject = nil;

#pragma mark configureWindow
//Configure our window for the specified object
- (void)configureWindow
{
    NSMutableAttributedString	*infoString;
    NSDictionary				*labelAttributes, *valueAttributes, *bigValueAttributes;
    NSMutableParagraphStyle		*paragraphStyle;
    NSTextAttachmentCell 		*imageAttatchment;
    NSTextAttachment 			*attatchment;
    NSImage 					*buddyImage;
    BOOL                        online = [activeListObject integerStatusObjectForKey:@"Online"];
    
	//
    [timer invalidate]; [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RATE
											  target:self
											selector:@selector(refresh:)
											userInfo:nil
											 repeats:NO] retain];
    
    //Set window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@'s Info",[activeListObject displayName]]];
    
    //Build the info text
    infoString = [[[NSMutableAttributedString alloc] init] autorelease];

    //Create an paragraph style with the correct tabbing and indents
    paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setTabStops:[NSArray arrayWithObjects:
        [[[NSTextTab alloc] initWithType:NSRightTabStopType location:InfoIndentA] autorelease],
        [[[NSTextTab alloc] initWithType:NSLeftTabStopType location:InfoIndentB] autorelease],
        nil]];
    [paragraphStyle setHeadIndent:InfoIndentB];

    //Prepare the text attributes we will use
    labelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:11], NSFontAttributeName,
        [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], NSForegroundColorAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName, 
        nil];
    valueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont systemFontOfSize:11], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];
    bigValueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:16], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];
    
    //Buddy Icon
    if(buddyImage = [[activeListObject displayArrayForKey:@"UserIcon"] objectValue]){
		//MUST make a copy, since resizing and flipping the original image here breaks it everywhere else
		buddyImage = [[buddyImage copy] autorelease];		
        //Resize to default buddy icon size for consistency
        [buddyImage setScalesWhenResized:YES];
        [buddyImage setSize:NSMakeSize(48,48)];
    }else{
        buddyImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
    }
    
    imageAttatchment = [[[NSTextAttachmentCell alloc] initImageCell:buddyImage] autorelease];
    attatchment = [[[NSTextAttachment alloc] init] autorelease];
    [attatchment setAttachmentCell:imageAttatchment];

    [infoString appendString:@"\r\t" withAttributes:labelAttributes];
    [infoString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attatchment]];
    
    //Display Name
	//"<DisplayName>" (or) "<DisplayName> (<UID>)"
	NSString	*displayName = [activeListObject displayName];
	NSString	*formattedUID = [activeListObject formattedUID];
    [infoString appendString:@"\t" withAttributes:labelAttributes];
    if([displayName compare:formattedUID] == 0){
        [infoString appendString:[NSString stringWithFormat:@"%@",displayName] withAttributes:bigValueAttributes];
    }else{
        [infoString appendString:[NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID] 
				  withAttributes:bigValueAttributes];
    }
    
	//Server display name if present
	NSString *serverDisplayName = [activeListObject statusObjectForKey:@"Server Display Name"];
	if (serverDisplayName && [serverDisplayName length]) {
		[infoString appendString:@"\r\r\tDisplay Name:\t" withAttributes:labelAttributes];
		[infoString appendString:serverDisplayName withAttributes:valueAttributes];
	}
	
    //Client
    NSString *client = [activeListObject statusObjectForKey:@"Client"];
    if(client && [client length]){
        [infoString appendString:@"\r\r\tClient:\t" withAttributes:labelAttributes];
        [infoString appendString:client withAttributes:valueAttributes];
    }
    
    //Signon Date
    NSDate *signonDate = [activeListObject statusObjectForKey:@"Signon Date"];
    if(signonDate && online){
        NSString        *currentDay, *signonDay, *signonTime;
        NSDateFormatter	*dayFormatter, *timeFormatter;

        [infoString appendString:@"\r\r\tOnline For:\t" withAttributes:labelAttributes];
		[infoString appendString:[NSDateFormatter stringForTimeIntervalSinceDate:signonDate 
																  showingSeconds:NO
																	 abbreviated:NO] withAttributes:valueAttributes];
        [infoString appendString:@"\r\tOnline Since:\t" withAttributes:labelAttributes];
            
        //Create the formatters
        dayFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%m/%d/%y" allowNaturalLanguage:YES] autorelease];
        timeFormatter = [[[NSDateFormatter alloc] initWithDateFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO
																												showingAMorPM:YES]
												allowNaturalLanguage:YES] autorelease];
        
        //Get day & time strings
        currentDay = [dayFormatter stringForObjectValue:[NSDate date]];
        signonDay = [dayFormatter stringForObjectValue:signonDate];
        signonTime = [timeFormatter stringForObjectValue:signonDate];
        
        if([currentDay compare:signonDay] == 0){ //Show time
            [infoString appendString:signonTime withAttributes:valueAttributes];
            
        }else{ //Show date and time
            [infoString appendString:[NSString stringWithFormat:@"%@, %@", signonDay, signonTime] 
					  withAttributes:valueAttributes];
        }
    }
    
    //Online
    /*    int online = [activeListObject integerStatusObjectForKey:@"Online"];
    [infoString appendString:@"\r\tOnline:\t" withAttributes:labelAttributes];
    [infoString appendString:(online ? @"Yes" : @"No") withAttributes:valueAttributes];*/
    
    //Away & Status
    int away = [activeListObject integerStatusObjectForKey:@"Away"];
	NSAttributedString *status = [activeListObject statusObjectForKey:@"StatusMessage"];
    
    if(status || away){ //If away or w/ status message
        if(away){
            [infoString appendString:@"\r\r\tAway:\t" withAttributes:labelAttributes];
        }else{
            [infoString appendString:@"\r\r\tStatus:\t" withAttributes:labelAttributes];
        }
        
        if (status) {
            NSMutableAttributedString   *statusString = [[[adium contentController] fullyFilteredAttributedString:status 
																								listObjectContext:activeListObject] mutableCopy];
            NSMutableParagraphStyle     *indentStyle;
            
            NSRange                     firstLineRange = [[statusString string] lineRangeForRange:NSMakeRange(0,0)];
            
            //Strip some attributes from info (?)
            //[textProfileString addAttributes:valueAttributes range:NSMakeRange(0,[textProfileString length])];
            
            //Set correct indent & tabbing on the first line of the profile
            [statusString addAttribute:NSParagraphStyleAttributeName 
								 value:paragraphStyle
								 range:NSMakeRange(0,firstLineRange.length)];
            
            //Indent the remaining lines of profile
            indentStyle = [paragraphStyle mutableCopy];
            [indentStyle setFirstLineHeadIndent:InfoIndentB];
            [statusString addAttribute:NSParagraphStyleAttributeName
								 value:indentStyle
								 range:NSMakeRange(firstLineRange.length, [statusString length] - firstLineRange.length)];
            [indentStyle release];
            
            [infoString appendAttributedString:statusString];
            [statusString release];
        } else {
            [infoString appendString:@"Yes" withAttributes:valueAttributes];
        }
    }
    
    //Idle Since
    int idle = (int)[activeListObject doubleStatusObjectForKey:@"Idle"];
    if(idle != 0){
        int	hours = (int)(idle / 60);
        int	minutes = (int)(idle % 60);

        [infoString appendString:@"\r\r\tIdle:\t" withAttributes:labelAttributes];

        if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
            [infoString appendString:@"Yes" withAttributes:valueAttributes];

        }else{
            if(hours){
                [infoString appendString:[NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")]
                          withAttributes:valueAttributes];
            }else{
                [infoString appendString:[NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")]
                          withAttributes:valueAttributes];
            }
        }
    }

    //Warning
    int warning = [activeListObject integerStatusObjectForKey:@"Warning"];
    if(warning > 0){
        [infoString appendString:@"\r\r\tWarning:\t" withAttributes:labelAttributes];
        [infoString appendString:[NSString stringWithFormat:@"%i%%",warning] withAttributes:valueAttributes];
    }
    
    //Text Profile
	NSAttributedString 	*textProfile = [activeListObject statusObjectForKey:@"TextProfile"];
    if(textProfile && [textProfile length]){
		[infoString appendString:@"\r\r\tProfile:\t" withAttributes:labelAttributes];
		NSMutableAttributedString   *textProfileString = [[[adium contentController] fullyFilteredAttributedString:textProfile 
																								 listObjectContext:activeListObject] mutableCopy];
		NSMutableParagraphStyle     *indentStyle;
		
		NSRange                     firstLineRange = [[textProfileString string] lineRangeForRange:NSMakeRange(0,0)];
		
		//Strip some attributes from info (?)
		//[textProfileString addAttributes:valueAttributes range:NSMakeRange(0,[textProfileString length])];
		
		//Set correct indent & tabbing on the first line of the profile
		[textProfileString addAttribute:NSParagraphStyleAttributeName 
								  value:paragraphStyle 
								  range:NSMakeRange(0,firstLineRange.length)];
		
		//Indent the remaining lines of profile
		indentStyle = [paragraphStyle mutableCopy];
		[indentStyle setFirstLineHeadIndent:InfoIndentB];
		[textProfileString addAttribute:NSParagraphStyleAttributeName 
								  value:indentStyle 
								  range:NSMakeRange(firstLineRange.length, [textProfileString length] - firstLineRange.length)];
		[indentStyle release];
		
		[infoString appendAttributedString:textProfileString];
		[textProfileString release];
    }
    
    //
    [self displayInfo:infoString];
    
}

//Displays the attributed string in the profile view.  Pass nil for no profile
- (void)displayInfo:(NSAttributedString *)infoString
{
    if(infoString && [infoString length]){
        NSColor	*backgroundColor;

        //Display the string
        [[textView_contactProfile textStorage] setAttributedString:infoString];
        [textView_contactProfile resetCursorRects]; //Why must I call this manually?

        //Set the background color
        backgroundColor = [infoString attribute:AIBodyColorAttributeName
										atIndex:0 
						  longestEffectiveRange:nil 
										inRange:NSMakeRange(0,[infoString length])];
        [textView_contactProfile setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];

    }

    [textView_contactProfile setNeedsDisplay:YES];
}

#pragma mark activeListObject management
//Refresh if changes are made to the object we're displaying
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if(inObject == activeListObject){
        [self configureWindow];
    }
    return(nil);
}

//
- (void)contactSelectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium contactController] selectedListObject];
	
	if(object){
		//Remember who we're displaying info for
		[activeListObject release]; activeListObject = [object retain];
		
		[self configureWindow];
		
		//Refresh the window's content (Contacts only)
		if([activeListObject isKindOfClass:[AIListContact class]]){
			[[[AIObject sharedAdiumInstance] contactController] updateListContactStatus:(AIListContact *)activeListObject];
		}
	}
}

#pragma mark Window loading/unloading
+ (id)showInfoWindowForListObject:(AIListObject *)listObject
{
	
    if(!sharedInfoWindowInstance){
        sharedInfoWindowInstance = [[self alloc] initWithWindowNibName:INFO_WINDOW_NIB];
    }
	
	if (listObject) {
		//Remember who we're displaying info for
		[activeListObject release]; activeListObject = [listObject retain];
		
		//Ask contacts to update their info
		if([activeListObject isKindOfClass:[AIListContact class]]){
			[[[AIObject sharedAdiumInstance] contactController] updateListContactStatus:(AIListContact *)activeListObject];
		}
		
		[sharedInfoWindowInstance configureWindow];
	} else {
		[sharedInfoWindowInstance contactSelectionChanged:nil];
	}
	
	//Show the window and configure it for the contact
	[sharedInfoWindowInstance showWindow:nil];
	
    return(sharedInfoWindowInstance);
}

//Close the profile window
+ (void)closeTextProfileWindow
{
    if(sharedInfoWindowInstance){
        [sharedInfoWindowInstance closeWindow:nil];
    }
}

//Private ---------------------------------------------------------------------------

//Refresh the information we're displaying
- (void)refresh:(NSTimer *)timer
{
    [self configureWindow];
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    timer = nil;
    
    return(self);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Configure
    [textView_contactProfile setEditable:NO];

	//Observe selection changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactSelectionChanged:)
									   name:Interface_ContactSelectionChanged
									 object:nil];
	
    //Register ourself as a handle observer
    [[adium contactController] registerListObjectObserver:self];
	
    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_TEXT_PROFILE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_TEXT_PROFILE_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Stop observing and clean up
	[[adium notificationCenter] removeObserver:self];
    [[adium contactController] unregisterListObjectObserver:self];
    [timer invalidate]; [timer release]; timer = nil;
    [activeListObject release]; activeListObject = nil;

    //Close down the shared instance
	[sharedInfoWindowInstance autorelease]; sharedInfoWindowInstance = nil;
    
    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end
