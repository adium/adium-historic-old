<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    $pageID = "team";
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
                <h1>Special Thanks</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p><a href="http://gaim.sf.net">The Gaim Team</a><br />
                    <span class="tiny">LibGaim</span></p>
                    <p><a href="http://www.sf.net">SourceForge.net</a><br />
                    <span class="tiny">Project Hosting</span></p>
                    <p><a href="http://www.ambitiouslemon.com">AmbitiousLemon.com</a><br />
                    <span class="tiny">FunMac Adium Forums Hosting</span></p>
                    <p><a href="http://www.penguinmilitia.net">Penguinmilitia.net</a><br />
                    <span class="tiny">Email Hosting</span></p>
                </div>
                <div class="boxThinBottom"></div>
                
                <h1>Contributors</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p><a href="mailto:psiona@mac.com">Laura Natcher</a><br />
                    <span class="tiny">Duck Icon Variants, Artwork</span></p>
                    <p><a href="mailto:cforsythe@gmail.com">Christopher Forsythe</a><br />
                    <span class="tiny">Community, Moderator</span></p>
                    <p><a href="mailto:ik@jasperhauser.nl">Jasper Hauser</a><br />
                    <span class="tiny">Interface Icons</span></p>
                    <p><a href="mailto:maran@mac.com">Benjamin Costello</a><br />
                    <span class="tiny">Site design, Xtras site</span></p>
                    <p><a href="mailto:4N01@simplstick.com">Steve Holt</a><br />
                    <span class="tiny">Code Contributions</span></p>
                    <p>Mac-arena the Bored Zo<br />
                    <span class="tiny">Code Contributions</span></p>
                    <p>Asher Haig<br />
                    <span class="tiny">Build Scripts</span></p>
                </div>
                <div class="boxThinBottom"></div>
                <h1>Previous Contributors</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p>Adam Betts<br />
                    <span class="tiny">Adiumy Iconset</span></p>
                    <p>Jeremy Knickerbocker<br />
                    <span class="tiny">Build Hosting</span></p>
                    <p>Phillip Ryu<br />
                    <span class="tiny">Feedback &amp; Testing</span></p>
                    <p>Greg Smith<br />
                    <span class="tiny">Code Contributions</span></p>
                    <p>Vinay Venkatesh<br />
                    <span class="tiny">Code Contributions</span></p>
                    <p>New York Internet<br />
                    <span class="tiny">1.x Site Hosting</span></p>
                </div>
                <div class="boxThinBottom"></div>
           </div>
            <div id="content">
                <h1>Lead Developers</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <div class="teamMember">
                        <h2>Adam Iser</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Adam Iser.png" alt="avatar" />
                        <span class="teamData">Email:</span><a href="mailto:adamiser@adiumx.com">adamiser@adiumx.com</a><br />
                        <span class="teamData">AIM:</span>resImadA<br />
                        <span class="teamData">MSN:</span>adamiser@mac.com
                    </div>
                    <div class="teamMember">
                        <h2>Evan Schoenberg</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Evan Schoenberg.png" alt="avatar" />
                        <span class="teamData">Email:</span><a href="mailto:evan@adiumx.com">evan@adiumx.com</a><br />
                        <span class="teamData">AIM:</span>TekJew<br />
                        <span class="teamData">MSN:</span>evan.s@dreskin.net<br />
                        <span class="teamData">Yahoo:</span>evands
                    </div>
                    <div class="cleanHackLeft"> </div>
                </div>
                <div class="boxWideBottom"></div>
                <h1>Developers</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <div class="teamMember">
                        <h2>Jeffrey Melloy <span class="teamDescription">(SQL Logger)</span></h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Jeffrey Melloy.png" alt="avatar" />
                        <span class="teamData">Website:</span><a href="http://www.visualdistortion.org/adium/">http://www.visualdistortion.org/adium/</a><br />
                        <span class="teamData">Email:</span><a href="mailto:jmelloy@visualdistortion.org">jmelloy@visualdistortion.org</a><br />
                        <span class="teamData">AIM:</span>fetchgreebledonx<br />
                        <span class="teamData">MSN:</span>visualdistortion_x@hotmail.com
                    </div>
                    <div class="teamMember">
                        <h2>Colin Barrett</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Colin Barrett.png" alt="avatar" />
                        <span class="teamData">Website:</span><a href="http://www.fourx.org/">http://www.fourx.org/</a><br />
                        <span class="teamData">Email:</span><a href="mailto:timber@lava.net">timber@lava.net</a><br />
                        <span class="teamData">AIM:</span>mactigerz<br />
                        <span class="teamData">Yahoo:</span>ramoth4_com
                    </div>
                    <div class="teamMember">
                        <h2>Jorge Salvador Caffarena <span class="teamDescription">(Developer, Site Coding)</span></h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Jorge Salvador Caffarena.png" alt="avatar" />
                        <span class="teamData">Website:</span><a href="http://eevyl.kualosw.com/">http://eevyl.kualosw.com/</a><br />
                        <span class="teamData">Email:</span><a href="mailto:eevyl@mac.com">eevyl@mac.com</a><br />
                        <span class="teamData">AIM:</span>eevyl@mac.com<br />
                        <span class="teamData">MSN:</span>jorg4es@yahoo.es
                    </div>
                    <div class="teamMember">
                        <h2>Nelson Elhage <span class="teamDescription">(Games)</span></h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Nelson Elhage.png" alt="avatar" />
                        <span class="teamData">Email:</span><a href="mailto:hanji@users.sourceforge.net">hanji@users.sourceforge.net</a><br />
                        <span class="teamData">AIM:</span>HanjiTheArcher<br />
                        <span class="teamData">Jabber:</span>Hanji@jabber.org
                    </div>
                    <div class="teamMember">
                        <h2>David Clark</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_David Clark.png" alt="avatar" />
                        <span class="teamData">Email:</span><a href="mailto:dchoby98@users.sourceforge.net">dchoby98@users.sourceforge.net</a><br />
                        <span class="teamData">AIM:</span>wlc98clark<br />
                        <span class="teamData">MSN:</span>dchoby98@hotmail.com
                    </div>
                     <div class="teamMember">
                        <h2>Brian Ganninger</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Brian Ganninger.png" alt="avatar" />
                        <span class="teamData">Website:</span><a href="http://www.infinitenexus.com/">http://www.infinitenexus.com/</a><br />
                        <span class="teamData">Email:</span><a href="mailto:disposable@infinitenexus.com">disposable@infinitenexus.com</a><br />
                        <span class="teamData">AIM:</span>bgann7899
                    </div>
                    <div class="teamMember">
                        <h2>Chris Serino</h2>
                        <img class="teamAvatar" width="64" height="64" border="0" src="images/avatars/avatar_Chris Serino.png" alt="avatar" />
                        <span class="teamData">Email:</span><a href="mailto:overmind911@users.sourceforge.net">overmind911@users.sourceforge.net</a><br />
                        <span class="teamData">AIM:</span>themindoverall<br />
                        <span class="teamData">MSN:</span>Overmind911@phreaker.net
                    </div>
                    <div class="cleanHackLeft"> </div>
                </div>
                <div class="boxWideBottom"></div>
                <h1>Retired Developers</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <div class="teamMember">
                        <h2>Adam Atlas</h2>
                    </div>
                    <div class="teamMember">
                        <h2>Arno Hautala</h2>
                    </div>
                    <div class="teamMember">
                        <h2>Ian Krieg</h2>
                    </div>
                    <div class="teamMember">
                        <h2>Scott Lamb</h2>
                    </div>
                    <div class="teamMember">
                        <h2>Erik J. Barzeski</h2>
                    </div>
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