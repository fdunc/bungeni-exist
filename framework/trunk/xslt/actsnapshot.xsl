<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 5, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> ashok</xd:p>
            <xd:p>Present an Act Summary </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="html" />
    
    <xsl:template match="akomaNtoso">
        <div class="act">
            <div class="act-number">
                <span class="label">Act No: </span>
                <xsl:value-of select="//docNumber[@id='ActNumber']" />  
            </div>
            <div class="act-title">
              <span class="label">Act Title: </span>
              <xsl:value-of select="//docTitle[@id='ActTitle']" />  
            </div>
            <div class="act-long-title">
                
                <xsl:value-of select="//docTitle[@id='ActLongTitle']" />  
            </div>
            <div class="act-commencement">
                <span class="label">Enacted Date:</span>
                <xsl:value-of select="//docDate[@refersTo='#CommencementDate']" />  
            </div>
            <xsl:variable name="this-act"><xsl:value-of select="//docNumber[@id='ActIdentifier']" /></xsl:variable>
        </div>
    </xsl:template>
    
</xsl:stylesheet>
