<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:i18n="http://exist-db.org/xquery/i18n" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> May 10, 2013</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p> Response event view</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml"/>
    <xsl:include href="context_tabs.xsl"/>
    <xsl:param name="event-uri"/>
    <xsl:param name="sequence-id"/>
    <xsl:param name="no-of-events"/>
    <xsl:template match="doc">
        <xsl:variable name="event-uri" select="event"/>
        <xsl:variable name="doc-type" select="bu:document/bu:docType/bu:value"/>
        <xsl:variable name="chamber" select="bu:chamber/bu:type/bu:value"/>
        <xsl:variable name="doc-uri">
            <xsl:choose>
                <xsl:when test="bu:document/@uri">
                    <xsl:value-of select="bu:document/@uri"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:document/@internal-uri"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="moevent-uri" select="bu:ontology/bu:document/bu:owner/bu:person/@href"/>
        <div id="main-wrapper">
            <div id="title-holder">
                <h1 class="title">
                    <xsl:if test="bu:document/bu:progressiveNumber">#<xsl:value-of select="bu:document/bu:progressiveNumber"/>:</xsl:if>
                    <xsl:value-of select="bu:document/bu:title"/>
                    | <i18n:text key="doc-event">event(nt)</i18n:text>: <xsl:value-of select="bu:document/bu:workflowEvents/bu:workflowEvent[@href=$event-uri]/bu:title"/>
                </h1>
            </div>
            <!-- 
                !+FIX_THIS (ao, 7th-May-2012) This can be enabled if we decide to have events on 
                their own tab.
            -->
            <xsl:call-template name="doc-tabs">
                <xsl:with-param name="tab-group" select="$doc-type"/>
                <xsl:with-param name="uri" select="$doc-uri"/>
                <xsl:with-param name="tab-path">responses</xsl:with-param>
                <xsl:with-param name="chamber" select="concat($chamber,'/')"/>
                <xsl:with-param name="excludes" select="exclude/tab"/>
            </xsl:call-template>
            <div id="doc-downloads"/>
            <div id="region-content" class="rounded-eigh tab_container" role="main">
                <div id="doc-main-section">
                    <xsl:call-template name="doc-events">
                        <xsl:with-param name="event-uri" select="$event-uri"/>
                        <xsl:with-param name="doc-type" select="lower-case($doc-type)"/>
                        <xsl:with-param name="doc-uri" select="$doc-uri"/>
                        <xsl:with-param name="chamber" select="$chamber"/>
                    </xsl:call-template>
                    <xsl:variable name="render-doc" select="if(xs:integer($sequence-id) = 0) then (bu:document/bu:workflowEvents/bu:workflowEvent[@href=$event-uri]) else (bu:document/bu:workflowEvents/bu:workflowEvent[@href=$event-uri]/bu:versions/bu:version[bu:sequence = $sequence-id])"/>
                    <h3 id="doc-heading" class="doc-headers">
                        <xsl:value-of select="bu:chamber/bu:type/@showAs"/>
                    </h3>
                    <h4 id="doc-item-desc" class="doc-headers">
                        <xsl:value-of select="$render-doc/bu:title"/>
                    </h4>
                    <h5 id="doc-item-desc" class="doc-headers">
                        <xsl:value-of select="$render-doc/bu:changeNote"/>
                    </h5>
                    <p class="doc-status inline-centered">
                        <span>
                            <b>
                                <i18n:text key="last-event">Last Event(nt)</i18n:text>:</b>
                        </span>
                        &#160;
                        <span>
                            <xsl:value-of select="if($render-doc/bu:status/@showAs) then $render-doc/bu:status/@showAs else $render-doc/bu:status/bu:value"/>
                        </span>
                        &#160;
                        <span>
                            <b>
                                <i18n:text key="status">Status(nt)</i18n:text>&#160;<i18n:text key="date-on">Date(nt)</i18n:text>:</b>
                        </span>
                        &#160;
                        <span>
                            <xsl:value-of select="format-dateTime($render-doc/bu:statusDate,$datetime-format,'en',(),())"/>
                        </span>
                    </p>
                    <div id="doc-content-area">
                        <div>
                            <xsl:choose>
                                <xsl:when test="xs:integer($sequence-id) = 0">
                                    <xsl:if test="$render-doc/bu:summary">
                                        <h2>summary</h2>
                                        <xsl:copy-of select="$render-doc/bu:summary"/>
                                    </xsl:if>
                                    <xsl:if test="$render-doc/bu:description">
                                        <h2>description</h2>
                                        <xsl:copy-of select="$render-doc/bu:description"/>
                                    </xsl:if>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$render-doc/bu:body"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    <!-- DOC-EVENTS -->
    <xsl:template name="doc-events">
        <xsl:param name="event-uri"/>
        <xsl:param name="doc-type"/>
        <xsl:param name="doc-uri"/>
        <xsl:param name="chamber"/>
        <xsl:variable name="total_events" select="count(bu:document/bu:workflowEvents/bu:workflowEvent[@href=$event-uri]/bu:versions/bu:version)"/>
        <div class="doc-views-section">
            <form onsubmit="redirectTo();">
                <label for="eventText" class="inline">
                    Contains <xsl:value-of select="$total_events"/> versions:
                </label>
                <input type="hidden" name="uri" value="{$event-uri}"/>
                <div class="inline">
                    <select name="id" id="eventText">
                        <option value="0">
                            -- summary --
                        </option>
                        <xsl:for-each select="bu:document/bu:workflowEvents/bu:workflowEvent[@href=$event-uri]/bu:versions/bu:version">
                            <xsl:sort select="bu:statusDate" order="descending"/>
                            <xsl:variable name="cur_pos" select="($total_events - position())+1"/>
                            <option value="{bu:sequence}">
                                <xsl:if test="$sequence-id eq bu:sequence">
                                    <!-- if current URI is equal to this versions URI -->
                                    <xsl:attribute name="selected">selected</xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="concat(bu:changeNote,' (',format-dateTime(bu:statusDate,$datetime-format,'en',(),()),')')"/>
                            </option>
                        </xsl:for-each>
                    </select>
                </div>
                <div class="inline">
                    <input type="submit" value="Go"/>
                </div>
            </form>
        </div>
    </xsl:template>
</xsl:stylesheet>