<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    $pageID = "faq";
    $details = detailsForPage("parts/tabs.txt", $pageID);
    
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium X : FAQ</title>
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
                <img class="adiumIcon" src="images/adiumy/yellow.png" width="128" height="128" border="0" alt="Adium X Icon" />
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
                <h1>Can't find an answer?</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p>Search the <a href="http://forum.adiumx.com">Adium forum</a></p>
                        <form action="http://www.funmac.com/search.php" method="post">
                            <input type="hidden" name="s" value="" />
                            <input type="hidden" name="searchdate" value="-1" />
                            <input type="hidden" name="forumchoice" value="38" />
                            <input type="hidden" name="action" value="simplesearch" />
                            <input type="text" class="forumsearchinput" name="query" />
                            <input type="submit" class="forumsearchbutton" value="Go" />
                        </form>
                        <p><span class="tiny"><a href="iseek://url/?=&amp;name=Adium%20Forums&amp;category=Foros&amp;encoding=5&amp;scheme=http&amp;url=www.funmac.com/search.php?s=%26searchdate=-1%26beforeafter=after%26forumchoice=38%26action=simplesearch%26query=">iSeek URL</a> (click to add it)</span></p>
                    
                    <p>Try asking in our <a href="irc://irc.freenode.net/#adium">irc channel</a>:<br />
                    <span class="tiny">Server: irc.freenode.net</span><br />
                    <span class="tiny">Channel: #adium</span></p>
                    <p>Get support via email: <a href="mailto:support@adiumx.com">support@adiumx.com</a></p>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">

                <h1>Upgrading From Adium 1.x</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                <p><span class="faqQuestion">How do I import my contacts, aliases, and logs from Adium 1.x?</span><br />
                Download and run the <a href="downloads/adium_1x_importer.tar.gz">Adium 1.x importer</a>.</p>
                </div>
                <div class="boxWideBottom"></div>

                <h1>General</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <p><span class="faqQuestion">What is Adium X?</span><br />
                    Adium X is an instant messaging client for Mac OS X.  Adium supports multiple protocols, allowing you to communicate on many services from within a single application.</p>
                    
                    <p><span class="faqQuestion">What are the requirements to use Adium?</span><br />
                    Adium requires Mac OS X 10.2 or higher ("Jaguar" or better) to run. Certain features (Log content searching, tab dragging animations) require Mac OS X 10.3 ("Panther").</p>
                    
                    <p><span class="faqQuestion">What services does Adium X support?</span><br />
                    Adium supports AIM, MSN, Yahoo, Jabber, Gadu-Gadu, Trepia, and Napster.</p>
                    
                    <p><span class="faqQuestion">Is Adium affiliated or endorsed by any of these companies?</span><br />
                    No, Absolutely not.  Adium is an independent, third-party instant messaging client. It is not associated with and is not supported by AOL, MSN, Yahoo, or any other such company</p>
                    
                    <p><span class="faqQuestion">What does Adium X cost?</span><br />
                    Adium is free, and is distributed under the <a href="http://www.fsf.org/copyleft/gpl.html">GNU General Public License</a>.</p>
                    
                    <p><span class="faqQuestion">How is Adium pronounced?</span><br />
                    Officially, Adium is pronounced like stadium, though there are adherents to Add-ee-um.  The project leads actually pronounce it differently, you're welcome to choose.</p>
                    
                    <p><span class="faqQuestion">What's with the ducks?</span><br />
                    The intention was for Adium's icon to be a messenger bird (as used in the past to deliver messages over long distances).  However, Adam Iser's graphical "skills" resulted in a strange, multicolored duck creature.  The duck caught on, and inspired <a href="http://www.artofadambetts.com/">Adam Betts</a> to re-create the duck as a professional quality icon set, which was adopted as the official mascot of Adium X.</p>

                    <p><span class="faqQuestion">What is LibGaim?</span><br />
                    LibGaim is the core of the linux/windows IM client <a href="http://gaim.sf.net">Gaim</a>.  Adium uses LibGaim to access all of the instant messaging services.</p>

                </div>
                <div class="boxWideBottom"></div>


                <h1>Usage</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    
                    <p><span class="faqQuestion">Can I change my away message when I already have an away message up?</span><br />
                    Hold down the option key, then click on the File menu. The "Remove Away Message" menu item will have changed to a "Set Away Message" submenu, from which you can change your away message.  Alternatively, press command-option-y to bring up the "Set Away Message" window.</p>
                    
                    <p><span class="faqQuestion">Can I set a fake idle time?</span><br />
                    Choose "Set Idle" from the File menu.  "Set Idle" pretends that you stopped using the computer the instant you select it.  You can continue using the computer as usual, but after the number of minutes set in the Idle Preferences, you will appear as idle to other users.  You will stay idle until you choose "Remove Idle" from the file menu.</p>
                    <p>Alternatively, hold down the option key while choosing "Set Custom Idle" from the File menu.  "Set Custom Idle" allows you to specify any idle time you want, and have that idle time apply immediately.</p>
                    
                    <p><span class="faqQuestion">How do I Move/Add/Delete contacts?</span><br />
                    You add, remove, and delete contacts right on the contact list.</p>
                    <p>To move a contact: Just click and drag that person's name from its old place to its new place on your contact list.</p>
                    <p>To delete a contact: Click on your contact's name and press Command-Delete. Or, choose "Delete Selection" from the Contact menu.</p>
                    <p>To add a contact: Choose "Add contact" from the Contact menu.</p>
                    
                    <p><span class="faqQuestion">Can I make each message appear in a separate window?</span><br />
                    Yes.  In Adium's Preferences (on the "Messages" pane) uncheck the option "Create new messages in tabs".</p>

                    <p><span class="faqQuestion">How do I set my buddy icon?</span><br />
                    There is currently no way to set your buddy icon inside Adium. Adium uses the picture in your Address Book 'me' card as your buddy icon</p>
                    
                </div>
                <div class="boxWideBottom"></div>
                
                
                <h1>Feedback</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                
                <p><span class="faqQuestion">Where should I report bugs?</span><br />
                Report bugs to <a href="mailto:bugs@adiumx.com">bugs@adiumx.com</a>.</p>

                <p><span class="faqQuestion">Where should I send feedback and requests?</span><br />
                Send feedback and requests to <a href="mailto:feedback@adiumx.com">feedback@adiumx.com</a>.</p>
              
                <p><span class="faqQuestion">Should I send crash reports, are they helpful?</span><br />
                Yes!  <i>Please</i> send us your crash reports, they are extremely useful.  The crash reporter will remember your email address, and the descriptions are completely optional, so sending a crash report is just as much work as ignoring one, and they really do help.</p>

                </div>
                <div class="boxWideBottom"></div>

                <h1>Development</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                
                    <p><span class="faqQuestion">What is CVS?</span><br />
                    CVS stands for Concurrent Versions System. It allows many developers to collaborate without stepping on each other's toes. It also allows users to be using the most up-to-date version, if they're so inclined.</p>
                
                    <p><span class="faqQuestion">Why does CVS say "Connection reset by peer" ?</span><br />
                    The "Connection reset by peer" message is like getting a busy signal on the phone.  Try again in a few minutes.</p>
                    
                    <p><span class="faqQuestion">Can I submit code changes to Adium?</span><br />
                    Definitely.  Create a patch file for your changes and email them (along with a description) to one of the developers.  Alternatively, speak to a developer in #adium on irc.freenode.net about your patch.  We are more likely to accept your patch if it's clean, documented, precise, and bug free.</p>
                    
                    <p><span class="faqQuestion">How do I get developer access to the Adium CVS?</span><br />
                    The best way to get developer access is to send us several good patches.  It is also helpful to keep in contact with us via IM or in #adium on irc.freenode.net.</p>
                    
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