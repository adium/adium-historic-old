/* Copyright (c) 2003 Colin Barrett */

/* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: */

/* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. */

/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/**********************************************
 * buildnum - generates a unique build number *
 *	     ©2003 - Colin Barrett	      *
 **********************************************/

/* $Id$ */

/* I've included this code as reference, in case you want to know how I generate the buildnum. There's no compling done by PB, it's already done, and the executable is buildnum. -chb. */
 
#include <stdio.h>
#include <time.h>

int main()
{
        const time_t clock = time(NULL);
        struct tm  *t = gmtime(&clock);
        char *str;
        asprintf(&str, "%02d%02d%02d", t->tm_year-100, t->tm_mon+1, 
t->tm_mday);
        printf("%4X", atoi(str));
        free(str);
}
