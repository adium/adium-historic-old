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

@interface AILog : NSObject {
    NSString	    *path;
    NSString	    *from;
    NSString	    *to;
	NSString		*serviceClass;
    NSDate			*date;
    NSString	    *dateSearchString;
	float			rankingPercentage;
}

//Given an Adium log file name, return an NSCalendarDate with year, month, and day specified
+ (NSCalendarDate *)dateFromFileName:(NSString *)fileName;

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass date:(NSDate *)inDate;

//Accessors
- (NSString *)path;
- (NSString *)from;
- (NSString *)to;
- (NSString *)serviceClass;
- (NSDate *)date;
- (float)rankingPercentage;
- (void)setRankingPercentage:(float)inRankingPercentage;

//Comparisons
- (BOOL)isFromSameDayAsDate:(NSCalendarDate *)inDate;
- (NSComparisonResult)compareTo:(AILog *)inLog;
- (NSComparisonResult)compareToReverse:(AILog *)inLog;
- (NSComparisonResult)compareFrom:(AILog *)inLog;
- (NSComparisonResult)compareFromReverse:(AILog *)inLog;
- (NSComparisonResult)compareDate:(AILog *)inLog;
- (NSComparisonResult)compareDateReverse:(AILog *)inLog;
	
@end
