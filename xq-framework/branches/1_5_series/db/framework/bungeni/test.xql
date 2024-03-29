xquery version "1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace bun = "http://exist.bungeni.org/bun" at "bungeni.xqm";
declare namespace bu="http://portal.bungeni.org/1.0/";
declare option exist:serialize "method=xhtml media-type=text/html indent=no";

let $getqrystr := xs:string(request:get-query-string())

return 
bun:generate-qry-str($getqrystr)