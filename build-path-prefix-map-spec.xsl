<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="/usr/share/xml/docbook/stylesheet/docbook-xsl/html/docbook.xsl"/>
<xsl:template name="user.head.content">
<style type="text/css">
/* make compact lists actually compact */
.compact li.listitem p {
    margin: 0;
}
/* in the test vectors, make verbatim output aligned with the "output is same as" text */
blockquote.blockquote, pre.programlisting {
    margin: auto 40px;
}
/* word-wrap long code literals */
code.literal {
    white-space: normal;
    word-break: break-all;
}
</style>
</xsl:template>
<xsl:output method="html" encoding="utf-8"/>
</xsl:stylesheet>
