<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    $pageID = "irc";
    $details = detailsForPage("parts/tabs.txt", $pageID);
    
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium X : Team</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<!--[if gte ie 5.5000]>
<link rel="stylesheet" type="text/css" href="styles/layoutIE.css" />
<link rel="stylesheet" type="text/css" href="styles/defaultIE.css" />
<![endif]-->
<link rel="shortcut icon" href="favicon.ico" />
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/blue.png" width="128" height="128" border="0" alt="Adium X Icon" />
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
                <h1>Channel settings</h1>

                <div class="boxThinTop"></div>
                <div class="boxThinContent">
					<p>A list of settings you can use if you already know how to use an irc client:</p>
                    <p>Server</p>
                    <p><a href="irc://irc.freenode.net/adium">irc.freenode.net</a></p>
                    <p>Channel</p>
                    <p><a href="irc://irc.freenode.net/adium">#adium</a></p>
                    <p>Join us in #adium on irc.freenode.net for live chat.</p>
                </div>
                <div class="boxThinBottom"></div>
                
                                <h1>Other forms of support</h1>

                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p><a href="http://forum.adiumx.com">Adium Forum</a></p>
                    <p>Discuss ideas, issues, or concerns with other users.</p>
                    <p><a href="http://team.adiumx.com">Adium Team</a></p>
                    <p>A list of developers and community members.</p>
                    
                </div>
                <div class="boxThinBottom"></div>
                

            </div>

            <div id="content">
                <h1>Why IRC?</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p>One way that Adium developers and users try to help support each other is through a group chat room that is on IRC (Internet Relay Chat). This allows for what is otherwise known as real time interaction. Everyone chats in a room, called a channel. You can ask any questions you want, and for the most part, they will be answered. We even talk about things not even remotely related to Adium!</p>
                    <p>All that is great, but you need to know how to get onto IRC to ask your question, right? Welp, here you go. Three simple steps that will tell you how to get onto irc:</p>
                    <div class="cleanHackLeft"> </div>
                </div>
                <div class="boxWideBottom"></div>
                <h1>Step 1: Getting an IRC client</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p>There are many irc clients out there, some simple, some not so simple. Luckily, we are going to discuss one of the simple ones here. All you need for this are:</p>
                    	<ul>
                    		<li>An apple computer</li>
                    		<li>An internet connection</li>
                    		<li>Some time.</li>
                    	</ul>
                    <p>Go to <a href="https://sourceforge.net/project/showfiles.php?group_id=74267">https://sourceforge.net/project/showfiles.php?group_id=74267</a> to download Colloquy. Here is a screen shot of that page as it is right now:</p>
                    <img class="irchowto" width="500" border="0" src="images/irchowto/irchowto1.jpg" alt="avatar" />
                    <p>You'll notice a couple of versions there, you probably want the latest version. Click on the file name which is underneath the bold title for the version you wish to download.</p>
                    <p>You will then come to a web page that looks a little like this:</p><br />
                    <img class="irchowto" width="500" border="0" src="images/irchowto/irchowto2.jpg" alt="avatar" />
                    <p>Click on the picture under the download column on the right. The trick to this page is to figure out which of these places is closest to you, which makes it a much faster download.</p>
                    <p>Once Colloquy is downloaded, if your browser has not automatically opened the file, go ahead and double click on it. It will expand the compressed file, and you will then get to copy it to where you want it.</p>
                </div>
                <div class="boxWideBottom"></div>
                <h1>Step 2: Setting up Colloquy</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
					<p>The second step to getting to talk to a Adium user or developer live, in real time, for support or to just chit chat, is to launch Colloquy, and then configure it to connect to the correct place. Go ahead and launch Colloquy from where you copied it to. Once you have done that, it should look something like this:</p>
                     <img class="irchowto" width="470" border="0" src="images/irchowto/irchowto3.jpg" alt="avatar" />
                	<p>Click the details triangle, and then fill in the fields for this panel to look something like this:</p>
                     <img class="irchowto" width="470" border="0" src="images/irchowto/irchowto4.jpg" alt="avatar" />
                	<p>Ensure that the Chat Server is setup to irc.freenode.net, and that you have added #Adium to the Join Rooms</p>
                	<p>Once you are done filling everything out, click the connect button.</p>
                    <div class="cleanHackLeft"> </div>
                </div>
                <div class="boxWideBottom"></div>
                <h1>Step 3: There is no step 3</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p>You should be connected within moments, and it should look like this:</p>
                     <img class="irchowto" width="470" border="0" src="images/irchowto/irchowto5.jpg" alt="avatar" />
                    <div class="cleanHackLeft"> </div>
                </div>
                <div class="boxWideBottom"></div>
            </div>
            <div id="bottom">
                <div id="powered">
                	<a href="http://gaim.sourceforge.net"><img width="88" height="31" src="http://gaim.sourceforge.net/images/powered_by_libgaim.png" border="0" alt="Adium is powered by libgaim "/></a> <a href="http://www.blogger.com"><img width="88" height="31" src="http://buttons.blogger.com/bloggerbutton1.gif" border="0" alt="This page is powered by Blogger. Isn't yours?" /></a> <a href="http://sourceforge.net"><img src="http://sourceforge.net/sflogo.php?group_id=67507&amp;type=2" width="125" height="37" border="0" alt="SourceForge.net Logo"/></a>
                </div>
                <div id="notice">
                    Adium is not endorsed by or affiliated with <a class="hidden" href="http://www.aol.com">America Online, Inc.</a> The marks AOL and AIM are registered trademarks of America Online, Inc.
                </div>
                <div class="cleanHackBoth"> </div>
            </div>
        </div>
        <div id="footer">&nbsp;</div>
    </div>
<script type="text/javascript" src="PieNG.js"></script>
</body>
</html>
