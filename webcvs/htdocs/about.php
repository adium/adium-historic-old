<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    require("scripts/actionshot.php");
    $pageID = "about";
    $details = detailsForPage("parts/tabs.txt", $pageID);
    
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium X : About</title>
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
                <img class="adiumIcon" src="images/adiumy/purple.png" width="128" height="128" border="0" alt="Adium X Icon" />
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
                <h1>User Action Shots</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                <p>We need some cool screenshots of Adium in action.  See this <a href="http://www.funmac.com/showthread.php?s=&amp;threadid=6218">forum thread</a> for more information.</p>
                <p>Meanwhile, here are some samples from users like you (thanks!):</p>
                <?php echo RandomActionShoot(); ?><br /><br />
                <?php echo RandomActionShoot(); ?><br /><br />
                <?php echo RandomActionShoot(); ?><br /><br />
                <?php echo RandomActionShoot(); ?>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">
                <h1>Adium X</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
    
    <p>The Adium Team is proud to present to you AdiumX <?php echo DownloadVersion(); ?>, a multiple protocol instant messaging client. This is a culmination of a year long rewrite of adium, which now utilizes libgaim (the core part of <a href="http://gaim.sourceforge.net">gaim</a>) to connect to multiple protocols, and is also based on a new plugin architecture. Partial address book integration, cool looking tabs, multiple protocols for instant messaging, and a compact contact list are some of the many features of the new Adium X. Give it a try; we're sure you will like it.</p>
    
    <p>Adium X is under active development.  We have a lot planned, and we appreciate your support :)</p>
    
                    <p><img src="images/adium/overview.jpg" alt="overview" /></p>
                    <p><img src="images/adium/myshot.jpg" alt="myshot" /></p>
                                     
                </div>
                <div class="boxWideBottom"></div>
          </div>
            <div id="bottom">
                <div id="powered">
                    <a href="http://www.blogger.com"><img width="88" height="31" src="http://buttons.blogger.com/bloggerbutton1.gif" border="0" alt="This page is powered by Blogger. Isn't yours?" /></a> <a href="http://sourceforge.net"><img src="http://sourceforge.net/sflogo.php?group_id=67507&amp;type=2" width="125" height="37" border="0" alt="SourceForge.net Logo"/></a>
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