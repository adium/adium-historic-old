<?php
    require("scripts/binaries.php");
    require("scripts/tabs.php");
    require("scripts/slogan.php");
    $pageID = "home";
    $details = detailsForPage("parts/tabs.txt", $pageID);
    
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium X : Home</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<script language="javascript" type="text/javascript">
 function OpenLink(c){
   window.open(c, 'link', 'width=480,height=480,scrollbars=yes,status=yes,toolbar=no');
 }
</script>
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/green.png" width="128" height="128" border="0" alt="Adium X Icon" />
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
                <h1>Highlights</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p><a href="history.html" onclick="OpenLink(this.href); return false">Version history</a></p>
                    <div class="donate"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;submit.x=57&amp;submit.y=8&amp;encrypted=-----BEGIN+PKCS7-----%0D%0AMIIHFgYJKoZIhvcNAQcEoIIHBzCCBwMCAQExggEwMIIBLAIBADCBlDCBjjELMAkG%0D%0AA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQw%0D%0AEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UE%0D%0AAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJ%0D%0AKoZIhvcNAQEBBQAEgYAFR5tF%2BRKUV3BS49vJraDG%2BIoWDoZMieUT%2FJJ1Fzjsr511%0D%0Au7hS1F2piJuHuqmm%2F0r8Kf8oaycOo74K3zLmUQ6T6hUS6%2Bh6lZAoIlhI3A1YmqIP%0D%0AdrdY%2FtfKRbWfolDumJ9Mdv%2FzJxPnpdQiTN5K1PMrPYE6GgPWE9WC4V9lqstSmTEL%0D%0AMAkGBSsOAwIaBQAwgZMGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQIjtd%2BN9o4ZB6A%0D%0AcIbH8ZjOLmE35xBQ%2F93chtzIcRXHhIQJVpBRCkyJkdTD3libP3F7TgkrLij1DBxg%0D%0AfFlE0V%2FGTk29Ys%2FwsPO7hNs3YSNuSz0HT5F6sa8aXwFtMCE%2FgB1Ha4qdtYY%2BNETJ%0D%0AEETwNMLefjhaBfI%2BnRxl2K2gggOHMIIDgzCCAuygAwIBAgIBADANBgkqhkiG9w0B%0D%0AAQUFADCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3Vu%0D%0AdGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9j%0D%0AZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBh%0D%0AbC5jb20wHhcNMDQwMjEzMTAxMzE1WhcNMzUwMjEzMTAxMzE1WjCBjjELMAkGA1UE%0D%0ABhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYD%0D%0AVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQI%0D%0AbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wgZ8wDQYJKoZI%0D%0AhvcNAQEBBQADgY0AMIGJAoGBAMFHTt38RMxLXJyO2SmS%2BNdl72T7oKJ4u4uw%2B6aw%0D%0AntALWh03PewmIJuzbALScsTS4sZoS1fKciBGoh11gIfHzylvkdNe%2FhJl66%2FRGqrj%0D%0A5rFb08sAABNTzDTiqqNpJeBsYs%2Fc2aiGozptX2RlnBktH%2BSUNpAajW724Nv2Wvhi%0D%0Af6sFAgMBAAGjge4wgeswHQYDVR0OBBYEFJaffLvGbxe9WT9S1wob7BDWZJRrMIG7%0D%0ABgNVHSMEgbMwgbCAFJaffLvGbxe9WT9S1wob7BDWZJRroYGUpIGRMIGOMQswCQYD%0D%0AVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDAS%0D%0ABgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQD%0D%0AFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbYIBADAMBgNV%0D%0AHRMEBTADAQH%2FMA0GCSqGSIb3DQEBBQUAA4GBAIFfOlaagFrl71%2Bjq6OKidbWFSE%2B%0D%0AQ4FqROvdgIONth%2B8kSK%2F%2FY%2F4ihuE4Ymvzn5ceE3S%2FiBSQQMjyvb%2Bs2TWbQYDwcp1%0D%0A29OPIbD9epdr4tJOUNiSojw7BHwYRiPh58S1xGlFgHFXwrEBb3dgNbMUa%2Bu4qect%0D%0AsMAXpVHnD9wIyfmHMYIBmjCCAZYCAQEwgZQwgY4xCzAJBgNVBAYTAlVTMQswCQYD%0D%0AVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFs%0D%0AIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRww%0D%0AGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMAkGBSsOAwIaBQCgXTAYBgkq%0D%0AhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wNDAzMjUwNDQ0%0D%0AMzRaMCMGCSqGSIb3DQEJBDEWBBRzTAS6zk5cmMeC49IorY8CM%2BkX0TANBgkqhkiG%0D%0A9w0BAQEFAASBgBsyRfMv9mSyoYq00wIB7BmUHFGq5x%2Ffnr8M24XbKjhkyeULk2NC%0D%0As4jbCgaWNg6grvccJtjbvmDskMKt%2BdS%2BEAkeWwm1Zf%2F%2B5u1fMyb5vo1NNcRIs5oq%0D%0A7SvXiLTPRzVqzQdhVs7PoZG0i0RRIb0tMeo1IssZeB2GE5Nsg0D8PwpB%0D%0A-----END+PKCS7-----">Donate using PayPal</a></div>
                </div>
                <div class="boxThinBottom"></div>
                <h1>Community</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <p><a href="http://www.funmac.com/forumdisplay.php?s=&amp;forumid=38">Adium Forum</a></p>
                    <p>Discuss ideas, issues, or concerns with other users.</p>
                    <p><a href="irc://irc.freenode.net/#adium">Adium IRC Channel</a></p>
                    <p>Join us in #adium on irc.freenode.net for live chat.</p>
                </div>
                <div class="boxThinBottom"></div>
                <h1>News Archives</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <?php include('/home/groups/a/ad/adium/blogs/archives/archive.php'); ?>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">
                <h1>News</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <?php include('scripts/blogfilter.php'); ?>
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