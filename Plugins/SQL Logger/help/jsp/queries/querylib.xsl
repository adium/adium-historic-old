<?xml version="1.0"?>
<!-- $Rev: 921 $ $Date: 2004-11-20 10:13:59 -0600 (Sat, 20 Nov 2004) $ -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:l="http://www.slamb.org/xmldb/library"
  xmlns:s="http://www.slamb.org/xmldb/statement"
  xmlns:xalan="http://xml.apache.org/xslt">

  <xsl:output method="html"
              indent="yes"
              xalan:indent-amount="2"
              doctype-public="-//W3C//DTD 4.01//EN"
              doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>

  <xsl:template match="l:library">
    <html>
      <head>
        <title>Query library</title>
      </head>
      <body>
        <h1>Query library</h1>

        <xsl:if test="l:version">
          <h3>Version</h3>
          <p><xsl:value-of select="l:version"/></p>
        </xsl:if>

        <xsl:if test="l:description">
          <h3>Description</h3>
          <p><xsl:value-of select="l:description"/></p>
        </xsl:if>

        <h3>Contents</h3>
        <ul>
          <xsl:apply-templates select="(s:query|s:update)" mode="contents"/>
        </ul>

        <xsl:apply-templates select="(s:query|s:update)"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="s:query|s:update" mode="contents">
    <li>
      <xsl:value-of select="name(.)"/> <xsl:text> </xsl:text>
      <a id="#st_{@name}_contents" href="#st_{@name}_full">
        <xsl:value-of select="@name"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="s:query|s:update">
    <hr noshade="noshade"/>
    <h2>
      <xsl:value-of select="name(.)"/> <xsl:text> </xsl:text>
      <a href="#st_{@name}_contents" id="st_{@name}_full">
        <xsl:value-of select="@name"/>
      </a>
    </h2>
    <xsl:if test="l:description">
      <h3>Description</h3>
      <p><xsl:copy-of select="l:description"/></p>
    </xsl:if>
    <xsl:if test="s:param">
      <h3>Parameters</h3>
      <ul>
        <xsl:for-each select="s:param">
          <li>
            <xsl:if test="@type">
              <xsl:value-of select="@type"/>
              <xsl:text> </xsl:text>
            </xsl:if>
            <b><xsl:value-of select="@name"/></b>
            <xsl:if test="@array">
              (array variable) <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="l:description">
              &#x2014; <xsl:value-of select="l:description"/>
            </xsl:if>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:if>
    <xsl:for-each select="s:sql">
      <h3>SQL syntax: <xsl:value-of select="@databases"/></h3>
      <blockquote>
        <pre>
          <xsl:apply-templates/>
        </pre>
      </blockquote>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="s:bind"> <b>&lt;<i><xsl:value-of select="@param"/></i>&gt;</b> </xsl:template>

  <xsl:template match="s:bindlist"> <b>&lt;join(<i><xsl:value-of select="s:join"/></i>, <i><xsl:value-of select="@each"/></i>, <i><xsl:value-of select="@param"/></i>&gt;</b> </xsl:template>

  <xsl:template match="s:sub"> <b>[<i><xsl:value-of select="@param"/></i>]</b> </xsl:template>
</xsl:stylesheet>
