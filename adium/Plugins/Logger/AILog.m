/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

void scandate(const char *sample, unsigned long *outyear, unsigned long *outmonth, unsigned long *outdate);

@implementation AILog

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo date:(NSCalendarDate *)inDate
{
    [super init];
	
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

//Sort by To, then Date
- (NSComparisonResult)compareTo:(AILog *)inLog
{
    NSComparisonResult  result = [to caseInsensitiveCompare:[inLog to]];
    if(result == NSOrderedSame) result = [date compare:[inLog date]];
	
    return(result);
}
- (NSComparisonResult)compareToReverse:(AILog *)inLog
{
    NSComparisonResult  result = [[inLog to] caseInsensitiveCompare:to];
    if(result == NSOrderedSame) result = [date compare:[inLog date]];
	
    return(result);
}
//Sort by From, then Date
- (NSComparisonResult)compareFrom:(AILog *)inLog
{
    NSComparisonResult  result = [from caseInsensitiveCompare:[inLog from]];
    if(result == NSOrderedSame) result = [date compare:[inLog date]];
    
    return(result);
}
- (NSComparisonResult)compareFromReverse:(AILog *)inLog
{
    NSComparisonResult  result = [[inLog from] caseInsensitiveCompare:from];
    if(result == NSOrderedSame) result = [date compare:[inLog date]];
    
    return(result);
}

//Sort by Date, then To
- (NSComparisonResult)compareDate:(AILog *)inLog
{
    NSComparisonResult  result = [date compare:[inLog date]];
    if(result == NSOrderedSame) result = [to caseInsensitiveCompare:[inLog to]];
    
    return(result);
}
- (NSComparisonResult)compareDateReverse:(AILog *)inLog
{
    NSComparisonResult  result = [[inLog date] compare:date];
    if(result == NSOrderedSame) result = [to caseInsensitiveCompare:[inLog to]];
    
    return(result);
}

//Returns the date specified by a filename
+ (NSCalendarDate *)dateFromFileName:(NSString *)fileName
{
    unsigned long   year = 0;
    unsigned long   month = 0;
    unsigned long   day = 0;
	
    scandate([fileName cString], &year, &month, &day);
    if(year && month && day){
        return([NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]]);
    }else{
        return(nil);
    }
}

//Scan an Adium date string, supahfast C style
//Submitted by Mac-arena the Bored Zo
void scandate(const char *sample, unsigned long *outyear, unsigned long *outmonth, unsigned long *outdate) {
    //read three numbers, starting after a space.
    while(*sample != ' ') ++sample;
    sample += 2; //skip over the ' ('
    
    /*get the year*/ {
		while(*sample < '0' || *sample > '9') ++sample;
		*outyear = strtoul(sample, (char **)&sample, 10);
    }
    
    /*get the month*/ {
		while(*sample < '0' || *sample > '9') ++sample;
		*outmonth = strtoul(sample, (char **)&sample, 10);
    }
    
    /*get the date*/ {
		while(*sample < '0' || *sample > '9') ++sample;
		*outdate = strtoul(sample, (char **)&sample, 10);
    }
}

@end
