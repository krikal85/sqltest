<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.1">
	<xsl:output method="html"/>
	<xsl:template match="/">
        <html>
            <head><title>Restaurants</title></head>
            <body>
                <h1>Restaurants</h1>
                <table>
                <tr>
                    <th>Name</th>
                    <th>Anschrift</th>
                    <th>Speisen</th>
                </tr>
                <xsl:for-each select="//Restaurant[starts-with(@Plz, '8')]">
                    <tr>
                        <td><xsl:value-of select="@Name"/></td>
                        <td><xsl:value-of select="@Plz"/> - 
                            <xsl:value-of select="@Ort"/> - 
                            <xsl:value-of select="@Adresse"/></td>
                        <td>
                            <ul>
                            <xsl:for-each select="Speisen/Speise">
                                <xsl:if test="position() &lt;=3">
                                    <li><xsl:value-of select="@Name"/></li>
                                </xsl:if>
                            </xsl:for-each>
                            </ul>
                        </td>

                    </tr>
                </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>