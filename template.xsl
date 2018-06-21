<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.1">
<xsl:output method="html"/>

        <xsl:template match="/">

            <html>
               
                <xsl:apply-templates select="//Restaurant"/>
 
            </html>

        </xsl:template>
        <xsl:template match= "//Restaurant">

                <xsl:value-of select= "@Name" />

        </xsl:template>

</xsl:stylesheet>