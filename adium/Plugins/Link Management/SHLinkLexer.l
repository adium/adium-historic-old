%{
/* SHLinkLexer.l
 * lex source to verify and identify URL types and completeness
 * 
 * Written by Stephen Holt for Adium, released under the GNU license
 *
 * Optoins used:    noyywrap    : act as if yywrap always returns 1
                    8bit        : always force 8-bit chars.
                    caseless    : case insensitive lexer
                    prefix=...  : replace YY_whatever with prefix - avoids symbol collisions
 */
#define YY_NO_UNPUT
#include "SHLinkLexer.h"
#include <stdlib.h>
%}

domains                 (com|edu|gov|net|org|us|co\.uk|org\.uk|museum|aero|biz|coop|info|int|mil|pro|com\.jp|com\.ar|au|de|es|gb|cl|cn|ie|mx) 
urlSpecifier            [^\/]+(.*\/)*\.{domains}(:\d+)?(\/.*)?
mailSpecifier           [^:].+\@.+\.{domains}

%option noyywrap 8bit caseless prefix="SHLinkLexer"

%x CANONICAL MAILTO
%%
<MAILTO>{mailSpecifier}        {BEGIN INITIAL; return SH_MAILTO_VALID;}
<MAILTO>.*                      {BEGIN INITIAL; return SH_URL_INVALID;}
<CANONICAL>{urlSpecifier}	{BEGIN INITIAL; return SH_URL_VALID;}
<CANONICAL>.*                   {BEGIN INITIAL; return SH_URL_INVALID;}

file:\/\/\/.*     		{return SH_FILE_VALID;}

https?:\/\/	|
ftp:\/\/	|
telnet:\/\/	|
rts:\/\/        |
irc:\/\/	|
nntp:\/\/       |
rstp:\/\/	|
itms:\/\/	|
gopher:\/\/                     {BEGIN CANONICAL;}

mailto:                         {BEGIN MAILTO;}


{mailSpecifier}			{return SH_MAILTO_DEGENERATE;}	
{urlSpecifier}			{return SH_URL_DEGENERATE;}

.				{return SH_URL_INVALID;}
%%
