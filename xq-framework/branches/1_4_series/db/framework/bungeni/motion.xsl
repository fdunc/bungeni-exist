<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 03, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p> Question item from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml"/>
    <xsl:include href="context_tabs.xsl"/>
    <xsl:param name="version"/>
    <xsl:template match="document">
        <xsl:variable name="ver_id" select="version"/>
        <xsl:variable name="doc-type" select="primary/bu:ontology/bu:document/@type"/>
        <xsl:variable name="ver_uri" select="primary/bu:ontology/bu:legislativeItem/bu:versions/bu:version[@uri=$ver_id]/@uri"/>
        <xsl:variable name="doc_uri" select="primary/bu:ontology/bu:legislativeItem/@uri"/>
        <div id="main-wrapper">
            <div id="title-holder" class="theme-lev-1-only">
                <h1 id="doc-title-blue">
                    Motion <xsl:value-of select="primary/bu:ontology/bu:legislativeItem/bu:itemNumber"/>:&#160;                     
                    <xsl:value-of select="primary/bu:ontology/bu:legislativeItem/bu:shortName"/>
                    <!-- If its a version and not a main document... add version title below main title -->
                    <xsl:if test="$version eq 'true'">
                        <br/>
                        <span class="doc-sub-title-red">Version - <xsl:value-of select="format-dateTime(primary/bu:ontology/bu:legislativeItem/bu:versions/bu:version[@uri=$ver_uri]/bu:statusDate,$datetime-format,'en',(),())"/>
                        </span>
                    </xsl:if>
                </h1>
            </div>
            <xsl:call-template name="doc-tabs">
                <xsl:with-param name="tab-group">
                    <xsl:choose>
                        <xsl:when test="$version eq 'true'">
                            <xsl:value-of select="concat($doc-type,'-ver')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$doc-type"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="uri">
                    <xsl:choose>
                        <xsl:when test="$version eq 'true'">
                            <xsl:value-of select="$ver_uri"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$doc_uri"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="tab-path">text</xsl:with-param>
            </xsl:call-template>
            <div id="doc-downloads">
                <ul class="ls-downloads">
                    <li>
                        <a href="{$doc-type}/pdf?uri={$doc_uri}" title="get PDF document" class="pdf">
                            <em>PDF</em>
                        </a>
                    </li>
                    <li>
                        <a href="{$doc-type}/xml?uri={$doc_uri}" title="get raw xml output" class="xml">
                            <em>XML</em>
                        </a>
                    </li>
                </ul>
            </div>
            <div id="main-doc" class="rounded-eigh tab_container" role="main">
                <div id="doc-main-section">
                    <xsl:if test="$version eq 'true'">
                        <div class="rounded-eigh tab_container" style="clear:both;width:110px;height:auto;float:right;display:inline;position:relative;top:0px;right:10px;">
                            <ul class="doc-versions">
                                <li>
                                    <a href="{primary/bu:ontology/bu:document/@type}/text?uri={primary/bu:ontology/bu:legislativeItem/@uri}">current</a>
                                </li>
                                <xsl:variable name="total_versions" select="count(primary/bu:ontology/bu:legislativeItem/bu:versions/bu:version)"/>
                                <xsl:for-each select="primary/bu:ontology/bu:legislativeItem/bu:versions/bu:version">
                                    <xsl:sort select="bu:statusDate" order="descending"/>
                                    <xsl:variable name="cur_pos" select="($total_versions - position())+1"/>
                                    <li>
                                        <xsl:choose>
                                            <!-- if current URI is equal to this versions URI -->
                                            <xsl:when test="$ver_uri eq @uri">
                                                <span>version-<xsl:value-of select="$cur_pos"/>
                                                </span>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <a href="{$doc-type}/version/text?uri={@uri}">
                                                    Version-<xsl:value-of select="$cur_pos"/>
                                                </a>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:if>
                    <h3 id="doc-heading" class="doc-headers">
                        KENYA PARLIAMENT
                    </h3>
                    <h4 id="doc-item-desc" class="doc-headers">
                        <xsl:value-of select="primary/bu:ontology/bu:legislativeItem/bu:shortName"/>
                    </h4>
                    <h4 id="doc-item-desc2" class="doc-headers-darkgrey">Motion Number: 
                        <xsl:value-of select="primary/bu:ontology/bu:legislativeItem/bu:itemNumber"/>
                    </h4>
                    <h4 id="doc-item-desc2" class="doc-headers-darkgrey">Primary Sponsor: <i>
                            <a href="member?uri={primary/bu:ontology/bu:legislativeItem/bu:owner/@href}">
                                <xsl:value-of select="primary/bu:ontology/bu:legislativeItem/bu:owner/@showAs"/>
                            </a>
                        </i>
                    </h4>
                    <h4 id="doc-item-desc2" class="doc-headers-darkgrey">Sponsors: ( 
                        <xsl:choose>
                            <!-- check whether we have signatories or not -->
                            <xsl:when test="primary/bu:ontology/bu:signatories/bu:signatory">
                                <xsl:for-each select="primary/bu:ontology/bu:signatories/bu:signatory">
                                    <i>
                                        <a href="member?uri={@href}">
                                            <xsl:value-of select="@showAs"/>
                                        </a>
                                    </i>
                                    <xsl:if test="position() &lt; last()">,</xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                None
                            </xsl:otherwise>
                        </xsl:choose>
                        )
                    </h4>
                    <xsl:variable name="render-doc" select="if ($version eq 'true') then                         primary/bu:ontology/bu:legislativeItem/bu:versions/bu:version[@uri=$ver_uri]                          else                         primary/bu:ontology/bu:legislativeItem                         "/>
                    <div class="doc-status">
                        <span>
                            <b>Last Event:</b>
                        </span>
                        <span>
                            <xsl:value-of select="$render-doc/bu:status"/>
                        </span>
                        <span>
                            <b>Date:</b>
                        </span>
                        <span>
                            <xsl:value-of select="format-dateTime($render-doc/bu:statusDate,$datetime-format,'en',(),())"/>
                        </span>
                    </div>
                    <div id="doc-content-area">
                        <div>
                            <xsl:copy-of select="$render-doc/bu:body"/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>