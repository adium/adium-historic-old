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

//$Id$

#import "AISoundController.h"
#import "LNAboutBoxController.h"
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/ESDateFormatterAdditions.h>

#define ABOUT_BOX_NIB					@"AboutBox"
#define	ADIUM_SITE_LINK					@"http://www.adiumx.com/"

#define ABOUT_SCROLL_FPS				30.0
#define ABOUT_SCROLL_RATE				1.0

@interface LNAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (BOOL)windowShouldClose:(id)sender;
- (NSString *)_applicationVersion;
- (void)_loadBuildInformation;
@end

@implementation LNAboutBoxController

//Returns the shared about box instance
LNAboutBoxController *sharedAboutBoxInstance = nil;
+ (LNAboutBoxController *)aboutBoxController
{
    if(!sharedAboutBoxInstance){
        sharedAboutBoxInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB];
    }
    return(sharedAboutBoxInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    numberOfDuckClicks = -1;
    
    return(self);
}

//Dealloc
- (void)dealloc
{    
    [buildNumber release];
    [buildDate release];
    
    [super dealloc];
}

//Prepare the about box window
- (void)windowDidLoad
{
    NSAttributedString		*creditsString;
    
    //Load our build information and avatar list
    [self _loadBuildInformation];

    //Credits
    creditsString = [[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits.rtf" ofType:nil] documentAttributes:nil] autorelease];
    [[textView_credits textStorage] setAttributedString:creditsString];
    [[textView_credits enclosingScrollView] setLineScroll:0.0];
    [[textView_credits enclosingScrollView] setPageScroll:0.0];
    
    //Start scrolling    
    scrollLocation = 0; 
    scrollRate = ABOUT_SCROLL_RATE;
    maxScroll = [[textView_credits textStorage] size].height - [[textView_credits enclosingScrollView] documentVisibleRect].size.height;
    scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
													target:self
												  selector:@selector(scrollTimer:)
												  userInfo:nil
												   repeats:YES] retain];
	eventLoopScrollTimer = [[NSTimer timerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
												   target:self
												 selector:@selector(scrollTimer:)
												 userInfo:nil
												  repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:eventLoopScrollTimer forMode:NSEventTrackingRunLoopMode];
	
    //Setup the build date / version
    [button_buildButton setTitle:buildDate];
    [textField_version setStringValue:[self _applicationVersion]];
    
	//Set the localized values
	[[self window] setTitle:AILocalizedString(@"About Adium","About window title")];
	[button_homepage setTitle:AILocalizedString(@"Adium Homepage",nil)];
	[button_license setTitle:AILocalizedString(@"License",nil)];

    [[self window] betterCenter];
}

//Close the about box
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Cleanup as the window is closing
- (BOOL)windowShouldClose:(id)sender
{
    [sharedAboutBoxInstance autorelease]; sharedAboutBoxInstance = nil;
    [scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;
	[eventLoopScrollTimer invalidate]; [eventLoopScrollTimer release]; eventLoopScrollTimer = nil;
	
    return(YES);
}

//Visit the Adium homepage
- (IBAction)visitHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.adiumx.com"]];
}


//Scrolling Credits ----------------------------------------------------------------------------------------------------
#pragma mark Scrolling Credits
//Scroll the credits
- (void)scrollTimer:(NSTimer *)scrollTimer
{    
	scrollLocation += scrollRate;
	
	if(scrollLocation > maxScroll) scrollLocation = 0;    
	if(scrollLocation < 0) scrollLocation = maxScroll;
	
	[textView_credits scrollPoint:NSMakePoint(0, scrollLocation)];
}

//Receive the flags changed event for reversing the scroll direction via option
- (void)flagsChanged:(NSEvent *)theEvent
{
    if([theEvent optionKey]) {
        scrollRate = -ABOUT_SCROLL_RATE;
    }else{
        scrollRate = ABOUT_SCROLL_RATE;   
    }
}


//Build Information ----------------------------------------------------------------------------------------------------
#pragma mark Build Information
//Toggle build date/number display
- (IBAction)buildFieldClicked:(id)sender
{
    if((++numberOfBuildFieldClicks) % 2 == 0){
        [button_buildButton setTitle:buildDate];
    }else{
		[button_buildButton setTitle:buildNumber];
    }
}

//Returns the current version of Adium
- (NSString *)_applicationVersion
{
    NSString	*version = [NSApp applicationVersion];
    return([NSString stringWithFormat:@"Adium X %@",(version ? version : @"")]);
}

//Load the current build date and our cryptic, non-sequential build number ;)
- (void)_loadBuildInformation
{
    //Grab the info from our buildnum script
    char *path, unixDate[256], num[256], whoami[256];
    if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation])
    {
        FILE *f = fopen(path, "r");
        fscanf(f, "%s | %s | %s", num, unixDate, whoami);
        fclose(f);
		
        if(*num){
            buildNumber = [[NSString stringWithFormat:@"%s", num] retain];
		}
		
		if(*unixDate){
			NSDateFormatter *dateFormatter = [NSDateFormatter localizedDateFormatter];

			NSDate	    *date;
			
			date = [NSDate dateWithTimeIntervalSince1970:[[NSString stringWithCString:unixDate] doubleValue]];
            buildDate = [[dateFormatter stringForObjectValue:date] retain];
		}
    }
	
    //Default to empty strings if something goes wrong
    if(!buildDate) buildDate = [@"" retain];
    if(!buildNumber) buildNumber = [@"" retain];
}


//Software License -----------------------------------------------------------------------------------------------------
#pragma mark Software License
//Display the software license sheet
- (IBAction)showLicense:(id)sender
{
	NSString	*licensePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"License" ofType:@"txt"];
	[textView_license setString:[NSString stringWithContentsOfFile:licensePath]];
	
	[NSApp beginSheet:panel_licenseSheet
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

//Close the software license sheet
- (IBAction)hideLicense:(id)sender
{
    [panel_licenseSheet orderOut:nil];
    [NSApp endSheet:panel_licenseSheet returnCode:0];
}


//Sillyness ----------------------------------------------------------------------------------------------------
#pragma mark Sillyness
//Flap the duck when clicked
- (IBAction)adiumDuckClicked:(id)sender
{
    numberOfDuckClicks++;

	if(numberOfDuckClicks == 10){
		numberOfDuckClicks = -1;            
		[[adium soundController] playSoundNamed:@"/Adium.AdiumSoundset/Feather Ruffle.aif"];
	}else{
		[[adium soundController] playSoundNamed:@"/Adium.AdiumSoundset/Quack.aif"];
	}
	
}


@end
