%{
/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 *	Options used:	noyywrap            : act as if yywrap always returns 1
 *					8bit                : always force 8-bit chars.
 *					caseless            : case insensitive lexer
 *					never-interactive   : prevents flex from including some calls to gettty() and such
 *										  -- gives a slight performace gain.
 *					prefix=...          : replace YY_whatever with prefix - avoids symbol collisions
 *					debug               : turns on debugging output (string + accepting rule)
 *										  -- only use while editing rules, and don't commit with this on
 *										     (it generates a lot of unnecessary output and kills performace.)
 *
 *	Variables used:		uint AHStringOffset : the position of the pointer, relative to the parent string
 *											  incremented by yyleng at each yylex() call.
 *	               		 int AHValidShift	: Used only in CANONICAL start state
 *											  ensures that yyleng reports whole length of the string,
 *											  without a costly call to yymore().
 */
unsigned int AHStringOffset;
int AHValidShift = 0;
#include "AHLinkLexer.h"
%}

ccTLDtypeB1     (co.ao|ed.ao|gv.ao|it.ao|og.ao|pb.ao|com.ar|gov.ar|int.ar|mil.ar|net.ar|org.ar|com.bd|edu.bd|net.bd|gov.bd|org.bd|mil.bd|com.bn|edu.bn|org.bn|net.bn|gr.br|am.br|art.br|edu.br|com.br|coop.br|esp.br|far.br|fm.br|g12.br|gov.br|imb.br|ind.br|inf.br|mil.br|net.br|org.br|psi.br|rec.br|srv.br|tmp.br|tur.br|tv.br|etc.br|adm.br|adv.br|arq.br|ato.br|bio.br|bmd.br|cim.br|cng.br|cnt.br|ecn.br|eng.br|eti.br|fnd.br|fot.br|fst.br|ggf.br|jor.br|lel.br|mat.br|med.br|mus.br|not.br|ntr.br|odo.br|ppg.br|pro.br|psc.br|qsl.br|slg.br|trd.br|vet.br|zlg.br|dpn.br|nom.br|com.co|edu.co|org.co|gov.co|mil.co|net.co|nom.co|ac.cr|co.cr|ed.cr|fi.cr|go.cr|or.cr|sa.cr|com.cyr|biz.cy|info.cy|ltd.cy|pro.cy|net.cy|org.cy|name.cy|tm.cy|ac.cy|ekloges.cy|press.cy|parliament.cy|edu.do|gov.do|gob.do|com.do|org.do|sld.do|web.do|net.do|mil.do|art.do|eun.eg|edu.eg|sci.eg|gov.eg|com.eg|org.eg|net.eg|mil.eg|com.et|gov.et|org.et|edu.et|net.et|biz.et|name.et|info.et|biz.fj|com.fj|info.fj|name.fj|net.fj|org.fj|pro.fj|ac.fj|gov.fj|mil.fj|school.fj|co.fk|org.fk|gov.fk|ac.fk|nom.fk|net.fk|com.gh|edu.gh|gov.gh|org.gh|mil.gh|com.gn|ac.gn|gov.gn|org.gn|net.gn|ac.id|co.id|or.id|go.id|ac.il|co.il|org.il|net.il|k12.il|gov.il|muni.il|idf.il|edu.jm|gov.jm|com.jm|net.jm|org.jm|per.kh|com.kh|edu.kh|gov.kh|mil.kh|net.kh|org.kh|com.kw|edu.kw|gov.kw|net.kw|org.kw|mil.kw|org.kz|edu.kz|net.kz|gov.kz|mil.kz|com.kz|net.lb|org.lb|gov.lb|edu.lb|com.lb|com.lc|org.lc|edu.lc|gov.lc|com.lr|edu.lr|gov.lr|org.lr|net.lr|org.ls|co.ls|aero.mv|biz.mv|com.mv|coop.mv|edu.mv|gov.mv|info.mv|int.mv|mil.mv|museum.mv|name.mv|net.mv|org.mv|pro.mv)

ccTYBtypeB2     (ac.mw|co.mw|com.mw|coop.mw|edu.mw|gov.mw|int.mw|museum.mw|net.mw|org.mw|com.mx|net.mx|org.mx|edu.mx|gob.mx|com.my|net.my|org.my|gov.my|edu.my|mil.my|name.my|edu.ng|com.ng|gov.ng|org.ng|net.ng|gob.ni|com.ni|edu.ni|org.ni|nom.ni|net.ni|com.np|org.np|edu.np|net.np|gov.np|mil.np|ac.nz|co.nz|cri.nz|gen.nz|geek.nz|govt.nz|iwi.nz|maori.nz|mil.nz|net.nz|org.nz|school.nz|com.om|co.om|edu.om|ac.com|sch.om|gov.om|net.om|org.om|mil.om|museum.om|biz.om|pro.om|med.om|com.pa|ac.pa|sld.pa|gob.pa|edu.pa|org.pa|net.pa|abo.pa|ing.pa|med.pa|nom.pa|com.pe|org.pe|net.pe|edu.pe|mil.pe|gob.pe|nom.pe|com.pg|net.pg|net.py|org.py|gov.py|edu.py|com.py|com.sa|edu.sa|sch.sa|med.sa|gov.sa|net.sa|org.sa|pub.sa|com.sb|gov.sb|net.sb|edu.sb|edu.sv|com.sv|gob.sv|org.sv|red.sv|gov.sy|com.sy|net.sy|ac.th|co.th|in.th|go.th|mi.th|or.th|net.th|com.tn|intl.tn|gov.tn|org.tn|ind.tn|nat.tn|tourism.tn|info.tn|ens.tn|fin.tn|net.tn|co.tz|ac.tz|go.tz|or.tz|ne.tz|ac.uk|co.uk|gov.uk|ltd.uk|me.uk|mil.uk|mod.uk|net.uk|nic.uk|nhs.uk|org.uk|plc.uk|police.uk|sch.uk|bl.uk|british-library.uk|icnet.uk|jet.uk|nel.uk|nls.uk|national-library-scotland.uk|parliament.uk|edu.uy|gub.uy|org.uy|com.uy|net.uy|mil.uy|vatican.va|com.ve|net.ve|org.ve|info.ve|co.ve|web.ve|com.ye|net.ye|ac.yu|co.yu|org.yu|edu.yu|ac.za|city.za|co.za|edu.za|gov.za|law.za|mil.za|nom.za|org.za|school.za|alt.za|net.za|ngo.za|tm.za|web.za|co.zm|org.zm|gov.zm|sch.zm|ac.zm|co.zw|org.zw|gov.zw|ac.zw)

ccTYBtypeB      {ccTLDtypeB1|ccTYBtypeB2}

ccTLD           (ac|ad|ae|af|ag|ai|al|am|an|aq|as|at|au|aw|az|ba|bb|be|bf|bg|bh|bi|bj|bm|bo|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|cu|cv|cx|cz|de|dj|dk|dm|dz|ec|ee|eh|er|es|eu|fi|fm|fo|fr|ga|gd|ge|gf|gg|gi|gl|gm|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|ie|im|in|io|iq|ir|is|it|je|jo|jp|ke|kg|ki|km|kn|kp|kr|ky|la|li|lk|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mz|na|nc|ne|nf|nl|no|nr|nu|pf|ph|pk|pl|pm|pn|pr|ps|pt|pw|qa|re|ro|ru|rw|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|sz|tc|td|tf|tg|tj|tk|tm|to|tp|tr|tt|tv|tw|ua|ug|um|us|uz|vc|vg|vi|vn|vu|wf|ws|ye|yt)
sTLD            (com|edu|gov|int|mil|net|org|biz|info|name|pro)
uTLD            (aero|coop|museum|mobi|cat|jobs|travel)

domains         (ccTLDtypeB|{ccTLD}|{sTLD}|{uTLD}|arpa|local)
%{
/*The Unicode standard, version 4.1, table 3-6, says that the highest byte that will occur in a valid UTF-8 sequence is 0xF4.*/
%}
userAndPass     [^:@]+(:[^:@]+)?
urlPath         \/[^[:space:]]*
urlSpecifier    ([_[:alnum:]\x80-\xf4-]+\.)+{domains}(:[0-9]+)?{urlPath}?
ipv4address     ([0-9]{1,3}\.){3}([0-9]{1,3})
ipURL           {ipv4address}(:[0-9]+)?{urlPath}?
singleDomain    [[:alnum:]\x80-\xf4-]+
mailSpecifier   [^:\/]+\@.+\.{domains}
jabberSpec      xmpp:.*\@.+\.{domains}{urlPath}?
aolIMSpec       aim:goim\?screenname=[^\ \t\n&]+(&message=.+)?
aolChatSpec     aim:gochat\?roomname=[^\ \t\n&]+
yahooIMSpecOld  (ymsgr|yahoo):sendim\?.+
yahooIMSpecNew	(ymsgr|yahoo):(\/\/)?im\?to=.+
yahooIMSpec     {yahooIMSpecOld}|{yahooIMSpecNew}
rdarSpec        (rdar|radr|radar|x-radar):\/\/(problems?\/)?[0-9]+(&[0-9]+)*
spotifySpec     spotify:(track|album|artist|search|playlist|user|radio):[^<>]+

hex4            [0-9A-Fa-f]{1,4}
ipv6HexSeq      {hex4}?(::?{hex4}){1,7}
ipv6HexPart     ({ipv6HexSeq})|(::{ipv6HexSeq})
ipv6Address     {ipv6HexPart}({ipv4address})?
ipv6URL         \[{ipv6Address}](:[0-9]+)?{urlPath}?

%option noyywrap nounput 8bit caseless never-interactive prefix="AH"

%x CANONICAL
%%

<CANONICAL>({userAndPass}@)?{urlSpecifier}        {AHStringOffset += AHleng;
                                                   AHleng += AHValidShift;
                                                   BEGIN INITIAL;
                                                   return AH_URL_VALID;}

<CANONICAL>({userAndPass}@)?{ipURL}               {AHStringOffset += AHleng;
                                                   AHleng += AHValidShift;
                                                   BEGIN INITIAL;
                                                   return AH_URL_VALID;}

<CANONICAL>({userAndPass}@)?{singleDomain}(\.{singleDomain})*(:[0-9]+)?{urlPath} {AHStringOffset += AHleng;
                                                   AHleng += AHValidShift;
                                                   BEGIN INITIAL;
                                                   return AH_URL_VALID;}

<CANONICAL>({userAndPass}@)?{singleDomain}(:[0-9]+)?{urlPath}? {AHStringOffset += AHleng;
                                                   AHleng += AHValidShift;
                                                   BEGIN INITIAL;
                                                   return AH_URL_VALID;}

<CANONICAL>({userAndPass}@)?{ipv6URL}            {AHStringOffset += AHleng;
                                                   AHleng += AHValidShift;
                                                   BEGIN INITIAL;
                                                   return AH_URL_VALID;}

<CANONICAL>.*                                    {AHStringOffset += AHleng;
                                                  BEGIN INITIAL;
                                                  return AH_URL_INVALID;}

file:\/\/\/.*           {AHStringOffset += AHleng; return AH_FILE_VALID;}

https?:\/\/             |
s?ftp:\/\/              |
feed:\/\/               |
ssh:\/\/                |
telnet:\/\/             |
rts?p:\/\/              |
irc:\/\/                |
nntp:\/\/               |
cifs:\/\/               |
smb:\/\/                |
hydra:\/\/              |
itms:\/\/               |
see:\/\/                |
afp:\/\/                |
adiumxtra:\/\/          |
webcal:\/\/             |
svn(\+ssh)?:\/\/        |
notes:\/\/              |
gopher:\/\/             |
x-man-page:\/\/         {AHStringOffset += AHleng; AHValidShift = AHleng; BEGIN CANONICAL;}

sip:{mailSpecifier}     {AHStringOffset += AHleng; return AH_URL_VALID;}

mailto:{mailSpecifier}  {AHStringOffset += AHleng; return AH_MAILTO_VALID;}
{mailSpecifier}         {AHStringOffset += AHleng; return AH_MAILTO_DEGENERATE;}

{jabberSpec}            {AHStringOffset += AHleng; return AH_URL_VALID;}

{urlSpecifier}          {AHStringOffset += AHleng; return AH_URL_DEGENERATE;}

{aolIMSpec}             {AHStringOffset += AHleng; return AH_URL_VALID;}
{aolChatSpec}           {AHStringOffset += AHleng; return AH_URL_VALID;}
{yahooIMSpec}           {AHStringOffset += AHleng; return AH_URL_VALID;}
{rdarSpec}              {AHStringOffset += AHleng; return AH_URL_VALID;}
{spotifySpec}           {AHStringOffset += AHleng; return AH_URL_VALID;}

.                       {return AH_URL_INVALID;}
%%
