<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xalan="http://xml.apache.org/xslt">

  <xsl:output method="html"
              encoding="ascii"
              indent="yes"
              xalan:indent-amount="2"
              doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
              doctype-system="http://www.w3.org/TR/html4/transitional.dtd"/>
  <xsl:template match="page">
    <html>
      <head>
        <title><xsl:value-of select="title" /></title>
        <link rel="stylesheet" type="text/css" href="stylesheet.css" />
      </head>
      <body>
        <table border="0" cellspacing="0" cellpadding="5">
          <tr>
            <td colspan="2" bgcolor="#000000" align="right">
              <h2 class="titlebar">
                <xsl:value-of select="title" />
              </h2>
              </td>
          </tr>
          <tr>
            <td width="170" height="20" background="images/transp-change.png"
            bgcolor="green"></td>
            <td height="20" background="images/transp-change.png"></td>
          </tr>
          <tr>
            <td width="170" bgcolor="green" valign="top" align="right">
              <h4>Adium SQL Links<br /></h4>
              <a href="index.html" class="sidebar">Installation Instructions</a>
              <br /><a href="http://www.visualdistortion.org/adium/screenshots.jsp" class="offsides">Screenshots</a>
              <br /><a href="tsearch.html" class="sidebar">TSearch Installation</a>
              <br /><a href="resin.html" class="sidebar">Resin Installation</a>
              <br /><a href="technical.html" class="sidebar">Technical
              Details</a>
              <br /><a href="performance.html"
              class="sidebar">Performance/Maintenance</a>

              <br /><br /><h4>Other links</h4>
              <a href="http://www.adiumx.com/" class="offsides">Adium</a>
              <br /><a href="http://adium.sourceforge.net" class="offsides">Adium
                2.0</a>
              <br /><a href="http://www.funmac.com/forumdisplay.php?forumid=38" 
                class="offsides">Adium
                Forums</a>
              <br /><a href="http://www.postgresql.org" class="offsides">PostgreSQL</a>
              <br /><a
                href="http://www.postgresql.org/docs/7.3/interactive/index.html"
                class="offsides">PSQL Documentation</a>
              <br /><a
              href="http://www.xceltech.net/products/freeware_products.html"
              class="offsides">PostMan Query</a>
              <br />
              <br />
              <h4>Visual Distortion Links</h4>
              <a href="http://www.visualdistortion.org/"
              class="offsides">Visual Distortion Home</a>
              <br />
              <a href="http://www.visualdistortion.org/guestbook.jsp"
              class="offsides">Guestbook</a>
              <br /><a
              href="http://www.visualdistortion.org/pictures/"
              class="offsides">Pictures</a>
              <br /><a href="http://www.visualdistortion.org/films/"
              class="offsides">Films</a>
              <br /><a href="http://www.visualdistortion.org/music/"
              class="offsides">Music</a>
            </td>
            <td>
              <xsl:apply-templates select="body"/>
              <hr />
                <div align="right">
                  <a href="mailto:jmelloy@visualdistortion.org">jmelloy@visualdistortion.org</a>
                </div>
            </td>
          </tr>
        </table>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="body">
    <xsl:copy-of select="*"/>
  </xsl:template>
</xsl:stylesheet>
