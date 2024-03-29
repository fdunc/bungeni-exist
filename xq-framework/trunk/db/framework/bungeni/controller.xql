xquery version "3.0";

(:~

The XQ-framework allows switching controllers between applications using the framework.

The only editable part of this file is the URI to the appcontroller module 

:)


declare namespace exist = "http://exist.sourceforge.net/NS/exist";

(:~
config module - this may need to be customized per module
:)
import module namespace config = "http://bungeni.org/xquery/config" at "../config.xqm";
(:~
app controller module - switch between applications by switching  appcontroller modules 
:)


(:~

Change the path to the appcontroller to the appcontroller of your application  

:)
import module namespace appcontroller = "http://bungeni.org/xquery/appcontroller" at "appcontroller.xqm";
import module namespace cmn = "http://exist.bungeni.org/cmn" at "../common.xqm";
import module namespace functx = "http://www.functx.com" at "../functx.xqm";

(: xhtml 1.1 :)
(:
declare option exist:serialize "media-type=text/html method=xhtml doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd";
:)
declare option exist:serialize "media-type=text/html method=xhtml";

(:~
The below are explained here :

http://www.exist-db.org/urlrewrite.html#d1830e343

:)
declare variable $exist:path external;
declare variable $exist:root external;
declare variable $exist:controller external;

(: The REL-PATH variable :)
declare variable $REL-PATH := fn:concat($exist:root, '/', $exist:controller);

let $CHAMBER-REL-PATH := "/" || substring-after(functx:replace-first($exist:path,"/",""),"/")
let $TYPE := substring-before(functx:replace-first($exist:path,"/",""),"/")
let $BICAMERAL := if(count(cmn:get-parl-config()/parliaments/parliament[status/text() = 'active']) > 1) then true() else false()
let $PARLIAMENT := if($CHAMBER-REL-PATH eq "/") then
                        cmn:get-parl-config()/parliaments/parliament[type/text() eq $exist:resource][1] 
                    else
                        cmn:get-parl-config()/parliaments/parliament[type/text() eq $TYPE][1]
(:let $PARLIAMENT := if ($PARL) then
                         $PARL
                    else
                         cmn:get_parl_config()/parliaments/legislature:)
let $ret := appcontroller:controller(
                $exist:path, 
                $PARLIAMENT,
                $BICAMERAL,
                $CHAMBER-REL-PATH,
                $exist:root, 
                $exist:controller, 
                $exist:resource,
                $REL-PATH
            ) return $ret