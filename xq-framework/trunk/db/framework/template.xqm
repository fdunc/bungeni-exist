(:
 Copyright 2011 Adam Retter

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
:)

(:~
: This module is responsible for merging XHTML
: templates and XHTML snippets together
:
: @author Adam Retter <adam.retter@googlemail.com>
: Modified :
:   ashok.hariharan
:   10-10-2011 - added template metadata processing support
:   07-11-2011 - renamed process-template to process-tmpl and added support for route processing, template
:                metadata processing is deprecated now
:   14-11-2011 - added route-override support to process-tmpl. Some pages like e.g. when vieiwing a specific question
:                set the page title dynamically from the contents of the question - so we cannot use the route title there.
:                such pages can specify a <route-override /> element from the controller. E.g. :
:                   <route-override>
:                       <xh:title>this is a title override</xh:title>
:                   </route-override>
:                will override the title
:)
xquery version "3.0";

(: Further additions by Ashok Hariharan :)

module namespace template = "http://bungeni.org/xquery/template";

declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace pg = "http://bungeni.org/page";

import module namespace config = "http://bungeni.org/xquery/config" at "config.xqm";
import module namespace cmn = "http://exist.bungeni.org/cmn" at "common.xqm";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "i18n.xql";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";


declare variable $template:SERVER-NAME := request:get-server-name();
declare variable $template:SERVER-PORT := request:get-server-port();

(:~
: Merges an XHTML template with XHTML content snippets
: 07-11-2011 - Renamed API to process-tmpl, added support for processing routes
:
: @param rel-path
:   Relative path to the URI routing controller
: @param request-rel-path
:   Relative path of this request URI
: @param template-name
:   The name of the template to load from the database and merge
: @param route-map
:   The node of the route as specified in the appcontroller
: @param route-override
:   The override map for the route map, this is set dynamically from the controller.
:   If its not used pass an empty node : ()
: @param content
:   The XHTML content snippets to merge into the template
:
: @return
:   An XHTML page which is the result of merging the template with the content snippets
: 
:)

declare function template:process-tmpl(
        $rel-path as xs:string, 
        $request-rel-path as xs:string, 
        $template-name as xs:string, 
        $route-map as node(),
        $route-override as node(),
        $content as node()+
        ) {  
    let $template := fn:doc(fn:concat($rel-path, "/", $template-name))
    let $div-content := $content/xh:ul[@id] | $content/xh:div[@id] | $content/xh:div[not(exists(@id))]/xh:div[@id]   
    let $inject-langs := template:merge($request-rel-path, document {$template/xh:html}, document {local:inject-langs()})
    (: extracts top level content and content from within an id less container :)
    let $proc-doc := template:copy-and-replace($request-rel-path, $inject-langs/xh:html, $div-content)
    (: process page meta and return :)
    return 
       (:local:treewalker($template/xh:html):)
       template:process-page-meta($route-map, $route-override, $proc-doc)
};

(:
    Injects language-selector into the template
:)
declare function local:inject-langs() as node() {
    <xh:div id="global-language">
    {
        element xh:ul {
            attribute id { "portal-languageselector" },
            let $langs := cmn:get-langs-config()/languages
            for $lang in $langs/language
            return 
                element li {
                    element a {
                        attribute href { concat("switch?language=",data($lang/@id)) },
                        attribute id { data($lang/@id) },
                        attribute title { data($lang/@english-name) },
                        attribute data-dir { if(xs:boolean(data($lang/@rtl))) then 'rtl' else 'ltr' },
                        data($lang/@display-name)
                    }
                }
        },
        <xh:ul id="portal-personaltools">
            <xh:li/>
        </xh:ul>
    }</xh:div>
};

(:~
: Merges two XHTML templates together
:
: $template2 is merged into $template1
: on the first matching occurence of element QName
: and element with equal 'id' attributes
:
: @param request-rel-path
:   Relative path of this request URI
: @param template1
:   The template to merge into
: @param template2
:   The template to merge
:
: @return
:   An XHTML template which is the merged result of the two templates
:)
declare function template:merge($request-rel-path as xs:string, $template1 as document-node(), $template2 as document-node()?) as document-node() {
    if(empty($template2))then
        $template1
    else
        document {
            template:copy-and-replace($request-rel-path, $template1/element(), $template2/element())
        }
};

(:~
: Identity transform
:
: Copies all nodes from $element, except elements who:
: 1) Have a QName matches a QName from $content, and
: 2) Have an @id attribute which matches that from $content
:
: @param request-rel-path
:   Relative path of this request URI
: @param element
:   The element to perform the identity transform on
: @param content
:   The replacements to be made
:
: @return
:   The transformed result
:)
declare function template:copy-and-replace($request-rel-path as xs:string, $element as element(), $content as element()*) {
  element {node-name($element)} { 
     for $attr in $element/@* return
        template:adjust-absolute-paths($request-rel-path, $attr)
     ,
     for $child in $element/node() return
        if($child instance of element()) then
            
            if($content/node-name(.) = node-name($child) and $child/@id = $content/@id)then
            (: if(node-name($child) = (xs:QName("xh:div"), xs:QName("xh:ul")) and $child/@id = $content/@id)then :)
                template:copy-and-replace($request-rel-path, $content[@id eq $child/@id], ())
            else
                template:copy-and-replace($request-rel-path, $child, $content)
        else
            $child
    }
};

(:~
: Identity transform to rewrite src, href and action attribute URIs
: Used by ePUB bun:gen-epub to makes links absolute.
:
: @param request-rel-path
:   Relative path of this request URI
: @param element
:   ePUB pages which needs to be rewritten with absolute paths
:
: @return
:   The transformed result
:)
declare function template:re-write-paths($request-rel-path as xs:string, $element as element()) {
  element {node-name($element)} {
     for $attr in $element/@* return
        template:adjust-absolute-paths($request-rel-path, $attr)
     ,
     for $child in $element/node() return
        if($child instance of element()) then
            template:re-write-paths($request-rel-path, $child)
        else
            $child
    }
};

(:~
: Rewrites src, href and action attribute URIs
:
: @param request-rel-path
:   Relative path of this request URI
: @param attr
:   The attribute to rewrite the value of
:
: @return
:   The rewritten attribute
:)
declare function template:adjust-relative-paths($request-rel-path as xs:string, $attr as attribute()) as attribute() {
    if(fn:local-name($attr) = ("src", "href", "action") and not(starts-with($attr, "/") or starts-with($attr, "http://") or starts-with($attr, "https://") or starts-with($attr, "../") or starts-with($attr, "#")))then (: starts-with($attr, "../") stops paths being processed more than once :)
            attribute {node-name($attr)} { 
                template:make-relative-uri($request-rel-path, $attr)
            }
        else 
            $attr
};

(:~
: Adjusts a URI to be relative to the $request-rel-path
:
: @param request-rel-path
:   Relative path of this request URI
: @param uri
:   The URI to make relative
:
: @return
:   The relative uri
:)
declare function template:make-relative-uri($request-rel-path as xs:string, $uri as xs:string) as xs:string {
    fn:concat(
        fn:string-join(
            for $sub-path-count in 1 to fn:count(fn:tokenize($request-rel-path, "/")) -2 return
                "../"
            ,
            ""
        ),
        $uri
    )
};

declare function template:adjust-absolute-paths($exist-controller as xs:string, $attr as attribute()) as attribute() {
    if(fn:local-name($attr) = ("src", "href", "action") and not(starts-with($attr, "mailto:") or starts-with($attr, "/") or starts-with($attr, "http://") or starts-with($attr, "https://") or starts-with($attr, "#")))then
            attribute {node-name($attr)} { 
                template:make-absolute-uri($exist-controller, $attr)
            }           
    else 
            $attr
};


(:~
: Adjusts a URI to be relative to the $request-rel-path
:
: @param request-rel-path
:   Relative path of this request URI
: @param uri
:   The URI to make relative
:
: @return
:   The relative uri
:)
declare function template:make-absolute-uri($exist-controller as xs:string, $uri as xs:string) as xs:string {
fn:concat("http://", $template:SERVER-NAME, ":", $template:SERVER-PORT, "/exist/apps", $exist-controller, "/", $uri) 
};


(:~
Extended API added by Ashok
:)

(:~
: Apply the metadata attributes on the page
: 
: @param content
:   XHTML content template
: @param override
:   The route override parameter
: @param page-info
:   The page-info element 
:)
declare function local:set-meta($route as element(), $override as element(), $content as element()) as  element() {
    (:~
    Check set the title from the page-info attribute 
    :)
   
	if ($content/self::xh:title and $route/title) then (
		   <title>{
		   if ($override/xh:title) then 
		      $override/xh:title/text()
		   else
		      $route/title/text()
		   }</title>
    ) 
    (: set body classes :)
    else if ($content/self::xh:body) then (
        element { node-name($content/self::xh:body) } {
        	attribute class { "template-portal-eXist " || $override/parliament/type/text() },
        	attribute  dir { if(cmn:get-langs-config()/languages/language[@id=template:set-lang()]/@rtl) then "rtl" else "ltr" },
        	$content/(@*, *)
        }
	) 
    (:~ 
    Set the navigation tab to the active one for the page - the condition to determine the active
    tab is slight more involved hence the nested if 
    :)
    
    else if ($content/ancestor::xh:div[@id="mainnav"] and $content/self::xh:li) then (
			if ($route/navigation) then (
				(:if ($content/descendant-or-self::xh:li[xh:a/@name = data($route/@href)] and contains(data($route/@href),$override/identifier)) then ( :)
				if ($content/descendant-or-self::xh:li[xh:a/@name = $route/navigation/text()] and contains(data($route/@href),$override/identifier)) then (
				    <xh:li class="active">
				        {$content/self::xh:li/(@*, *)}
				    </xh:li>
				) 
				else  
				    $content
			)
			else
			  $content
	)
    (:~
    Set the sub-navigation tab to the active one as specified in the route
    :)

    else if ($content/ancestor::xh:div[@id eq $override/identifier/text()] and $content/self::xh:li) then (
			if ($route/subnavigation) then (
				if ($content/self::xh:li[xh:a/@name=$route/subnavigation/text()]) then (
				    <xh:li class="selected navigation">
				        <xh:a class="current" href="{$content/xh:a/@href}">{$content/xh:a/i18n:text}</xh:a>
				    </xh:li>
				) 
				else  
				 $content
			)
			else
			  $content
	)
	
	(:~ highlight active lang :)
    else if ($content/ancestor::xh:ul[@id="portal-languageselector"] and $content/self::xh:li) then (
    
            for $anchor in $content/self::xh:li
            return 
    			if ($anchor/xh:a[@id = template:set-lang()]) then (
    			     element li {
    			        attribute class { "selected" }, 
                        $anchor/xh:a
                     }
                )
    			else ( 
    			     element li {
    			         $anchor/xh:a
    			     }   
    			)
	)
	

	else 
    (:~
     return the default 
     :)
  		element { node-name($content)}
		  		 {$content/@*, 
					for $child in $content/node()
						return if ($child instance of element())
							   then local:set-meta($route, $override, $child)
							   else $child
				 }
};


(:~
: Remove the page: namespace
: 
: @param element
:   XML element which contains the page: namespace
:
:)
declare function template:filter-page-namespace(
      $element as element()) as element() {
      element {node-name($element) }
             { $element/@*,
               for $child in $element/node()[not(namespace-uri(.)='http://bungeni.org/page')]
                  return if ($child instance of element())
                    then template:filter-page-namespace($child)
                    else $child
           }
};

(:~
:   Sets the UI language
:)
declare function template:set-lang() {
        if(string-length(request:get-parameter("language","")) gt 0) then 
            response:set-cookie('lang',request:get-parameter("language",""))
            
        else if(string-length(request:get-cookie-value('lang')) gt 0) then
            request:get-cookie-value('lang')                
            
        else    
            $config:DEFAULT-LANG        
};

(:~
: Process the metadata for the page by querying the route map
: Apply i18n translation process
: @param route
:   route map
: @param override
:   The route override parameter
: @param doc
:   The page content being processed by the template 
:)
declare function template:process-page-meta($route as element(), $override as element(), $doc as element()*) as element() {
	let $metazed := local:set-meta($route, $override, $doc)
	return
	   i18n:process($metazed, template:set-lang(), $config:I18N-MESSAGES, $config:DEFAULT-LANG)
};
