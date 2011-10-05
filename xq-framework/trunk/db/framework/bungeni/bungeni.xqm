module namespace bun = "http://exist.bungeni.org/bun";
import module namespace bungenicommon = "http://bungeni.org/pis/common" at "common.xqm";

declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace xh = "http://www.w3.org/1999/xhtml";

(:
Library for common lex functions
uses bungenicommon
:)

(:~
Local Constants
:)
declare variable $bun:PER-PAGE := 5;
declare variable $bun:DEFAULT-PAGE := 1;

(: Search for the doc matching the actid in the parameter and return the document :)
declare function bun:get-doc($actid as xs:string) as element() {
     for $match in collection(bungenicommon:get-lex-db())//akomaNtoso//docNumber[@id='ActIdentifier']
      let $c := string($match)
      where $c = $actid
    return $match/ancestor::akomaNtoso
};

    
(:
declare function lex:paginator($totalcount as xs:integer, $offset as xs:integer, $limit as xs:integer) as element(xh:div) {
<xh:div id="paginator>
{
     return $totalcount

}
<xh:div>
};
:)
declare function bun:paginator($offset as xs:integer) as element()+ {
    for $match in subsequence(collection(bungenicommon:get-lex-db())//akomaNtoso//docNumber[@id='ActIdentifier'],$offset,$bun:PER-PAGE)
    return element xh:li{
 			element xh:a {
                attribute href { fn:concat("?offset=", $bun:DEFAULT-PAGE, "&amp;limit=",$bun:PER-PAGE) },
                "&#160;"
            }
    }
};

declare function bun:get-bills($offset as xs:integer, $limit as xs:integer) as element() {
    
    (: stylesheet to transform :)
    let $stylesheet := bungenicommon:get-xslt("bill-listing.xsl")    
    
    (: input ANxml document in request :)
    let $doc := <docs> 
    <paginator>{bun:paginator($offset)}</paginator>
    {
        for $match in subsequence(collection(bungenicommon:get-lex-db())//akomaNtoso//docNumber[@id='ActIdentifier'],$offset,$bun:PER-PAGE)
        return $match/ancestor::akomaNtoso     
    } 
    </docs>
    
    return
        transform:transform($doc, $stylesheet, ())
       
};  


(: Search for the doc matching the actid in the parameter and return the tabel of contents :)
declare function bun:get-toc($actid as xs:string) as element() {
     for $match in collection(bungenicommon:get-lex-db())//akomaNtoso//docNumber[@id='ActIdentifier']
      let $c := string($match)
      where $c = $actid
    return $match/ancestor::akomaNtoso//preamble/toc
};


declare function bun:get-act($actid as xs:string, $pref as xs:string, $xslt as xs:string) {
    (: First get the act document :)
    let $doc := bun:get-doc($actid),
    (: Next get the doc of the XSLT :)   
     $doc-xslt := bungenicommon:get-xslt($xslt),
    (: Now transform the doc with the XSLT :)
     $doc-transformed := transform:transform($doc, 
		$doc-xslt,
        <parameters>
            <param name="pref" value="{$pref}" />
        </parameters>)
     return $doc-transformed
};