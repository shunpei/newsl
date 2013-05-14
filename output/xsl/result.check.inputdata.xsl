<?xml version="1.0" encoding="Shift_JIS"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" encoding="UTF-8"/>

<xsl:template match="/">
  <xsl:apply-templates select="all"/>
</xsl:template>

<xsl:template match="all">
  <html xml:lang="ja" lang="ja">
  <head>
  <title>dataCheck</title>
  <style type="text/css">table {font-family:monospace;}</style>
  <script type="text/javascript" src="../js/slcalc.js"></script>

  </head>
  <body>
<!-- START JS AREA-->
  <div id="topmenu"/>
<!-- END JS AREA-->
  <hr/>
<!-- START TOP MENU SHORTCUT-->
  jumpto:
  <xsl:for-each select="category">
  <xsl:sort select="@value" order="ascending" />
    <xsl:element name="a">
    <xsl:attribute name="href">
       #<xsl:value-of select="@value"/>
    </xsl:attribute>
    <xsl:value-of select="@value"/>
    </xsl:element><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
  </xsl:for-each>
<!-- END TOP MENU SHORTCUT-->
  <hr/>
<!-- Category TITLE -->
  <xsl:for-each select="category">
  <xsl:sort select="@value" order="ascending" />
  <xsl:element name="div">
    <xsl:attribute name="class">category</xsl:attribute>
    <xsl:attribute name="value"><xsl:value-of select="@value"/></xsl:attribute>
    <xsl:attribute name="style">display:block;</xsl:attribute>
    <xsl:element name="a">
      <xsl:attribute name="name"><xsl:value-of select="@value"/></xsl:attribute>
      <h3><xsl:value-of select="@value"/></h3>
    </xsl:element>
  </xsl:element>
<!-- END Category TITLE -->
    <table border="1">
    <tr>
      <th>run</th>
      <th>startno</th>
      <th>zn</th>
      <th>start</th>
      <th>goal</th>
      <th>pengate</th>
      <th>st</th>
      <th>name</th>
      <th>time</th>
      <th>pen</th>
      <th>pts</th>
    </tr>
    <xsl:for-each select="zn/race">
    <xsl:sort select="@value" data-type="text" order="ascending" />
    <xsl:sort select="@startno" data-type="number" order="ascending" />
      <tr>
        <!-- base data -->
        <td align="center"><xsl:value-of select="@value"/></td>
        <td align="center"><xsl:value-of select="@startno"/></td>
        <td align="center"><xsl:value-of select="../@value"/></td>

        <!-- check data -->
        <td align="center"><xsl:value-of select="@start"/></td>
        <td align="center"><xsl:value-of select="@goal"/></td>
        <td align="left"><xsl:value-of select="@pengate"/></td>
        <td align="left"><xsl:value-of select="@status"/></td>

        <!-- verify data -->
        <td align="left"><xsl:value-of select="../@name"/></td>
        <td align="right"><xsl:value-of select="@time"/></td>
        <td align="right"><xsl:value-of select="@pen"/></td>
        <td align="right"><xsl:value-of select="@pts"/></td>
      </tr>
    </xsl:for-each>
    </table>
    <hr/>
  </xsl:for-each>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>
