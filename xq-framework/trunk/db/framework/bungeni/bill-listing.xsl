<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:an="http://www.akomantoso.org/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:bu="http://portal.bungeni.org/1.0/" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 5, 2011</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p>Lists bills from Bungeni</xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- load configuration info -->
    <xsl:include href="config.xsl"/>
    <xsl:template match="docs">
        <div id="main-doc" class="rounded-eigh tab_container" role="main">
            <!-- container for holding listings -->
            <div id="doc-listing" class="acts">
                <!-- render the paginator -->
                <div class="list-header">
                    <div class="toggler-list" id="expand-all">+ expand all</div>
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
                                <option value="status" selected="">status date new</option>
                                <option value="status" selected="">status date old</option>
                                <option value="pub_date">publication date old</option>
                                <option value="status" selected="">publication date new</option>
                                <option value="gazetted">gazetted</option>
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
            <xsl:apply-templates mode="renderui">
                <xsl:sort select="output/bu:ontology/bu:legislativeItem/bu:statusDate" order="descending"/>
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    <xsl:template match="document" mode="renderui">
        <xsl:variable name="docIdentifier" select="output/bu:ontology/bu:legislativeItem/@uri"/>
        <li>
            <a href="bill/text?uri={$docIdentifier}" id="{$docIdentifier}">
                <xsl:value-of select="output/bu:ontology/bu:legislativeItem/bu:shortName"/>
            </a>
            <span>+</span>
            <div class="doc-toggle">
                <table class="doc-tbl-details">
                    <tr>
                        <td class="labels">id:</td>
                        <td>
                            <xsl:value-of select="$docIdentifier"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">moved by:</td>
                        <td>
                            <xsl:value-of select="output/bu:ontology/bu:legislativeItem/bu:owner/@showAs"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">status:</td>
                        <td>
                            <xsl:value-of select="output/bu:ontology/bu:legislativeItem/bu:status"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">status date:</td>
                        <td>
                            <xsl:value-of select="format-dateTime(output/bu:ontology/bu:legislativeItem/bu:statusDate,$datetime-format,'en',(),())"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">submission date:</td>
                        <td>
                            <xsl:value-of select="format-date(output/bu:ontology/bu:bungeni/bu:parliament/@date,$date-format,'en',(),())"/>
                        </td>
                    </tr>
                    <tr>
                        <td class="labels">ministry:</td>
                        <td>
                            <xsl:value-of select="referenceInfo/ref/bu:ministry/bu:shortName"/>
                        </td>
                    </tr>
                </table>
            </div>
        </li>
    </xsl:template>
</xsl:stylesheet>