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

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass date:(NSDate *)inDate
{
    [super init];
	
    path = [inPath retain];
    from = [inFrom retain];
    to = [inTo retain];
	serviceClass = [inServiceClass retain];
    date = [inDate retain];
    dateSearchString = nil;
 	
    return(self);
}

- (void)dealloc
{
    [path release];
    [from release];
    [to release];
	[serviceClass release];
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
- (NSString *)serviceClass{
	return(serviceClass);
}
- (NSDate *)date{
    return(date);
}

- (BOOL)isFromSameDayAsDate:(NSCalendarDate *)inDate
{
	return([[date dateWithCalendarFormat:nil timeZone:nil] dayOfCommonEra] == [inDate dayOfCommonEra]);
}

//Sort by To, then Date
- (NSComparisonResult)compareTo:(AILog *)inLog
{
    NSComparisonResult  result = [to caseInsensitiveCompare:[inLog to]];
    if(result == NSOrderedSame){
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0){
			result = NSOrderedAscending;
		}else if (interval > 0){
			result = NSOrderedDescending;
		}
	}
	
    return(result);
}
- (NSComparisonResult)compareToReverse:(AILog *)inLog
{
    NSComparisonResult  result = [[inLog to] caseInsensitiveCompare:to];
    if(result == NSOrderedSame){
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0){
			result = NSOrderedAscending;
		}else if (interval > 0){
			result = NSOrderedDescending;
		}
	}
	
    return(result);
}
//Sort by From, then Date
- (NSComparisonResult)compareFrom:(AILog *)inLog
{
    NSComparisonResult  result = [from caseInsensitiveCompare:[inLog from]];
    if(result == NSOrderedSame){
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0){
			result = NSOrderedAscending;
		}else if (interval > 0){
			result = NSOrderedDescending;
		}
	} 
	
    return(result);
}
- (NSComparisonResult)compareFromReverse:(AILog *)inLog
{
    NSComparisonResult  result = [[inLog from] caseInsensitiveCompare:from];
    if(result == NSOrderedSame){
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0){
			result = NSOrderedAscending;
		}else if (interval > 0){
			result = NSOrderedDescending;
		}
	}
    
    return(result);
}

//Sort by Date, then To
- (NSComparisonResult)compareDate:(AILog *)inLog
{
	NSComparisonResult  result;
	NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
	
	if (interval < 0){
		result = NSOrderedAscending;
	}else if (interval > 0){
		result = NSOrderedDescending;
	}else{
		result = [to caseInsensitiveCompare:[inLog to]];
    }
	
    return(result);
}
- (NSComparisonResult)compareDateReverse:(AILog *)inLog
{
	NSComparisonResult  result;
	NSTimeInterval		interval = [[inLog date] timeIntervalSinceDate:date];
	
	if (interval < 0){
		result = NSOrderedAscending;
	}else if (interval > 0){
		result = NSOrderedDescending;
	}else{
		result = [[inLog to] caseInsensitiveCompare:to];
    }
	
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
