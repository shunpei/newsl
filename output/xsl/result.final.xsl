<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" encoding="UTF-8"/>

<xsl:template match="/">
  <xsl:apply-templates select="all"/>
</xsl:template>


<xsl:template match="all">
  <html xml:lang="ja" lang="ja">
  <head>
  <title>sum Result</title>
  <style type="text/css">
  table {font-family:monospace;}
  .pagebreak { page-break-before: always; }
  </style>
  </head>
  <body>
  <xsl:for-each select="category">
  <xsl:sort select="@value" order="ascending" />
    <xsl:if test="position() &gt; 1">
      <div class="pagebreak"/>
    </xsl:if>
    <div align="right">2013.5.19</div>
    <h4>２０１３年度国民体育大会中国ブロック大会　兼　中国選手権大会カヌースラローム・ワイルドウォーター選手権大会</h4>
    <h2 align="center"><b>スラローム競技結果</b></h2>
    <h2><xsl:value-of select="@value"/></h2>
    <table border="1">
    <tr>
      <th>order</th>
      <th>zn</th>
      <th>name</th>
      <th>result</th>
      <th>run</th>
      <th>pts</th>
      <th>time</th>
      <th>pen</th>
      <th>pengate</th>
    </tr>
    <xsl:for-each select="zn">
    <xsl:sort select="@bestpts" data-type="number" order="ascending" />
    <xsl:sort select="@value" order="ascending" />
      <tr>
        <!-- order -->
        <td align="center" nowrap="nowrap">
          <xsl:choose>
            <xsl:when test="@bestpts &lt; 9999">
              <xsl:value-of select="position()" />
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
          </xsl:choose>
        </td>
        <!-- race data -->
        <td align="center" nowrap="nowrap"><xsl:value-of select="@value"/></td>
        <td align="left" nowrap="nowrap">
            <xsl:value-of select="@name"/><br/>
            <xsl:value-of select="@club"/><br/>
            </td>
        <td align="right" nowrap="nowrap">
          <xsl:choose>
            <xsl:when test="@bestpts &lt; 9999">
              <xsl:value-of select="@bestpts" />
            </xsl:when>
            <xsl:otherwise>-</xsl:otherwise>
          </xsl:choose>
        </td>
        <td align="center" nowrap="nowrap">
        <xsl:for-each select="race">
        <xsl:sort select="@value" data-type="text" order="ascending" />
          <xsl:value-of select="@value"/><br/>
        </xsl:for-each>
        </td>
        <td align="right" nowrap="nowrap">
        <xsl:for-each select="race">
        <xsl:sort select="@value" data-type="text" order="ascending" />
          <xsl:value-of select="@pts"/><br/>
        </xsl:for-each>
        </td>
        <td align="right" nowrap="nowrap">
        <xsl:for-each select="race">
        <xsl:sort select="@value" data-type="text" order="ascending" />
          <xsl:value-of select="@time"/><br/>
        </xsl:for-each>
        </td>
        <td align="right"  nowrap="nowrap">
        <xsl:for-each select="race">
        <xsl:sort select="@value" data-type="text" order="ascending" />
          <xsl:value-of select="@pen"/><br/>
        </xsl:for-each>
        </td>
        <td align="left" nowrap="nowrap">
        <xsl:for-each select="race">
        <xsl:sort select="@value" data-type="text" order="ascending" />
          <xsl:value-of select="@pengate"/><br/>
        </xsl:for-each>
        </td>
      </tr>
    </xsl:for-each>
    </table>
    <br />
    <div align="right">
    <table border="1">
    <tr><th>対象</th><td align="center">１本目　・　２本目</td></tr>
    <tr><th>発表種別</th><td>確定　・　掲示　・　仮</td></tr>
    <tr><th>確定時刻</th><td>　</td></tr>
    </table>
    <table border="1">
    <tr><th>競技委員長</th><th>審判部長　</th><th>集計主任　</th></tr>
    <tr><td><br /><br /></td><td><br /><br /></td><td><br /><br /></td></tr>
    </table>

    </div>
    <hr/>
  </xsl:for-each>
  </body>
  </html>
</xsl:template>
</xsl:stylesheet>
