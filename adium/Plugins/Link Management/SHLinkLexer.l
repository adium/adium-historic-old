%{
/* SHLinkLexer.l
 * lex source to verify and identify URL types and completeness
 * 
 * Written by Stephen Holt for Adium, released under the GPL
 *
 * Optoins used:	noyywrap    : act as if yywrap always returns 1
 *			8bit        : always force 8-bit chars.
 *			caseless    : case insensitive lexer
 *			prefix=...  : replace YY_whatever with prefix - avoids symbol collisions
 */
#define YY_NO_UNPUT
#include "SHLinkLexer.h"
%}


ccTLD		(ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|fi|fj|fk|fm|fo|fr|ga|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)
sTLD		(com|edu|gov|int|mil|net|org|biz|info|name|pro)
uTLD		(aero|coop|museum)

domains		({ccTLD}|{sTLD}|{uTLD}|arpa)
urlSpecifier	[^\/]+((.*:)?.*@)?(.*\/)*\.{domains}(:[0-9]+)?(\/.*)?
mailSpecifier	[^:\/]+\@.+\.{domains}
jabberSpec      "xmpp:".*@.+\.{domains}(\/.*)?
aolIMSpec       "aim:goim?screenname="[^\s&]+("&message=".+)?


%option noyywrap 8bit caseless prefix="SHLinkLexer"

%x CANONICAL
%%

<CANONICAL>{urlSpecifier}   {BEGIN INITIAL; return SH_URL_VALID;}
<CANONICAL>.*		    {BEGIN INITIAL; return SH_URL_INVALID;}

file:\/\/\/.*		    {return SH_FILE_VALID;}

https?:\/\/	|
ftp:\/\/	|
ssh:\/\/        |
telnet:\/\/	|
rts:\/\/        |
irc:\/\/	|
nntp:\/\/       |
rstp:\/\/	|
itms:\/\/	|
gopher:\/\/		    {BEGIN CANONICAL;}

mailto:{mailSpecifier}      {return SH_MAILTO_VALID;}


{mailSpecifier}		    {return SH_MAILTO_DEGENERATE;}	
{urlSpecifier}		    {return SH_URL_DEGENERATE;}

{jabberSpec}		    {return SH_URL_VALID;}
{aolIMSpec}		    {return SH_URL_VALID;}

.			    {return SH_URL_INVALID;}
%%
