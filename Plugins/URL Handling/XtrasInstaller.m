//
//  XtrasInstaller.m
//  IMGamesPluginInstaller
//
//  Created by Sam McCandlish on 10/12/04.
//

#import "XtrasInstaller.h"

//Should only be YES for testing
#define	ALLOW_UNTRUSTED_XTRAS	NO

@interface XtrasInstaller (PRIVATE)
- (void)closeInstaller;
@end

@implementation XtrasInstaller
+ (XtrasInstaller *)installer
{
	return([[XtrasInstaller alloc] init]);
}

- (id)init
{
	if(self = [super init]){
		download = nil;
		window = nil;
	}

	return(self);
}

- (void)dealloc
{
	[download release];

	[super dealloc];
}

- (IBAction)cancel:(id)sender;
{
	[download cancel];
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(download) [download cancel];

	[self closeInstaller];
}

- (void)closeInstaller
{
	if(window) [window close];
	[self autorelease];	
}

- (void)installXtraAtURL:(NSURL *)url
{
	if([[url host] isEqualToString:@"www.adiumxtras.com"] || ALLOW_UNTRUSTED_XTRAS){
		NSURL	*urlToDownload;

		[NSBundle loadNibNamed:@"XtraProgressWindow" owner:self];
		[progressBar setUsesThreadedAnimation:YES];
		
		[progressBar setDoubleValue:0];
		[percentText setStringValue:@"0%"];
		[cancelButton setStringValue:AILocalizedString(@"Cancel",nil)];
		[window setTitle:AILocalizedString(@"Xtra Download",nil)];
		[window makeKeyAndOrderFront:self];

		urlToDownload = [[NSURL alloc] initWithScheme:@"http" host:[url host] path:[url path]];
		dest = [NSTemporaryDirectory() stringByAppendingPathComponent:[[urlToDownload path] lastPathComponent]];

		download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:urlToDownload] delegate:self];
		[download setDestination:dest allowOverwrite:YES];

		[urlToDownload release];

	}else{
		NSRunAlertPanel(AILocalizedString(@"Nontrusted Xtra", nil),
						AILocalizedString(@"This Xtra is not hosted by adiumxtras.com. Automatic installation is not allowed.", nil),
						AILocalizedString(@"Cancel", nil),
						nil, nil);
		[self closeInstaller];
	}
}

- (void)download:(NSURLDownload *)connection didReceiveResponse:(NSURLResponse *)response
{
	amountDownloaded = 0;
	downloadSize = [response expectedContentLength];
	[progressBar setMaxValue:(long long)downloadSize];
	[progressBar setDoubleValue:0.0];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	amountDownloaded += (long long)length;
	if(downloadSize != NSURLResponseUnknownLength){
		[progressBar setDoubleValue:(double)amountDownloaded];
		[percentText setStringValue:[NSString stringWithFormat:@"%f%",(double)((amountDownloaded / (double)downloadSize) * 100)]];
	}
	else
		[progressBar setIndeterminate:YES];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
    return(NO);
}

- (void)download:(NSURLDownload *)inDownload didFailWithError:(NSError *)error {
	NSString	*errorMsg;

	errorMsg = [NSString stringWithFormat:@"An error occurred while downloading this Xtra: %@.",[error localizedDescription]];
	
	NSBeginAlertSheet(@"Xtra Downloading Error", @"Cancel", nil, nil, window, self,
					 NULL, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, errorMsg);
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	NSPipe			*outputPipe = [NSPipe pipe];
	NSFileHandle	*output;
	NSString		*fileName;
	
	NSString		*lastPathComponent = [[dest lowercaseString] lastPathComponent];
	NSString		*pathExtension = [lastPathComponent pathExtension];

	if([pathExtension isEqualToString:@"tgz"] || [lastPathComponent hasSuffix:@".tar.gz"]){
		NSTask			*uncompress, *untar;

		uncompress = [[NSTask alloc] init];
		[uncompress setLaunchPath:@"/usr/bin/gunzip"];
		[uncompress setArguments:[NSArray arrayWithObjects:@"-df" , [dest lastPathComponent] ,  nil]];
		[uncompress setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
		
		[uncompress launch];
		[uncompress waitUntilExit];
		[uncompress release];
		
		if([pathExtension isEqualToString:@"tgz"]){
			dest = [[dest stringByDeletingPathExtension] stringByAppendingPathExtension:@"tar"];
		}else{
			//hasSuffix .tar.gz
			dest = [dest substringToIndex:[dest length] - 3];//remove the .gz, leaving us with .tar
		}
		
		untar = [[NSTask alloc] init];
		[untar setLaunchPath:@"/usr/bin/tar"];
		[untar setArguments:[NSArray arrayWithObjects:@"-xvf", [dest lastPathComponent], nil]];
		[untar setStandardOutput:outputPipe];
		[untar setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
		
		[untar launch];
		[untar waitUntilExit];
		[untar release];

		//get the name of the untared file, which will be output on the first line
		output = [outputPipe fileHandleForReading];
		fileName = [[[[[NSString alloc] initWithData:[output readDataToEndOfFile]
											encoding:NSASCIIStringEncoding] autorelease] componentsSeparatedByString:@"\n"] objectAtIndex:0];		
	}else if([pathExtension isEqualToString:@"zip"]){
		NSTask	*unzip;
		
		//First, perform the actual unzipping
		unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		[unzip setArguments:[NSArray arrayWithObjects:
			@"-o",  /* overwrite */
			@"-q", /* quiet! */
			dest, /* source zip file */
			@"-d", [dest stringByDeletingLastPathComponent], /*destination folder*/
			nil]];

		[unzip setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];

		[unzip launch];
		[unzip waitUntilExit];
		[unzip release];

		//Now get the name of the unzipped file/directory, which will be output in a format like this:
		/*
		 Archive:  Get Info Window Layout.ListLayout.zip
		 Length     Date   Time    Name
		 --------    ----   ----    ----
		 1414  08-30-04 22:48   Get Info Window Layout.ListLayout
		 --------                   -------
		 1414                   1 file
		 */
		unzip = [[NSTask alloc] init];
		outputPipe = [NSPipe pipe];

		[unzip setLaunchPath:@"/usr/bin/unzip"];
		[unzip setArguments:[NSArray arrayWithObjects:
			@"-l",  /* list files */
			dest, /* source zip file */
			nil]];
		[unzip setStandardOutput:outputPipe];
		
		[unzip launch];
		[unzip waitUntilExit];
		[unzip release];

		output = [outputPipe fileHandleForReading];
		NSString	*outputString = [[[NSString alloc] initWithData:[output readDataToEndOfFile]
														   encoding:NSASCIIStringEncoding] autorelease];
		NSString	*outputLine = [[outputString componentsSeparatedByString:@"\n"] objectAtIndex:3];

		NSArray		*outputComponents = [outputLine componentsSeparatedByString:@" "];
		unsigned	count = [outputComponents count];
		unsigned	i = 0;
		unsigned	validComponentsFound = 0;
		
		//Loop past the length, date, and time components to get to the name, the 4th valid component
		for(i = 0; i < count; i++){
			if([(NSString *)[outputComponents objectAtIndex:i] length]){
				validComponentsFound++;
				
				if(validComponentsFound == 4){
					break;
				}
			}
		}
		
		//From the beginning of the file name onward, rejoin to get the original fileName
		fileName = [[outputComponents subarrayWithRange:NSMakeRange(i, count-i)] componentsJoinedByString:@" "];
	}
	
	[[NSFileManager defaultManager] removeFileAtPath:dest handler:nil];

	dest = [[dest stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];

	//Open the file so Adium can install it and then delete it
	[[NSWorkspace sharedWorkspace] openTempFile:dest];

	[self closeInstaller];
}

@end
