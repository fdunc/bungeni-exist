xquery version "3.0";

module namespace appcontroller = "http://bungeni.org/xquery/appcontroller";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace xh = "http://www.w3.org/1999/xhtml";

(:~
eXist Imports
:)
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace util = "http://exist-db.org/xquery/util";

(:~
Framework Imports
:)
import module namespace config = "http://bungeni.org/xquery/config" at "../config.xqm";
import module namespace template = "http://bungeni.org/xquery/template" at "../template.xqm";
import module namespace fw = "http://bungeni.org/xquery/fw" at "../fw.xqm";

(:~
Application imports
:)
import module namespace bun = "http://exist.bungeni.org/bun" at "bungeni.xqm";
import module namespace rou = "http://exist.bungeni.org/rou" at "route.xqm";
import module namespace cmn = "http://exist.bungeni.org/cmn" at "../common.xqm";

(:~
All applications using the XQ framework must implement the appcontroller namespace module with the function 
called appcontroller:controller() in the same pattern as below
:)
declare function appcontroller:controller($EXIST-PATH as xs:string, 
                                $EXIST-ROOT as xs:string, 
                                $EXIST-CONTROLLER as xs:string, 
                                $EXIST-RESOURCE as xs:string, 
                                $REL-PATH as xs:string) {
        if ($EXIST-PATH eq "" ) then
        	fw:redirect(fn:concat(request:get-uri(), "/"))
        else if($EXIST-PATH eq "/" or $EXIST-PATH eq "/home" or $EXIST-PATH eq "/index.xml") 
             then
        	   rou:get-home(
        		  $EXIST-PATH , 
                  $EXIST-ROOT , 
                  $EXIST-CONTROLLER, 
                  $EXIST-RESOURCE, 
                  $REL-PATH
                  )
                  
    	(: GLUE-SERVICE :)
    	else if ($EXIST-PATH eq "/check-update" )
    		 then 
                let $docuri := xs:string(request:get-parameter("uri","")), 
                    $statusdate := xs:string(request:get-parameter("t","")),
                    $check-up-results :=  bun:check-update($docuri,$statusdate)
                return $check-up-results        
                  
    	(: LANGUAGE-SETTER :)
    	else if ($EXIST-PATH eq "/switch")
    		 then (
                template:set-lang(),
                fw:redirect-rel($EXIST-PATH, request:get-header("Referer"))
            )
            
        (: for attachment downloads :)
    	else if ($EXIST-PATH eq "/download" )
    		 then 
                let $docuri := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $attid := xs:string(request:get-parameter("att",$bun:DOCNO)),
                    $act-entries-tmpl :=  bun:get-attachment("public-view",$docuri,$attid)
                return $act-entries-tmpl
                    
    	(: Now we process application requests :)
    	else if ($EXIST-PATH eq "/business")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $act-entries-tmpl :=  bun:get-sittings($offset,$limit,$qry,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("business.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    								        $REL-PATH, 
    								        $EXIST-PATH, 
    								        $config:DEFAULT-TEMPLATE,
    								        cmn:get-route($EXIST-PATH),
    								        (),
    								        (cmn:build-nav-node($EXIST-PATH,(template:merge($EXIST-PATH, $act-entries-repl, bun:get-listing-search-context($EXIST-PATH,"listing-search-form.xml",'whatson')))))
    								    ) 
               
        else if ($EXIST-PATH eq "/members")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $act-entries-tmpl :=  bun:get-members($offset,$limit,$qry,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("members.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    								        $REL-PATH, 
    								        $EXIST-PATH, 
    								        $config:DEFAULT-TEMPLATE,
    								        cmn:get-route($EXIST-PATH),
    								        (),
    								        (cmn:build-nav-node($EXIST-PATH,
    								                    (template:merge($EXIST-PATH, 
    								                    $act-entries-repl, 
    								                    bun:get-listing-search-context($EXIST-PATH,"listing-search-form.xml",'membership')
    								                   ))))
    								    )                  
               
        (:~ Handlers for business submenu :)
    	else if ($EXIST-PATH eq "/committees")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $act-entries-tmpl :=  bun:get-committees($offset,$limit,$qry,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("committees.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    								        $REL-PATH, 
    								        $EXIST-PATH, 
    								        $config:DEFAULT-TEMPLATE,
    								        cmn:get-route($EXIST-PATH),
    								        (),
    								        (cmn:build-nav-node($EXIST-PATH,(template:merge($EXIST-PATH, $act-entries-repl, bun:get-listing-search-context($EXIST-PATH,"listing-search-form.xml",'committee')))))
    								    )  
                    
        (:~ ITEM LISTINGS :)        
    	else if ($EXIST-PATH eq "/bills")
    		 then 
    		 rou:get-bills($EXIST-PATH, 
                    $EXIST-ROOT, 
                    $EXIST-CONTROLLER, 
                    $EXIST-RESOURCE, 
                    $REL-PATH)

    	else if ($EXIST-PATH eq "/questions")
    		 then 
                 rou:get-questions(
                    $EXIST-PATH, 
                    $EXIST-ROOT, 
                    $EXIST-CONTROLLER, 
                    $EXIST-RESOURCE, 
                    $REL-PATH
                    )
                    
    	else if ($EXIST-PATH eq "/motions")
    		 then 
                 rou:get-motions(
                    $EXIST-PATH, 
                    $EXIST-ROOT, 
                    $EXIST-CONTROLLER, 
                    $EXIST-RESOURCE, 
                    $REL-PATH
                    )
                    
    	else if ($EXIST-PATH eq "/tableddocuments")
    		 then 
                 rou:get-tableddocuments(
                    $EXIST-PATH, 
                    $EXIST-ROOT, 
                    $EXIST-CONTROLLER, 
                    $EXIST-RESOURCE, 
                    $REL-PATH
                    ) 
                    
    	else if ($EXIST-PATH eq "/agendaitems")
    		 then 
                 rou:get-agendaitems(
                    $EXIST-PATH, 
                    $EXIST-ROOT, 
                    $EXIST-CONTROLLER, 
                    $EXIST-RESOURCE, 
                    $REL-PATH
                    )                     
    				
        (:~ ITEMS SEARCH :)     
 	    else if ($EXIST-PATH eq "/search-all")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $scope := xs:string(request:get-parameter("scope",'global')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $acl := "public-view",
                    $act-entries-tmpl :=  bun:search-global($acl,$offset,$limit,$qry,$scope,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("questions.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    									       $REL-PATH, 
    									       $EXIST-PATH, 
    									       $config:DEFAULT-TEMPLATE,
    									       cmn:get-route($EXIST-PATH),
    									       (),
    									       (cmn:build-nav-node($EXIST-PATH,
    									           (template:merge($EXIST-PATH, 
    									               $act-entries-repl, 
    									               bun:get-global-search-context($EXIST-PATH, 
    									                   "global-search-form.xml",
    									                   $scope))))
    									     )
    								    )    
    	else if ($EXIST-PATH eq "/search-settings")
    		 then 
               template:process-tmpl(
                $REL-PATH, 
                $EXIST-PATH, 
                $config:DEFAULT-TEMPLATE, 
                cmn:get-route($EXIST-PATH),
                (),
                cmn:build-nav-tmpl($EXIST-PATH, "search-settings.xml")
               )     								    
    	else if ($EXIST-PATH eq "/advanced-search")
    		 then 
               template:process-tmpl(
                $REL-PATH, 
                $EXIST-PATH, 
                $config:DEFAULT-TEMPLATE, 
                cmn:get-route($EXIST-PATH),
                (),
                cmn:rewrite-tmpl($EXIST-PATH, bun:get-advanced-search-context($EXIST-PATH,"advanced-search.xml"))
               ) 
        else if ($EXIST-PATH eq "/search-adv")
    		 then 
                let 
                    $qryall := xs:string(request:get-parameter("qa",'')),
                    $qryexact := xs:string(request:get-parameter("qe",'')),
                    $qryhas := xs:string(request:get-parameter("qh",'')),
                    
                    (: accepts a sequence of parent types as request :)
                    $parenttypes := request:get-parameter("types",()),                    
                    (: accepts a sequence of document types as request :)
                    $doctypes := request:get-parameter("docs",()),
                    
                    $override_path := xs:string(request:get-parameter("exist_path","/search-adv")),
                    $status := xs:string(request:get-parameter("std","")),
                    $startdate := xs:string(request:get-parameter("sd",())),  
                    $enddate := xs:string(request:get-parameter("ed",())),
                    $sortby := xs:string(request:get-parameter("sort",$bun:SORT-BY)),
                    
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    
                    $acl := "public-view",
                    $act-entries-tmpl :=  bun:advanced-search($qryall,
                                                            $qryexact,
                                                            $qryhas,
                                                            $parenttypes,                                                            
                                                            $doctypes,
                                                            $offset,
                                                            $limit,
                                                            $status,
                                                            $startdate,
                                                            $enddate,
                                                            $sortby),
    		        $act-entries-repl := document {
    									   template:copy-and-replace($EXIST-PATH, fw:app-tmpl("questions.xml")/xh:div, $act-entries-tmpl)
                                        } 
                                        return 
                                        template:process-tmpl(
                                               $REL-PATH, 
                                               $EXIST-PATH, 
                                               $config:DEFAULT-TEMPLATE,
                                               cmn:get-route($override_path),
                                               (),
                                               cmn:build-nav-node($override_path,$act-entries-repl)
                                        )              
        else if ($EXIST-PATH eq "/search")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    (: 
                        $scope is either global or listing - Let's us know which search form 
                        has been called to action.
                    :)
                    $scope := xs:string(request:get-parameter("scope",'listing')),
                    $type := xs:string(request:get-parameter("type",'bill')),
                    (:
                      override_path : For the search we want to override the automatic 
                      navigation rendering based on routes. So the search form, embeds 
                      a navigation context as a hidden input field. The hidden input 
                      field captures the origin search context e.g. if the search is being
                      done from a listing for a question. 
                      
                      So we use override_path instead of EXIST-PATH only in the context
                      of rendering the navigation correctly, and not in other cases e.g 
                      copy-and-replace or process-tmpl where the EXIST-PATH is used for 
                      rendering the correct template.
                      
                      Hence we use override_path only for build-nav-node() and get-route()
                      to re-route the navigation.
                    :)
                    $override_path := xs:string(request:get-parameter("exist_path","/search")),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $acl := "public-view",
                    $act-entries-tmpl :=  bun:search-criteria($acl,$offset,$limit,$qry,$sty,$type),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("questions.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    									       $REL-PATH, 
    									       $EXIST-PATH, 
    									       $config:DEFAULT-TEMPLATE,
    									       cmn:get-route($override_path),
    									       (),
    									       (cmn:build-nav-node($override_path,
    									           (template:merge($EXIST-PATH, 
    									               $act-entries-repl, 
    									               bun:get-listing-search-context($override_path, 
    									                   "listing-search-form.xml",
    									                   $type))))
    									     )
    								    )
               

        (:~
            Atom FEEDS
        :)    								 
    	else if ($EXIST-PATH eq "/bills/rss")
    		 then 
                let
                    $act-entries-tmpl :=  bun:get-atom-feed("public-view", "bill","user")
                    return $act-entries-tmpl
    	else if ($EXIST-PATH eq "/questions/rss")
    		 then 
                let
                    $act-entries-tmpl :=  bun:get-atom-feed("public-view","question","user")
                    return $act-entries-tmpl    
    	else if ($EXIST-PATH eq "/motions/rss")
    		 then 
                let
                    $act-entries-tmpl :=  bun:get-atom-feed("public-view", "motion","user")
                    return $act-entries-tmpl                     
    	else if ($EXIST-PATH eq "/tableddocuments/rss")
    		 then 
                let
                    $act-entries-tmpl :=  bun:get-atom-feed("public-view", "tableddocument","user")
                    return $act-entries-tmpl  
    	else if ($EXIST-PATH eq "/agendaitems/rss")
    		 then 
                let
                    $act-entries-tmpl :=  bun:get-atom-feed("public-view", "agendaitem","user")
                    return $act-entries-tmpl                    
            
        (: PDF FO GENERATORS :)
    	else if ($EXIST-PATH eq "/bill/pdf")   
    		 then 
                rou:get-pdf($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)
    	else if ($EXIST-PATH eq "/question/pdf")   
    		 then 
                rou:get-pdf($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)    
    	else if ($EXIST-PATH eq "/motion/pdf")   
    		 then 
                rou:get-pdf($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)  
    	else if ($EXIST-PATH eq "/tableddocument/pdf")   
    		 then 
                rou:get-pdf($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)  
    	else if ($EXIST-PATH eq "/agendaitem/pdf")   
    		 then 
                rou:get-pdf($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)                             
    	else if ($EXIST-PATH eq "/member/pdf")   
    		 then 
                let $memid := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $act-entries-tmpl :=  bun:gen-member-pdf($memid)
                return $act-entries-tmpl                           
          
        (:Get AkomaNtoso XML:)
    	else if ($EXIST-PATH eq "/bill/xml")   
    		 then 
                rou:get-xml($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)    
    	else if ($EXIST-PATH eq "/question/xml")   
    		 then 
                rou:get-xml($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)
    	else if ($EXIST-PATH eq "/motion/xml")   
    		 then 
                rou:get-xml($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH) 
    	else if ($EXIST-PATH eq "/tableddocument/xml")   
    		 then 
                rou:get-xml($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)
    	else if ($EXIST-PATH eq "/agendaitem/xml")   
    		 then 
                rou:get-xml($EXIST-PATH, 
                            $EXIST-ROOT, 
                            $EXIST-CONTROLLER, 
                            $EXIST-RESOURCE, 
                            $REL-PATH)                             

    	else if ($EXIST-PATH eq "/politicalgroups")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $act-entries-tmpl :=  bun:get-politicalgroups($offset,$limit,$qry,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("committees.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    								        $REL-PATH, 
    								        $EXIST-PATH, 
    								        $config:DEFAULT-TEMPLATE,
    								        cmn:get-route($EXIST-PATH),
    								        (),
    								        (cmn:build-nav-node($EXIST-PATH,(template:merge($EXIST-PATH, $act-entries-repl, bun:get-listing-search-context($EXIST-PATH, "listing-search-form.xml",'politicalgroup')))))
    								    )
    	else if ($EXIST-PATH eq "/politicalgroup/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-group("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 ) 
    	else if ($EXIST-PATH eq "/ministry/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-group("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )     									 
    	else if ($EXIST-PATH eq "/politicalgroup/members" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-group("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )
    	else if ($EXIST-PATH eq "/politicalgroup/contacts" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl := bun:get-contacts-by-uri("public-view","Group",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )    									 
    	else if ($EXIST-PATH eq "/committee/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-group("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )    
    	else if ($EXIST-PATH eq "/committee/members" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-group("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )
    	else if ($EXIST-PATH eq "/committee/assigned-items" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-assigned-items($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )      
    	else if ($EXIST-PATH eq "/committee/sittings" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-assigned-items($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 ) 
    	else if ($EXIST-PATH eq "/committee/staff" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-assigned-items($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )     	
    	else if ($EXIST-PATH eq "/committee/contacts" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-assigned-items($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )     									 
    								    
    	else if ($EXIST-PATH eq "/bill/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )
    	else if ($EXIST-PATH eq "/bill/version/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )    									 
    									 
    	else if ($EXIST-PATH eq "/bill/timeline" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),      
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl := bun:get-parl-doc-timeline("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )  									 
    									 
    	else if ($EXIST-PATH eq "/bill/assigned-groups" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )    									 
    									 
    	else if ($EXIST-PATH eq "/bill/details" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)  									
    									
    	else if ($EXIST-PATH eq "/bill/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),      
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)   
    	else if ($EXIST-PATH eq "/bill/version/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),      
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)     	
    	else if ($EXIST-PATH eq "/bill/event" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-event($docnumber,$parts),
                    $act-entries-repl:= document {
                                        template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
                                    }
                                    return
                                        template:process-tmpl(
                                            $REL-PATH,
                                            $EXIST-PATH,
                                            $config:DEFAULT-TEMPLATE,
                                            cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>,
                                            cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
                                        )    
    	else if ($EXIST-PATH eq "/question/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>,
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/question/version/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),       
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>,    									   
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    									
    	else if ($EXIST-PATH eq "/question/timeline" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc-timeline("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)  									
    	else if ($EXIST-PATH eq "/question/details" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),       
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )     									
    	else if ($EXIST-PATH eq "/question/assigned-groups" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    	else if ($EXIST-PATH eq "/question/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/question/version/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),      
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    
    	else if ($EXIST-PATH eq "/question/event" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-event($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    									
    									
    	else if ($EXIST-PATH eq "/motion/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),   
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/motion/version/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),    
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    									
    	else if ($EXIST-PATH eq "/motion/timeline" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),    
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc-timeline("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)  									
    									
    	else if ($EXIST-PATH eq "/motion/version" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 ) 								
    									
    	else if ($EXIST-PATH eq "/motion/details" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/motion/assigned-groups" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),    
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/motion/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/motion/version/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    	else if ($EXIST-PATH eq "/motion/event" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),   
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-event($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)       									
    									
    	else if ($EXIST-PATH eq "/tableddocument/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/tableddocument/version/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									) 									
    									
    	else if ($EXIST-PATH eq "/tableddocument/timeline" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc-timeline("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/tableddocument/details" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)  									
    									
    	else if ($EXIST-PATH eq "/tableddocument/assigned-groups" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),    
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/tableddocument/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )
    									 
    	else if ($EXIST-PATH eq "/tableddocument/version" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 ) 
    	else if ($EXIST-PATH eq "/tableddocument/event" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-event($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)  
        (: AGENDA ITEMS :)
    	else if ($EXIST-PATH eq "/agendaitem/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),             
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/agendaitem/version/text" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),  
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									) 									
    									
    	else if ($EXIST-PATH eq "/agendaitem/timeline" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),   
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc-timeline("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/agendaitem/details" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)    									
    									
    	else if ($EXIST-PATH eq "/agendaitem/assigned-groups" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/agendaitem/documents" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),       
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-doc("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )
    									 
    	else if ($EXIST-PATH eq "/agendaitem/version" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-ver("public-view", $docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 ) 
    	else if ($EXIST-PATH eq "/agendaitem/event" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),        
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-doc-event($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									) 
        (: SITTINGS :)    									
    	else if ($EXIST-PATH eq "/sitting" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $act-entries-tmpl :=  bun:get-sitting("public-view",$docnumber,"sitting.xsl"),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("sitting.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )  
    	else if ($EXIST-PATH eq "/get-sittings-json" )
    		 then 
                let $act-entries-tmpl :=  bun:get-sittings-json("public-view")
                    return $act-entries-tmpl
                    
        (:~ MEMBER INFORMATION :)
    
    	else if ($EXIST-PATH eq "/member" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-member($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    	else if ($EXIST-PATH eq "/member/personal-info" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),     
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-member($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									) 
    	else if ($EXIST-PATH eq "/member/offices-held" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),   
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-member($docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)       									

    	else if ($EXIST-PATH eq "/member/parl-activities" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)), 
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-parl-activities("public-view",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)
    									
    	else if ($EXIST-PATH eq "/member/contacts" )
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),           
                    $parts := cmn:get-view-parts($EXIST-PATH),
                    $act-entries-tmpl :=  bun:get-contacts-by-uri("public-view","Membership",$docnumber,$parts),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl($parts/template)/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE,
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									)	
    	else if ($EXIST-PATH eq "/whatson")
    		 then 
                let 
                    $qry := xs:string(request:get-parameter("q",'')),
                    $sty := xs:string(request:get-parameter("s",$bun:SORT-BY)),
                    $offset := xs:integer(request:get-parameter("offset",$bun:OFF-SET)),
                    $limit := xs:integer(request:get-parameter("limit",$bun:LIMIT)),
                    $act-entries-tmpl :=  bun:get-sittings($offset,$limit,$qry,$sty),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("whatson.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    								    template:process-tmpl(
    								        $REL-PATH, 
    								        $EXIST-PATH, 
    								        $config:DEFAULT-TEMPLATE,
    								        cmn:get-route($EXIST-PATH),
    								        (),
    								        (cmn:build-nav-node($EXIST-PATH,(template:merge($EXIST-PATH, $act-entries-repl, bun:get-listing-search-context($EXIST-PATH,"listing-search-form.xml",'whatson')))))
    								    )     									
    	else if ($EXIST-PATH eq "/calendar")
    		 then 
                let 
                    $docnumber := xs:string(request:get-parameter("uri",$bun:DOCNO)),
                    $act-entries-tmpl :=  bun:get-sitting("public-view",$docnumber,"calendar.xsl"),
    		        $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("calendar.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-tmpl(
    									   $REL-PATH, 
    									   $EXIST-PATH, 
    									   $config:DEFAULT-TEMPLATE, 
    									   cmn:get-route($EXIST-PATH),
                                            <route-override>
                                                <xh:title>{data($act-entries-tmpl//xh:div[@id='title-holder'])}</xh:title>
                                            </route-override>, 
    									   cmn:build-nav-node($EXIST-PATH, $act-entries-repl)
    									 )  
    									 
        (:~ UNMAPPED :)			       
        else if ($EXIST-PATH eq "/politicalgroups")
    		 then 
               template:process-tmpl(
                $REL-PATH, 
                $EXIST-PATH, 
                $config:DEFAULT-TEMPLATE, 
                cmn:get-route($EXIST-PATH),(),
                cmn:build-nav-tmpl($EXIST-PATH, "politicalgroups.xml")
               )	     	
    	else if ($EXIST-PATH eq "/publications")
    		 then 
               template:process-tmpl(
                $REL-PATH, 
                $EXIST-PATH, 
                $config:DEFAULT-TEMPLATE, 
                cmn:get-route($EXIST-PATH),
                (),
                cmn:build-nav-tmpl($EXIST-PATH, "publications.xml")
               )  
       else if ($EXIST-PATH eq "/admin") 
            then
               template:process-tmpl(
                   $REL-PATH,
                   $EXIST-PATH,
                   $config:DEFAULT-TEMPLATE,
                   cmn:get-route($EXIST-PATH),
                   (),
                   cmn:build-nav-tmpl($EXIST-PATH, "admin-ui.xml")
                   )
       else if ($EXIST-PATH eq "/preferences")
             then
               fw:redirect-rel($EXIST-PATH, "bungeni/user-config.xql")
       else if ($EXIST-PATH eq "/testing/blue/color") 
              then
                <xml>{request:get-effective-uri()}</xml>
              (:cmn:get-tabgroups("question"):)
               (:
                <xml>
                    <exist-path>{$EXIST-PATH}</exist-path>
                    <exist-controller>{$EXIST-CONTROLLER}</exist-controller>
                    <exist-resource>{$EXIST-RESOURCE}</exist-resource>
                    <exist-root>{$EXIST-ROOT}</exist-root>
                    <exist-relpath>{$REL-PATH}</exist-relpath>                
                </xml>
                :)
    	(:else if ($EXIST-PATH eq "/by-capno")
    		 then 
               let $act-entries-tmpl := bun:get-bills(0,0),
    		       $act-entries-repl:= document {
    									template:copy-and-replace($EXIST-PATH, fw:app-tmpl("acts-list.xml")/xh:div, $act-entries-tmpl)
    								 } 
    								 return 
    									template:process-template($REL-PATH, $EXIST-PATH, $config:DEFAULT-TEMPLATE, (
    										fw:app-tmpl("menu.xml"), 
    										template:merge($EXIST-PATH, fw:app-tmpl("act-list-page.xml"), $act-entries-repl)
    										)
    									) :)                
    	else
            fw:ignore()
};
