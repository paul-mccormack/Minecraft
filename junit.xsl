<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- Copy all nodes and attributes by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- If a failure element exists within a testcase element, set the value of the message
    attribute of the failure element to the contents of the name attribute of the testcase element concatenated with the file attribute of the testcase element -->
    <xsl:template match="testcase/failure">
        <xsl:copy>
            <xsl:attribute name="message">
                <xsl:value-of select="concat(../@name, ' ', ../@file)" />
            </xsl:attribute>
        </xsl:copy>
    </xsl:template>

    <!-- Set the value of the name attribute of the testcase element to the value of the classname
    element of that testcase element -->
    <xsl:template match="testcase/@name">
        <xsl:attribute name="name">
            <xsl:value-of select="../@classname" />
        </xsl:attribute>
    </xsl:template>

    <!-- Remove the classname attribute from the testcase element -->
    <xsl:template match="testcase/@classname" />

    <!-- Remove the file attribute from the testcase element -->
    <xsl:template match="testcase/@file" />
</xsl:stylesheet>