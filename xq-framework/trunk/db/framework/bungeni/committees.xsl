<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <!-- IMPORTS -->
    <xsl:import href="config.xsl"/>
    <xsl:import href="paginator.xsl"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 14, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p>List committees from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- +SORT_ORDER(ah,nov-2011) pass the sort ordr into the XSLT-->
    <xsl:param name="sortby"/>
    <xsl:template match="docs">
        <div id="main-doc" class="rounded-eigh tab_container" role="main">
            <!-- container for holding listings -->
            <div id="doc-listing" class="acts">
                <!-- render the paginator -->
                <div class="list-header">
                    <div class="toggler-list" id="expand-all">- compress all</div>
                    <xsl:apply-templates select="paginator"/>
                    <div id="search-n-sort" class="search-bar">
                        <form method="get" action="" name="search_sort">
                            <label for="search_for">Search text:</label>
                            <input id="search_for" name="q" class="search_for" type="text" value=""/>
                            <label for="search_in">in:</label>
                            <select name="w" id="search_w">
                                <option value="doc" selected="">entire document</option>
                                <option value="name">short name</option>
                                <option value="text">body text</option>
                                <option value="desc">description</option>
                                <option value="changes">changes</option>
                                <option value="versions">versions</option>
                                <option value="owner">owner</option>
                            </select>
                            <label for="search_in">sort by:</label>
                            <select name="s" id="sort_by">
                                <option value="st_date_newest" selected="selected">status date [newest]</option>
                                <option value="st_date_oldest">status date [oldest]</option>
                                <option value="sub_date_newest">submission date [newest]</option>
                                <option value="sub_date_oldest">submission date [oldest]</option>
                                <option value="ministry">ministry</option>
                            </select>
                            <input value="search" type="submit"/>
                        </form>
                    </div>
                </div>
                <!-- render the actual listing-->
                <xsl:apply-templates select="alisting"/>
            </div>
        </div>
    </xsl:template>

    
    <!-- Include the paginator generator -->
    <xsl:include href="paginator.xsl"/>
    <xsl:template match="alisting">
        <ul id="list-toggle" class="ls-row" style="clear:both">
            <xsl:apply-templates mode="renderui"/>
        </ul>
    </xsl:template>
    <xsl:template match="document" mode="renderui">
        <xsl:variable name="docIdentifier" select="bu:ontology/bu:group/@uri"/>
        <li>
            <a href="committee/profile?uri={$docIdentifier}" id="{$docIdentifier}">
                <xsl:value-of select="bu:ontology/bu:legislature/bu:fullName"/>
            </a>
            <div style="display:inline-block;">/ <xsl:value-of select="bu:ontology/bu:legislature/bu:type"/>
            </div>
            <span>-</span>
            <div class="doc-toggle">
                <table class="doc-tbl-details">
                    <tr>
                        <td class="labels">id:</td>
                        <td>
                            <xsl:value-of select="bu:ontology/bu:bungeni/bu:principalGroup/@href"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">parent group:</td>
                        <td>
                            <xsl:value-of select="bu:ontology/bu:legislature/bu:parent_group/bu:shortName"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">start date:</td>
                        <td>
                            <xsl:value-of select="format-date(bu:ontology/bu:group/bu:startDate, '[D1o] [MNn,*-3], [Y]', 'en', (),())"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">submission date:</td>
                        <td>
                            <xsl:value-of select="format-dateTime(bu:ontology/bu:legislature/bu:statusDate,$datetime-format,'en',(),())"/>
                        </td>
                    </tr>
                </table>
            </div>
        </li>
    </xsl:template>
</xsl:stylesheet>