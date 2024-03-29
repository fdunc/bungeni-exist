<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:i18n="http://exist-db.org/xquery/i18n" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 9, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p> MP Personal Information from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml"/>
    <xsl:include href="context_tabs.xsl"/>
    <xsl:include href="context_downloads.xsl"/>
    <xsl:param name="address_type"/>
    <xsl:param name="chamber"/>
    <xsl:param name="chamber-id"/>
    <xsl:template match="doc">
        <xsl:variable name="onto-type">
            <xsl:choose>
                <xsl:when test="$address_type eq 'Member'">
                    <xsl:value-of select="bu:ontology/bu:membership/bu:docType/bu:value"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:ontology/bu:group/bu:docType/bu:value"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="doc-type">
            <xsl:choose>
                <xsl:when test="$address_type eq 'Member'">
                    <xsl:value-of select="$address_type"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:ontology/bu:group/bu:docType/bu:value"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="doc-uri">
            <xsl:choose>
                <xsl:when test="$address_type eq 'Member'">
                    <xsl:value-of select="bu:ontology/bu:membership/bu:referenceToUser/bu:refersTo/@href"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:ontology/bu:group/@uri"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contact-name">
            <xsl:choose>
                <xsl:when test="$address_type eq 'Member'">
                    <xsl:value-of select="concat(bu:ontology/bu:membership/bu:referenceToUser/bu:firstName,' ', bu:ontology/bu:membership/bu:referenceToUser/bu:lastName, ' (',bu:ontology/bu:membership/bu:referenceToUser/bu:title,')')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:ontology/bu:group/bu:shortName"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="contact-name-title">
            <xsl:choose>
                <xsl:when test="$address_type eq 'Member'">
                    <xsl:value-of select="concat(bu:ontology/bu:membership/bu:referenceToUser/bu:salutation,', ',bu:ontology/bu:membership/bu:referenceToUser/bu:firstName,' ', bu:ontology/bu:membership/bu:referenceToUser/bu:lastName)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="bu:ontology/bu:group/bu:fullName"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div id="main-wrapper">
            <div id="title-holder">
                <h1 class="title">
                    <xsl:choose>
                        <xsl:when test="$address_type eq 'Member'">
                            <xsl:value-of select="concat(bu:ontology/bu:membership/bu:referenceToUser/bu:firstName,' ', bu:ontology/bu:membership/bu:referenceToUser/bu:lastName,', ',bu:ontology/bu:membership/bu:referenceToUser/bu:title)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="bu:ontology/bu:group/bu:fullName"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </h1>
            </div>
            <xsl:call-template name="mem-tabs">
                <xsl:with-param name="tab-group">
                    <xsl:value-of select="$doc-type"/>
                </xsl:with-param>
                <xsl:with-param name="tab-path">contacts</xsl:with-param>
                <xsl:with-param name="chamber" select="concat($chamber,'/')"/>
                <xsl:with-param name="uri" select="$doc-uri"/>
                <xsl:with-param name="excludes" select="exclude/tab"/>
            </xsl:call-template>
            <!-- Renders the document download types -->
            <xsl:if test="$doc-type eq 'Member'">
                <xsl:call-template name="doc-formats">
                    <xsl:with-param name="render-group">contacts</xsl:with-param>
                    <xsl:with-param name="doc-type" select="lower-case($doc-type)"/>
                    <xsl:with-param name="chamber" select="concat($chamber,'/')"/>
                    <xsl:with-param name="uri" select="$doc-uri"/>
                </xsl:call-template>
            </xsl:if>
            <div id="region-content" class="rounded-eigh tab_container" role="main">
                <div id="doc-main-section">
                    <div id="toggle-wrapper" class="clear toggle-wrapper">
                        <div id="toggle-i18n" class="hide">
                            <span id="i-compress">
                                <i18n:text key="compress">▼&#160;compress all(nt)</i18n:text>
                            </span>
                            <span id="i-expand">
                                <i18n:text key="expand">►&#160;expand all(nt)</i18n:text>
                            </span>
                        </div>
                        <div class="toggler-list" id="expand-all">▼&#160;<i18n:text key="compress">compress all(nt)</i18n:text>
                        </div>
                    </div>
                    <ul id="list-toggle" class="ls-row clear">
                        <xsl:for-each select="ref/bu:ontology/child::node()/bu:addresses/bu:address">
                            <xsl:sort select="bu:logicalAddressType" order="descending"/>
                            <li>
                                <xsl:value-of select="bu:logicalAddressType"/>
                                <span class="tgl-pad-right">▼</span>
                                <div class="doc-toggle">
                                    <div id="{bu:postalAddressType}{bu:addressId}" class="toggle address-info" style="min-height:100px">
                                        <div class="address-block">
                                            <address>
                                                <strong>
                                                    <xsl:value-of select="$contact-name-title"/>
                                                </strong>
                                                <br/>
                                                <i18n:text key="Address">address(nt)</i18n:text>, room <bu:groupId type="xs:integer">4</bu:groupId>
                                                <br/>
                                                <xsl:value-of select="bu:city"/>, <xsl:value-of select="bu:country/bu:countryName"/>&#160;<span title="i18n(Zip Code, Zip Code (nt))">
                                                    <xsl:value-of select="bu:zipCode"/>
                                                </span>
                                                &#160;<xsl:value-of select="bu:postalAddressType/@showAs"/>&#160;<bu:addressId type="xs:integer">4</bu:addressId>
                                                <br/>
                                                <abbr title="i18n(Phone Number(s), phone (nt))">
                                                    <i18n:text key="Phone Number(s)">Phone (nt)</i18n:text>:</abbr>
                                                <xsl:value-of select="bu:phone"/>
                                                <br/>
                                                <abbr title="i18n(Fax Number(s), fax (nt))">
                                                    <i18n:text key="Fax Number(s)">Fax (nt)</i18n:text>:</abbr>
                                                <xsl:value-of select="bu:fax"/>
                                            </address>
                                            <address>
                                                <strong>
                                                    <xsl:value-of select="$contact-name"/>
                                                </strong>
                                                <br/>
                                                <a href="mailto:{$contact-name}&#160;&lt;{bu:email}&gt;">
                                                    <xsl:value-of select="bu:email"/>
                                                </a>
                                            </address>
                                        </div>
                                        <div class="clear"/>
                                        <div class="mem-desc">
                                            <xsl:copy-of select="bu:ontology/bu:membership/bu:notes/child::node()" copy-namespaces="no"/>
                                        </div>
                                    </div>
                                    <div class="clear"/>
                                </div>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>