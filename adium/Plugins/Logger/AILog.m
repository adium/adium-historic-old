/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AILoggerPlugin.h"
#import "AILog.h"
#import "AILogViewerWindowController.h"

#define OLD_SUFFIX  @".adiumLog.html"

@implementation AILog

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo date:(NSCalendarDate *)inDate
{
    [super init];

    //Temprary Code.  This can be removed once everyone who ran the alpha has opened their log viewer :)
    //
    //Rename Adium 2.0 alpha logs.  Logs saved after the format change and before this viewer use
    //the filename format: adam_(2003|11|16).adiumLog.html
    //
    //We want to convert these to: adam (2003|11|16).html
    //
    if([inPath hasSuffix:OLD_SUFFIX]){
	NSString    *newPath;
	NSString    *fileName = [inPath lastPathComponent];
	NSString    *filePath = [inPath stringByDeletingLastPathComponent];
	NSRange     underRange = [fileName rangeOfString:@"_"];
		
	//Remove the .adiumLog and the '_'
	fileName = [NSString stringWithFormat:@"%@.html",[fileName substringToIndex:([fileName length] - [OLD_SUFFIX length])]];
	fileName = [NSString stringWithFormat:@"%@ %@",[fileName substringToIndex:underRange.location], [fileName substringFromIndex:underRange.location+1]];
	
	//Rename
	newPath = [filePath stringByAppendingPathComponent:fileName];
	[[NSFileManager defaultManager] movePath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:inPath]
					  toPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:newPath]
					 handler:nil];
	inPath = newPath;
    }
    
    path = [inPath retain];
    from = [inFrom retain];
    to = [inTo retain];
    date = [inDate retain];
    dateSearchString = nil;
 	
    return(self);
}

- (void)dealloc
{
    [path release];
    [from release];
    [to release];
    [date release];
    [dateSearchString release];
    
    [super dealloc];
}

- (NSString *)path{
    return(path);
}
- (NSString *)from{
    return(from);
}
- (NSString *)to{
    return(to);
}
- (NSDate *)date{
    return(date);
}
- (NSString *)dateSearchString
{
    static NSFormatter     *dateSearchFormatter = nil;
    
    //Setup our shared date formatter
    if(!dateSearchFormatter){
	NSString    *searchFormat = [NSString stringWithFormat:@"%@ %@",
	    [[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString],
	    [[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString]];
	dateSearchFormatter = [[NSDateFormatter alloc] initWithDateFormat:searchFormat allowNaturalLanguage:YES];
    }
    
    //Load and cache our search string
    if(!dateSearchString){
	dateSearchString = [[dateSearchFormatter stringForObjectValue:date] retain];
    }
    
    return(dateSearchString);
}

- (NSComparisonResult)compareTo:(AILog *)inLog{
    return([to caseInsensitiveCompare:[inLog to]]);
}
- (NSComparisonResult)compareToReverse:(AILog *)inLog{
    return([[inLog to] caseInsensitiveCompare:to]);
}
- (NSComparisonResult)compareFrom:(AILog *)inLog{
    return([from caseInsensitiveCompare:[inLog from]]);
}
- (NSComparisonResult)compareFromReverse:(AILog *)inLog{
    return([[inLog from] caseInsensitiveCompare:from]);
}
- (NSComparisonResult)compareDate:(AILog *)inLog{
    return([date compare:[inLog date]]);
}
- (NSComparisonResult)compareDateReverse:(AILog *)inLog{
    return([[inLog date] compare:date]);
}

//Returns the date specified by a filename
+ (NSCalendarDate *)dateFromFileName:(NSString *)fileName
{
    int     year = 0;
    int     month = 0;
    int     day = 0;
    
    //
    if(sscanf([fileName cString],"%*s (%i|%i|%i)%*s", &year, &month, &day)){
        return([NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]]);
    }else{
        return(nil);
    }
}

@end
