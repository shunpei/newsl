<?xml version="1.0" encoding="Shift_JIS"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" encoding="UTF-8"/>

<xsl:template match="/">
  <xsl:apply-templates select="all"/>
</xsl:template>

<xsl:template match="all">
  <html xml:lang="ja" lang="ja">
  <head>
  <title>usecCheck</title>
  <style type="text/css">table {font-family:monospace;}</style>
  </head>
  <body>
  <xsl:for-each select="category">
  <xsl:sort select="@value" order="ascending" />
    <h3><xsl:value-of select="@value"/></h3>
    <table border="1">
    <tr>
      <th>run</th>
      <th>startno</th>
      <th>zn</th>
      <th>name</th>
      <th>result</th>
      <th>pts</th>
      <th>time</th>
      <th>pen</th>
      <th>pengate</th>
    </tr>
    <xsl:for-each select="zn/race">
    <xsl:sort select="@value" data-type="text" order="ascending" />
    <xsl:sort select="@startno" data-type="number" order="ascending" />
      <tr>
        <td align="center"><xsl:value-of select="@value"/></td>
        <td align="center"><xsl:value-of select="@startno"/></td>
        <td align="center"><xsl:value-of select="../@value"/></td>
        <td align="left">
            <xsl:value-of select="../@name"/><br/>
            <xsl:value-of select="../@club"/><br/>
            </td>
        <td align="right">
          <xsl:choose>
            <xsl:when test="../@bestpts &lt; 9999">
              <xsl:value-of select="../@bestpts" />
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
          </xsl:choose>
        </td>
        <td align="right">
          <xsl:choose>
            <xsl:when test="@pts &lt; 9999">
              <xsl:value-of select="@pts" />
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
          </xsl:choose>
         </td>
        <td align="right"><xsl:value-of select="@time"/></td>
        <td align="right"><xsl:value-of select="@pen"/></td>
        <td align="left"><xsl:value-of select="@pengate"/></td>
      </tr>
    </xsl:for-each>
    </table>
    <hr/>
  </xsl:for-each>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>
