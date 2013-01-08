xquery version "3.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace transform = "http://exist-db.org/xquery/transform";

import module namespace cfg = "http://bungeni.org/xquery/config" at "../config.xqm";

declare option exist:serialize "method=xhtml media-type=text/xml";

declare function local:get-form($docname as xs:string) as node() * {
    doc($cfg:FORMS-COLLECTION || '/' || $docname || '.xml')
};

let $contextPath := request:get-context-path()
let $docname := xs:string(request:get-parameter("doc","nothing"))
let $nodename := xs:string(request:get-parameter("node","nothing"))
let $showing := xs:string(request:get-parameter("tab","fields"))
return
<html   xmlns="http://www.w3.org/1999/xhtml"
        xmlns:xf="http://www.w3.org/2002/xforms"
        xmlns:exist="http://exist.sourceforge.net/NS/exist"
        xmlns:ev="http://www.w3.org/2001/xml-events" 
        xmlns:zope="http://namespaces.zope.org/zope"
        xmlns:db="http://namespaces.objectrealms.net/rdb">
   <head>
      <title>Add Type Database</title>
    </head>
    <body class="nihilo InlineBordersAlert">
    	<div id="xforms">
            <div style="display:none">
                 <xf:model>
                    <xf:instance id="i-type" src="{$contextPath}/rest/db/config_editor/bungeni_custom/types.xml"/>   

                    <xf:instance id="i-typedoc" xmlns="">
                        <data>
                            <doc name="" enabled="false"/>
                        </data>
                    </xf:instance> 

                    <xf:instance id="i-typegroup" xmlns="">
                        <data>
                            <group name="" workflow="group" enabled="false">
                                <member name="member_member" workflow="group_membership" enabled="false"/>
                            </group>
                        </data>
                    </xf:instance>                        

                    <xf:bind nodeset=".">
                        <xf:bind nodeset="@name" type="xf:string" required="true()" />
                        <xf:bind nodeset="@enabled" type="xf:boolean" required="true()"/>
                    </xf:bind>

                    <xf:instance id="i-controller" src="{$contextPath}/rest/db/config_editor/data/controller.xml"/>

                    <xf:instance id="tmp">
                        <data xmlns="">
                            <wantsToClose>false</wantsToClose>
                        </data>
                    </xf:instance>

                <xf:submission id="s-add"
                               method="put"
                               replace="none"
                               ref="instance()">
                    <xf:resource value="'{$contextPath}/rest/db/config_editor/bungeni_custom/types.xml'"/>

                    <xf:header>
                        <xf:name>username</xf:name>
                        <xf:value>admin</xf:value>
                    </xf:header>
                    <xf:header>
                        <xf:name>password</xf:name>
                        <xf:value></xf:value>
                    </xf:header>
                    <xf:header>
                        <xf:name>realm</xf:name>
                        <xf:value>exist</xf:value>
                    </xf:header>

                    <xf:action ev:event="xforms-submit-done">
                        <xf:message level="ephemeral">Type details saved successfully</xf:message>
                        <script type="text/javascript" if="instance('tmp')/wantsToClose">
                            dijit.byId("taskDialog").hide();
                            //dojo.publish('/add',['form','types','doc','none','none']);  
                        </script>
                    </xf:action>

                    <xf:action ev:event="xforms-submit-error" if="instance('i-controller')/error/@hasError='true'">
                        <xf:setvalue ref="instance('i-controller')/error/@hasError" value="'true'"/>
                        <xf:setvalue ref="instance('i-controller')/error" value="event('response-reason-phrase')"/>
                    </xf:action>

                    <xf:action ev:event="xforms-submit-error" if="instance('i-controller')/error/@hasError='false'">
                        <xf:message>The form details have not been filled in correctly</xf:message>
                    </xf:action>
                </xf:submission>
                
                <xf:action ev:event="xforms-ready"/>

            </xf:model>
            
            </div>    	
            <div style="width: 100%; height: 100%;">
                <h1>New Type: {$nodename} </h1>
                <xf:group ref="instance('i-type{$nodename}')">
                    <xf:group appearance="bf:verticalTable">
                        <xf:input id="form-name" ref="child::node()/@name">
                            <xf:label>name</xf:label>
                            <xf:hint>Unique name given to the form</xf:hint>
                            <xf:alert>Invalid form name</xf:alert>
                        </xf:input>                           
                        
                        <xf:input id="descriptor-order" ref="child::node()/@enabled">
                            <xf:label>enabled</xf:label>
                            <xf:hint>check to enable</xf:hint>
                        </xf:input>                 
                        
                        <br/>
                        <xf:group id="dialogButtons" appearance="bf:horizontalTable">
                            <xf:label/>
                            <xf:trigger>
                                <xf:label>Add</xf:label>
                                <xf:action if="'{$nodename}' = 'doc'">
                                    <xf:setvalue ref="instance('tmp')/wantsToClose" value="'true'"/>
                                    <xf:insert nodeset="instance()/doc" at="last()" position="after" origin="instance('i-typedoc')/doc" />
                                    <xf:send submission="s-add"/>
                                </xf:action>
                                <xf:action if="'{$nodename}' = 'group'">
                                    <xf:setvalue ref="instance('tmp')/wantsToClose" value="'true'"/>
                                    <xf:insert nodeset="instance()/group" at="last()" position="after" origin="instance('i-typegroup')/group" />
                                    <xf:send submission="s-add"/>
                                </xf:action>                                
                            </xf:trigger>                  
                        </xf:group>
                     </xf:group>
                </xf:group>
                   
            </div>                    
        </div>
    </body>
</html>