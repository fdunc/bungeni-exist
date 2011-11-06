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
: @version 201109122029
:)

xquery version "1.0";

(: Further additions by Ashok Hariharan :)

module namespace template = "http://bungeni.org/xquery/template";

declare namespace xh = "http://www.w3.org/1999/xhtml";
declare namespace pg = "http://bungeni.org/page";

import module namespace config = "http://bungeni.org/xquery/config" at "config.xqm";


(:~
: Merges an XHTML template with XHTML content snippets
:
: @param rel-path
:   Relative path to the URI routing controller
: @param request-rel-path
:   Relative path of this request URI
: @param template-name
:   The name of the template to load from the database and merge
: @param content
:   The XHTML content snippets to merge into the template
:
: @return
:   An XHTML page which is the result of merging the template with the content snippets
:)
declare function template:process-template($rel-path as xs:string, $request-rel-path as xs:string, $template-name as xs:string, $content as node()+) {  (:document-node(element(xh:div))* :)
    let $template := fn:doc(fn:concat($rel-path, "/", $template-name)),
    $div-content := $content/xh:div[@id] | $content/xh:div[not(exists(@id))]/xh:div[@id] 
    (: extracts top level content and content from within an id less container :)
    let $processed-doc := template:copy-and-replace($request-rel-path, $template/xh:html, $div-content)
    return template:process-page-meta($processed-doc)
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
        template:adjust-relative-paths($request-rel-path, $attr)
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

(:~
Extended API added by Ashok
:)

(:~
: Apply the metadata attributes on the page
: 
: @param content
:   XHTML content template
:
: @param page-info
:   The page-info element 
:)
declare function local:set-meta($content as element(), $page-info as element()) as  element() {
    (:~
    Check set the title from the page-info attribute 
    :)

	if ($content/self::xh:title and  $page-info/pg:title) then (
		<title>{$page-info/pg:title/text()}</title>
    )

    (:~ 
    Set the navigation tab to the active one for the page - the condition to determine the active
    tab is slight more involved hence the nested if 
    :)
    (: This condition is for the example template - adjust appropriately :)
	
    else if ($content/ancestor::xh:div[@id="mainnav"] and $content/self::xh:a) then (
			if ($page-info/pg:navigation) then (
				if ($content/self::xh:a[@href=$page-info/pg:navigation/text()]) then (
					<a class="current" href="{$page-info/pg:navigation/text()}">{$page-info/pg:navigation/text()}</a>
				) 
				else  
				 $content
			)
			else
			  $content
	)
	(:~
	Set the subnavigation tab 
    :)
    else if ($content/ancestor::xh:div[@id="subnav"] and $content/self::xh:a) then (
			if ($page-info/pg:subnavigation) then (
				if ($content/self::xh:a[@href=$page-info/pg:subnavigation/text()]) then (
					<a class="current" href="{$page-info/pg:subnavigation/text()}">{$page-info/pg:subnavigation/text()}</a>
				) 
				else  
				 $content
			)
			else
			  $content
	)

	else 
    (:~
     return the default 
     :)
  		element { node-name($content)}
		  		 {$content/@*, 
					for $child in $content/node()
						return if ($child instance of element())
							   then local:set-meta($child, $page-info)
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





declare function template:process-page-meta($doc as element()) as element() {
	(: Get the page info element :)
	let $page-info := $doc//pg:info
	(: Now remove the page namespace from the final document :)
	let $final := template:filter-page-namespace($doc)
    (: For now only the title is specified in page namespace - but this will be expanded
       to support other things :)
	(: Set the title and return the page :)
	(:let $output := template:set-title($final, $page-info/pg:title/text()) :)
	(: For navigation menu to highlight current page :)
	return
		local:set-meta($final, $page-info)
};

