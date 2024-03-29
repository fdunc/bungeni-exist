<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:an="http://www.akomantoso.org/1.0" xmlns:i18n="http://exist-db.org/xquery/i18n" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 16, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p> Committee item from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml"/>
    <xsl:include href="context_tabs.xsl"/>
    <xsl:param name="mem-status"/>
    <xsl:param name="chamber"/>
    <xsl:param name="chamber-id"/>
    <xsl:param name="epub"/>
    <xsl:template match="doc">
        <xsl:variable name="ver_id" select="version"/>
        <xsl:variable name="doc-type" select="bu:ontology/bu:group/bu:docType/bu:value"/>
        <xsl:variable name="doc-uri" select="bu:ontology/bu:group/@uri"/>
        <div id="main-wrapper">
            <div id="title-holder">
                <h1 class="title">
                    <xsl:value-of select="bu:ontology/bu:group/bu:fullName"/>
                </h1>
            </div>
            <xsl:if test="$epub ne 'true'">
                <xsl:call-template name="doc-tabs">
                    <xsl:with-param name="tab-group">
                        <xsl:value-of select="$doc-type"/>
                    </xsl:with-param>
                    <xsl:with-param name="uri">
                        <xsl:value-of select="$doc-uri"/>
                    </xsl:with-param>
                    <xsl:with-param name="tab-path">members</xsl:with-param>
                    <xsl:with-param name="chamber" select="concat($chamber,'/')"/>
                    <xsl:with-param name="excludes" select="exclude/tab"/>
                </xsl:call-template>
                <div id="doc-downloads"/>
            </xsl:if>
            <div id="region-content" class="rounded-eigh tab_container" role="main">
                <div id="doc-main-section">
                    <div id="toggle-wrapper" class="clear toggle-wrapper">
                        <xsl:if test="$epub ne 'true'">
                            <div id="toggle-i18n" class="hide">
                                <span id="i-compress">
                                    <i18n:text key="compress">▼&#160;compress all(nt)</i18n:text>
                                </span>
                                <span id="i-expand">
                                    <i18n:text key="expand">►&#160;expand all(nt)</i18n:text>
                                </span>
                            </div>
                            <div class="toggler-list list-active" id="expand-all">▼&#160;<i18n:text key="compress">compress all(nt)</i18n:text>
                            </div>
                        </xsl:if>
                        <xsl:if test="bu:ontology/bu:group/bu:status/bu:value = 'active'">
                            <div class="sub-toggler" id="member-statuses">
                                <span class="list-dot {if($mem-status='current') then 'current' else ()}">•&#160;<a href="{$chamber}/committee-members?uri={$doc-uri}&amp;status=current">
                                        <i18n:translate>
                                            <i18n:text key="current">current ({1}) (nt)</i18n:text>
                                            <i18n:param>
                                                <xsl:value-of select="count(bu:ontology/bu:members/bu:member[bu:type/bu:value eq 'committee_member' and empty(bu:endDate)])"/>
                                            </i18n:param>
                                        </i18n:translate>
                                    </a>
                                </span>
                                &#160;
                                <span class="list-dot {if($mem-status = 'current') then () else 'current'}">•&#160;<a href="{$chamber}/committee-members?uri={$doc-uri}&amp;status=past">
                                        <i18n:translate>
                                            <i18n:text key="former">former ({1}) (nt)</i18n:text>
                                            <i18n:param>
                                                <xsl:value-of select="count(bu:ontology/bu:members/bu:member[bu:type/bu:value eq 'committee_member' and not(empty(bu:endDate))])"/>
                                            </i18n:param>
                                        </i18n:translate>
                                    </a>
                                </span>
                            </div>
                        </xsl:if>
                    </div>
                    <ul id="list-toggle" class="ls-row clear">
                        <xsl:choose>
                            <xsl:when test="$mem-status = 'current'">
                                <xsl:for-each select="bu:ontology/bu:members/bu:member[bu:type/bu:value eq 'committee_member' and empty(bu:endDate)]">
                                    <xsl:sort select="bu:designations/bu:designation/bu:sortOrder" order="ascending" data-type="number"/>
                                    <xsl:call-template name="mem-list-details"/>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="bu:ontology/bu:members/bu:member[bu:type/bu:value eq 'committee_member' and not(empty(bu:endDate))]">
                                    <xsl:sort select="bu:designations/bu:designation/bu:sortOrder" order="ascending" data-type="number"/>
                                    <xsl:call-template name="mem-list-details"/>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </ul>
                </div>
            </div>
        </div>
    </xsl:template>
    <!-- LIST-MEMBERS -->
    <xsl:template name="mem-list-details">
        <li>
            <a href="{$chamber}/member?uri={bu:person/@href}">
                <xsl:value-of select="bu:person/@showAs"/>
            </a>
            <div class="struct-ib">/ <xsl:value-of select="bu:memberElectionType/bu:value"/>
            </div>
            <div class="struct-ib">/ <i18n:text key="member-status">
                    <xsl:value-of select="bu:activeStatus/bu:value"/>
                </i18n:text>
            </div>
            <span class="tgl-pad-right">▼</span>
            <div class="doc-toggle">
                <div style="min-height:60px;">
                    <div class="list-inline">
                        <div class="inline-label">
                            <i18n:text key="date-start">start date(nt)</i18n:text>:
                        </div>
                        <xsl:value-of select="format-date(xs:date(bu:startDate),$date-format,'en',(),())"/>
                    </div>
                    <div class="list-inline">
                        <div class="inline-label">
                            <i18n:text key="date-elected">elected date(nt)</i18n:text>:
                        </div>
                        <xsl:value-of select="format-date(xs:date(bu:electionDate),$date-format,'en',(),())"/>
                    </div>
                    <xsl:if test="bu:endDate">
                        <div class="list-inline">
                            <div class="inline-label">
                                <i18n:text key="End Date">end date(nt)</i18n:text>:
                            </div>
                            <xsl:value-of select="format-date(xs:date(bu:endDate),$date-format,'en',(),())"/>
                        </div>
                    </xsl:if>
                    <xsl:if test="string-length(bu:notes) != 0">
                        <div class="list-inline">
                            <div class="inline-label">
                                <i18n:text key="notes">notes(nt)</i18n:text>:
                        </div>
                            <xsl:value-of select="substring(bu:notes,0,360)"/>...
                    </div>
                    </xsl:if>
                </div>
                <div class="clear"/>
            </div>
        </li>
    </xsl:template>
</xsl:stylesheet>