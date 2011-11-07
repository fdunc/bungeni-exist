<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 2, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Ashok Hariharan</xd:p>
            <xd:p>This is the template for the common paginator generator</xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- this is the paginator template matcher -->
    <xsl:template match="paginator">
        <xsl:variable name="offset">
            <xsl:value-of select="./offset"/>
        </xsl:variable>
        <xsl:variable name="count">
            <xsl:value-of select="./count"/>
        </xsl:variable>
        <xsl:variable name="limit">
            <xsl:value-of select="./limit"/>
        </xsl:variable>
        <div id="paginator" class="paginate" align="right">
            <!--div id="xxx"><xsl:value-of select="$count"></xsl:value-of></div-->
            <xsl:call-template name="generate-paginator">
                <xsl:with-param name="i">1</xsl:with-param>
                <xsl:with-param name="count" select="$count"/>
                <xsl:with-param name="offset" select="$offset"/>
                <xsl:with-param name="limit" select="$limit"/>
            </xsl:call-template>
        </div>
    </xsl:template>
    
    <!-- this is the paginator generator -->
    <xsl:template name="generate-paginator">
        <xsl:param name="i"/>
        <xsl:param name="count"/>
        <xsl:param name="offset"/>
        <xsl:param name="limit"/>
        
        <!--begin_: Line_by_Line_Output -->
        <xsl:if test="$i &lt;= round($count div $limit)">
            <xsl:choose>
                <xsl:when test="((abs($i)-0)*$limit = $offset) or (($offset+1) = $i)">
                    <a class="curr-no">
                        <xsl:attribute name="href">
                            <xsl:text>#</xsl:text>
                        </xsl:attribute>
                        <xsl:value-of select="$i"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:text>?offset=</xsl:text>
                            <xsl:value-of select="abs($limit)*abs($i)"/>
                            <xsl:text>&amp;limit=</xsl:text>
                            <xsl:value-of select="$limit"/>
                        </xsl:attribute>
                        <xsl:value-of select="$i"/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        
        <!--begin_: RepeatTheLoopUntilFinished-->
        <xsl:if test="$i &lt; floor($count div $limit)">
            <xsl:call-template name="generate-paginator">
                <xsl:with-param name="i">
                    <xsl:value-of select="$i + 1"/>
                </xsl:with-param>
                <xsl:with-param name="count" select="$count"/>
                <xsl:with-param name="offset" select="$offset"/>
                <xsl:with-param name="limit" select="$limit"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>