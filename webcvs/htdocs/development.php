<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    $pageID = "dev";
    $details = detailsForPage("parts/tabs.txt", $pageID);
    
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium X : Development</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="shortcut icon" href="favicon.ico" />
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/red.png" width="128" height="128" border="0" alt="Adium X Icon" />
                <div class="text">
                    <h1>Adium X</h1>
                    <h2><?php echo RandomSlogan(); ?></h2>
                </div>
            </div>
            <div id="buttoncontainer">
                <ul id="buttonlist">
                    <li><a class="download" href="<?php echo DownloadAddress(); ?>"><?php echo DownloadTitle(); ?></a></li>
                    <li class="lastItem"><a class="xtras" href="http://ambitiouslemon.com/adiumxtras/">Xtras!</a></li>
	           </ul>
	       </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <?php echo DynamicTabs("parts/tabs.txt", $pageID); ?>
                </ul>
            </div>
            <div id="sidebar-a">
                <h1>Want To Help?</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p>Contact one of the <a href="team.php">lead developers</a> for information on contributing.</p>
                </div>
                <div class="boxThinBottom"></div>
                <h1>Development Statistics</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p>Source changes are displayed as they occur in <a href="irc://irc.freenode.net/#adium">#adium</a> on irc.freenode.net</p>
                    <p>Also available:<br />
                    <a href="http://cia.navi.cx/stats/project/adium/">Commit Statistics</a><br />
                    <a href="http://cia.navi.cx/stats/project/adium/.rss">Commit RSS feed</a><br />
                    <a href="http://lists.sourceforge.net/lists/listinfo/adium-cvs">Commit mailing list</a></p>
                    <p>The commit mailing list is very high traffic, so be sure your mailbox can handle it.</p>
                </div>
                <div class="boxThinBottom"></div>
                <h1>Project Hosting</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p>Adium development is hosted by <a href="http://sourceforge.net">SourceForge.net</a>.</p>
                    <p><a href="http://sourceforge.net/projects/adium/">Adium project page</a></p>
                </div>
                <div class="boxThinBottom"></div>
           </div>
            <div id="content">
                <h1>Adium X v<?php echo DownloadVersion(); ?> Source</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                <p>Download the source code corresponding to Adium X release v<?php echo DownloadVersion(); ?>:<br />
                <a href="<?php echo DownloadSourceAddress(); ?>"><?php echo DownloadSourceAddress(); ?></a></p>
                </div>
                <div class="boxWideBottom"></div>           
                <h1>Newest Adium X Source Code</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p>Adium is an open source project, distributed under the GPL license. The most recent Adium source code is available from the sourceforge CVS server. Use the following instructions to check yourself out a copy:
</p>
                    <p>Requirements</p>
                    <ul>
                        <li><a href="http://www.apple.com/xcode">XCode</a> (Available with a free account from Apple)</li>
                        <li><a href="http://www.apple.com/macosx">Mac OS X 10.3</a></li>
                    </ul>
                    <p>Instructions</p>
                    <ul class="steps">
                        <li>Paste into terminal:<br /><span class="code">cvs -d:pserver:anonymous@cvs.adiumx.com:/cvsroot/adium login</span></li>
                        <li>When asked for a password, just press return. No password is required.</li>
                        <li>Paste into terminal:<br /><span class="code">cvs -z3 -d:pserver:anonymous@cvs.adiumx.com:/cvsroot/adium co adium</span></li>
                    </ul>
                    <p>You can update the source (as frequently as desired), by moving into the adium folder with <span class="code">cd adium</span> and running <span class="code">cvs -z3 update -Pd</span></p>
                </div>
                <div class="boxWideBottom"></div>
               <h1>Libgaim Source Code</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p>LibGaim is developed by the <a href="http://gaim.sf.net">Gaim team</a>.  For convience, we keep the source code for the version of LibGaim we are using (along with the source of it's dependencies) in our sourceforge CVS.  LibGaim is also distrubuted under the GPL, check with the <a href="http://gaim.sf.net">Gaim team</a> for more information.</p>
                    <p>Requirements</p>
                    <ul>
                        <li><a href="http://www.apple.com/xcode">XCode</a> (Available with a free account from Apple)</li>
                        <li>10.2.7 SDK (Custom install option of XCode)</li>
                        <li><a href="http://www.apple.com/macosx">Mac OS X 10.3</a></li>
                    </ul>
                    <p>Instructions</p>
                    <ul class="steps">
                        <li>Paste into terminal:<br /><span class="code">cvs -d:pserver:anonymous@cvs.adiumx.com:/cvsroot/adium login</span></li>
                        <li>When asked for a password, just press return. No password is required.</li>
                        <li>Paste into terminal:<br /><span class="code">cvs -z3 -d:pserver:anonymous@cvs.adiumx.com:/cvsroot/adium co libgaim</span></li>
                    </ul>
                    <p>You can update the source (as frequently as desired), by moving into the libgaim folder with <span class="code">cd libgaim</span> and running <span class="code">cvs -z3 update -Pd</span></p>
                </div>
                <div class="boxWideBottom"></div>
          </div>
            <div id="bottom">
                <div id="powered">
                	<a href="http://gaim.sourceforge.net"><img width="88" height="31" src="http://gaim.sourceforge.net/images/powered_by_libgaim.png" border=0 alt="Adium is powered by libgaim "/></a> <a href="http://www.blogger.com"><img width="88" height="31" src="http://buttons.blogger.com/bloggerbutton1.gif" border="0" alt="This page is powered by Blogger. Isn't yours?" /></a> <a href="http://sourceforge.net"><img src="http://sourceforge.net/sflogo.php?group_id=67507&amp;type=2" width="125" height="37" border="0" alt="SourceForge.net Logo"/></a>
                </div>
                <div id="notice">
                    Adium is not endorsed by or affiliated with <a class="hidden" href="http://www.aol.com">America Online, Inc.</a> The marks AOL and AIM are registered trademarks of America Online, Inc.
                </div>
                <div class="cleanHackBoth"> </div>
            </div>
        </div>
        <div id="footer">&nbsp;</div>
    </div>
</body>
</html>