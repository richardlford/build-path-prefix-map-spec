<?xml version='1.0'?>
<!-- https://stackoverflow.com/questions/5665616/move-an-xml-element-into-another-element-with-xslt -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output/>

  <!--  identity ("do-nothing") transformation  -->
  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!--  select the first child of a <div> with class="sect1" and who has a
        direct-or-indirect descendent <a> with name="notes-and-links"  -->
  <xsl:template match="//div[@class='sect1' and .//a[@name='notes-and-links']]/*[1]">
    <xsl:call-template name="identity"/>
    <div class="footnotes">
      <!--  select all children except <hr> and <br>  -->
      <xsl:copy-of select="//div[@class='footnotes']/*[not(self::hr) and not(self::br)]"/>
    </div>
  </xsl:template>

  <xsl:template match="//div[@class='footnotes']"/>
</xsl:stylesheet>
