/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIChatLog.h"
#import "AILogViewerWindowController.h"

void scandate(const char *sample, unsigned long *outyear, unsigned long *outmonth, unsigned long *outdate);

@implementation AIChatLog

static	NSTimeZone	*defaultTimeZone = nil;

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass date:(NSDate *)inDate
{
    [super init];
	
	if(!defaultTimeZone) defaultTimeZone = [[NSTimeZone defaultTimeZone] retain];
		
    path = [inPath retain];
    from = [inFrom retain];
    to = [inTo retain];
	serviceClass = [inServiceClass retain];
    date = [inDate retain];
    dateSearchString = nil;
 	rankingPercentage = 0;
	
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

- (float)rankingPercentage{
	return(rankingPercentage);
}
- (void)setRankingPercentage:(float)inRankingPercentage{
	rankingPercentage = inRankingPercentage;
}

- (BOOL)isFromSameDayAsDate:(NSCalendarDate *)inDate
{
	return([[date dateWithCalendarFormat:nil timeZone:nil] dayOfCommonEra] == [inDate dayOfCommonEra]);
}

//Sort by To, then Date
- (NSComparisonResult)compareTo:(AIChatLog *)inLog
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
- (NSComparisonResult)compareToReverse:(AIChatLog *)inLog
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
- (NSComparisonResult)compareFrom:(AIChatLog *)inLog
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
- (NSComparisonResult)compareFromReverse:(AIChatLog *)inLog
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
- (NSComparisonResult)compareDate:(AIChatLog *)inLog
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
- (NSComparisonResult)compareDateReverse:(AIChatLog *)inLog
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

-(NSComparisonResult)compareRank:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	float				otherRankingPercentage = [inLog rankingPercentage];
	
	if (rankingPercentage > otherRankingPercentage){
		result = NSOrderedDescending;		
	}else if (rankingPercentage < otherRankingPercentage){
		result = NSOrderedAscending;	
	}else{
		result = [to caseInsensitiveCompare:[inLog to]];
    }
	
	return(result);
}
-(NSComparisonResult)compareRankReverse:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	float				otherRankingPercentage = [inLog rankingPercentage];
	
	if (rankingPercentage > otherRankingPercentage){
		result = NSOrderedAscending;		
	}else if (rankingPercentage < otherRankingPercentage){
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
        return([NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:defaultTimeZone]);
    }else{
        return(nil);
    }
}

//Scan an Adium date string, supahfast C style
//Submitted by Mac-arena the Bored Zo
void scandate(const char *sample, unsigned long *outyear, unsigned long *outmonth, unsigned long *outdate) {
    //read three numbers, starting after:
	
	//a space...
    while(*sample != ' ') ++sample;
	
	//...followed by a (
	while(*sample != '(') ++sample;
	
    sample += 1; //start with the next character
    
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
