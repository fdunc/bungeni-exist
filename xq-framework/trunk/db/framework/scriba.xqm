xquery version "3.0";

module namespace scriba = 'http://scribaebookmake.sourceforge.net/1.0/';
declare namespace transform = "http://exist-db.org/xquery/transform";
import module namespace cmn = "http://exist.bungeni.org/cmn" at "common.xqm";
import module namespace functx = "http://www.functx.com" at "functx.xqm";

(:~
    : Module for Generating ScribaEbookMaker main config file. The SCF, see structure below in
    : scriba:create-book()
    
    : @author Anthony Oduor <aowino@googlemail.com>
:)

(:~
 : Add authors to metadata node
 :
 : @param $authors nodes with authors, editors
 :
 : @return <metaitem/> node(s)
:)
declare function scriba:add-authors($creators as node()) {

    if (not(empty($creators/node()))) then 
        for $creator in $creators/node()
            return 
                <metaitem eletype="dc" elename="creator" role="{data($creator/@role)}">{$creator/text()}</metaitem>
    else
        <metaitem eletype="dc" elename="creator" role="aut">Bungeni Creator</metaitem>     
};

(:~
 : Add title of ebook to metadata node
 :
 : @param $title of document
 :
 : @return <metaitem/> node(s)
:)
declare function scriba:add-title($title as xs:string) {
    if (not(empty($title))) then 
        <metaitem eletype="dc" elename="title">{$title}</metaitem>
    else
        <metaitem eletype="dc" elename="title">Blank title of %pretty_date%</metaitem> 
};

(:~
 : Generate main component - <contents/> node
 :
 : @param $pages content nodes that will make up pages of the ePUB
 :
 : @return <contents/> node
:)
declare function scriba:generate-content($pages as node()) {

    <contents tocId="toc">
        <content packageId="toc" packagePath="/" packageFile="toc.ncx" contentMediaType="application/x-dtbncx+xml" />
        <content packageId="cover-image" 
                packagePath="/IMG"
                contentUrl="http://localhost:8088/exist/rest/db/framework/bungeni/assets/images/bungeni-logo.png"
                packageFile="bungeni-logo.png" 
                isInSpine="true"
                contentMediaType="image/png"/>        
        <content packageId="cover" packagePath="/" packageFile="cover.html" isInSpine="true" contentMediaType="application/xhtml+xml" 
                tocName="Cover Page" 
                isNeededTidy="true" 
                isNeeded="xsl">
                <![CDATA[
                    <div id="cover-image" style="margin:0 auto;"> 
                        <h1>Bungeni Publication</h1>                     
                        <img src="IMG/bungeni-logo.png" alt="Bungeni Logo"/> 
                    </div>
                ]]>
        </content>                
        {
        for $page at $pos in $pages/page
            return
                <content packageId="bungeni_{$page/@id}" 
                        packagePath="{$pos} {functx:capitalize-first($page/@id)}" 
                        packageFile="bungeni/bungeni_{$page/@id}.htm" 
                        contentMediaType="application/xhtml+xml" 
                        isInSpine="true" 
                        tocName="Bungeni {$page/@id}" 
                        isNeededTidy="true" 
                        isNeededXsl="false">
                    {scriba:escapee($page)}
                </content>
        }
    </contents>
    
};

(:~
 : Creates <book/> node - Scriba's configuration file. See structure below
 :
    <book version="1.0">
        <metadata>
            <metaitem eletype="dc/meta" elename=""/>
            ...
        </metadata>
        <contents tocId="toc">
            <content packageId="bungeni_{name}" 
                    packagePath="Bungeni_{$pos}_{name}" 
                    packageFile="bungeni/bungeni_{name}.htm" 
                    contentMediaType="application/xhtml+xml" 
                    isInSpine="true" 
                    tocName="Bungeni {name}" 
                    isNeededTidy="true" 
                    isNeededXsl="false">
                    
                    <![CDATA[ *insert content* ]]>
                    
            </content>
            ...
        </contents>
    </book>
 :
 : @param $lang ISO code of the language in use
 : @param $title of document
 : @param $authors of document
 : @param $pages paged contents of ebook
 :
 : @return <book/> node
:)
declare function scriba:create-book($lang as xs:string, $title as xs:string, $authors as node(), $pages as node()) {
            
     <book version="1.0">
        <metadata>
            {scriba:add-title($title)}    
            {scriba:add-authors($authors)}
            <metaitem eletype="dc" elename="language">{$lang}</metaitem>
            <metaitem eletype="dc" elename="identifier" id="bungenibookid">bungeniId</metaitem>
            <metaitem eletype="dc" elename="subject">Legislation</metaitem>
            <metaitem eletype="dc" elename="date">%date%</metaitem>
            <metaitem eletype="meta" elename="meta" name="cover" content="cover-image" destination="opf"/>        
            <metaitem eletype="meta" elename="meta" name="copyright" content="Bungeni Parliament" destination="opf"/>
            <metaitem eletype="meta" elename="meta" name="dtb:uid" content="bungeniId" destination="ncx"/>
            <metaitem eletype="meta" elename="meta" name="dtb:depth" content="1" destination="ncx"/>
            <metaitem eletype="meta" elename="meta" name="dtb:totalPageCount" content="{count($pages/page)}" destination="ncx"/>
            <metaitem eletype="meta" elename="meta" name="dtb:maxPageNumber" content="{count($pages/page)}" destination="ncx"/>
        </metadata>{
            
            scriba:generate-content($pages)   
            
    }</book>
};

(:~
 : Add escapes the node given for scriba not to complain
 :
 : @param $noded item node
 :
 : @return node with escape content
:)
declare function scriba:escapee($noded as node()) {
    
    let $stylesheet := cmn:get-xslt("escape-xml.xsl")    
    let $doc := <div>
                    {transform:transform($noded,$stylesheet,())}
                </div>
    return 
        $doc

};