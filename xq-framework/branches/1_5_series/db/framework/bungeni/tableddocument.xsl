<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:i18n="http://exist-db.org/xquery/i18n" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    
    <!-- Generic templates applied to document views -->
    <xsl:import href="tmpl-doc-generic.xsl"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 6, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p> Tabled document item from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    <!--xsl:character-map name="uncode">
        <xsl:output-character character="<" string="<"/>
        <xsl:output-character character=">" string=">"/>
    </xsl:character-map-->
    <xsl:output method="xml"/>
    
    <!-- Parameter from Bungeni.xqm denoting this as version of a parliamentary 
        document as opposed to main document. -->
    <xsl:template match="doc">
        <xsl:call-template name="doc-item"/>
    </xsl:template>   

    <!-- N/A -->
    <xsl:template name="doc-item-signatories"/>
</xsl:stylesheet>