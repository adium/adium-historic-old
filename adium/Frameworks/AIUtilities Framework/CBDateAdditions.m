//
//  CBDateAdditions.m
//  Adium
//
//  Created by Colin Barrett on Sun Sep 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
/*
#import "CBDateAdditions.h"
#include <sys/types.h>
#include <sys/stat.h>

#define PATH_TO_PLIST [@"~/Library/Preferences/.GlobalPreferences.plist"\
    stringByExpandingTildeInPath]

/*******************************
* compute the crc of a file
*
* Colin Barrett, Adium
*
* Based on crc code by David Gentzel
* http://www-genome.wi.mit.edu/ftp/pub/software/rhmapper/RHMAPPER-0.9/binhex/crc.c
*/
/*
#include <stdio.h>

#define BYTEMASK	0xFF
#define WORDMASK	0xFFFF
#define WORDBIT		0x10000

#define CRCCONSTANT	0x1021

#define DOCRC(x)				\
temp = crc;					\
for(i = 0; i < 8; i++)				\
{						\
    x <<= 1;					\
    if((temp <<= 1) & WORDBIT)			\
        temp = (temp & WORDMASK) ^ CRCCONSTANT;	\
    temp ^= (x >> 8);				\
    x &= BYTEMASK;				\
}						\
crc = temp;

char *crc_for_file(FILE *inn)
{
    unsigned int crc = 0;
    unsigned long temp;
    int c, i;
    char *return_me = "";
    if(in != NULL)
        while((c = getc(inn)) != EOF)
            DOCRC(c)
    DOCRC(0)
    DOCRC(0)
    sprintf(return_me, "%ud%ud", (crc >> 8) & BYTEMASK, crc & BYTEMASK);
	
    return return_me;
}
/*******************************/
/*
@implementation NSDate (TimestampAdditions)

- (NSString *)getTimestampWithSeconds:(BOOL)getSeconds
{
    static	char 		*checksum = "NO VALUE";
    static	long		moddate = -1;
    static 	NSString	*timestamp = @"NO VALUE";
    
    char *newsum = "";
    long newdate = -1;
    
    int update = 0;
    
    /*
    if(strcmp(checksum, "NO VALUE") != 0)
    {
        //get modification date        
        
        if(moddate != -1 && moddate != newdate)
        {
            //calculate the checksum
            FILE *f = fopen([PATH_TO_PLIST cstring], "r");
            newsum = crc_for_file(f);
            fclose(f);
        }
        if(strcmp(checksum, "NO VALUE") != 0
            && moddate != -1 
            && moddate != newdate
            && strcmp(checksum, newsum) !=0)
        {
            checksum = newsum;
            timestamp = [[NSDictionary dictionaryWithContentsOfFile:PATH_TO_PLIST] objectForKey:@"NSTimeFormatString"];
            
        }
    }*/
    /*

    if()
    
    
    
    return timestamp;
}

@end*/
