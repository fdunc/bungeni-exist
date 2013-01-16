xquery version "3.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace transform = "http://exist-db.org/xquery/transform";

import module namespace appconfig = "http://exist-db.org/apps/configmanager/config" at "../modules/appconfig.xqm";



declare option exist:serialize "method=xhtml media-type=text/xml";

let $CXT := request:get-context-path()
let $DOCNAME := xs:string(request:get-parameter("doc","none"))
let $REST-CXT-MODELTMPL := $CXT || "/rest" || $appconfig:ROOT || "/model_templates"
let $REST-CXT-CONFIGWF := $CXT || "/rest" || $appconfig:WF-FOLDER
let $NODENAME := xs:string(request:get-parameter("node","nothing"))
let $ATTR := xs:string(request:get-parameter("attr","nothing"))
let $SHOWING := xs:string(request:get-parameter("tab","fields"))
return
<html   xmlns="http://www.w3.org/1999/xhtml"
        xmlns:xf="http://www.w3.org/2002/xforms"
        xmlns:exist="http://exist.sourceforge.net/NS/exist"
        xmlns:ev="http://www.w3.org/2001/xml-events" 
        xmlns:zope="http://namespaces.zope.org/zope"
        xmlns:db="http://namespaces.objectrealms.net/rdb">
   <head>
      <title>Edit Database</title>
    </head>
    <body class="nihilo InlineBordersAlert">
    	<div id="xforms">
            <div style="display:none">
                <xf:model>
                    <xf:instance id="i-workflowui" src="{$REST-CXT-CONFIGWF}/{$DOCNAME}"/>                   

                    <xf:instance id="i-conditions" xmlns="">
                        <data>
                            <conditions>
                               <condition>pi_has_signatories</condition>
                               <condition>user_is_context_owner</condition>    
                               <condition>is_scheduled</condition>
                               <condition>is_written_response</condition>
                               <condition>response_allow_submit</condition>
                               <condition>pi_signatories_check</condition>
                            </conditions>
                        </data>
                    </xf:instance>

                    <xf:bind nodeset="transition[{$ATTR}]">
                        <xf:bind id="b-title" nodeset="@title" type="xf:string" required="true()" constraint="string-length(.) &gt; 3" />
                        <xf:bind id="b-order" nodeset="@order" type="xf:integer" required="true()" constraint="(. &lt; 100) and (. &gt; 0)" />
                        <xf:bind nodeset="@trigger" type="xf:string" required="true()" />
                        <xf:bind nodeset="@require_confirmation" type="xf:boolean" required="true()" />
                    </xf:bind>

                    <xf:instance id="i-controller" src="{$REST-CXT-MODELTMPL}/controller.xml"/>

                    <xf:instance id="tmp">
                        <data xmlns="">
                            <wantsToClose>false</wantsToClose>
                        </data>
                    </xf:instance>
                    
                    <xf:submission id="s-add" method="put" replace="none" ref="instance()">
                        <xf:resource value="'{$REST-CXT-CONFIGWF}/{$DOCNAME}'"/>
    
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
                            <xf:message level="ephemeral">Workflow changes updated successfully</xf:message>
                            <script type="text/javascript" if="instance('tmp')/wantsToClose">
                                dijit.byId("taskDialog").hide();  
                                dojo.publish('/view',['state','{$DOCNAME}','{$NODENAME}','{$ATTR}','none']);
                            </script>
                        </xf:action>
    
                        <xf:action ev:event="xforms-submit-error" if="instance('i-controller')/error/@hasError='true'">
                            <xf:setvalue ref="instance('i-controller')/error/@hasError" value="'true'"/>
                            <xf:setvalue ref="instance('i-controller')/error" value="event('response-reason-phrase')"/>
                        </xf:action>
    
                        <xf:action ev:event="xforms-submit-error" if="instance('i-controller')/error/@hasError='false'">
                            <xf:message>The workflow information have not been filled in correctly</xf:message>
                        </xf:action>
                    </xf:submission>

                    <xf:action ev:event="xforms-ready" >
                        <script type="text/javascript" if="'{$SHOWING}' != 'none'">
                            dijit.byId("switchDiv").selectChild("{$SHOWING}");                        
                        </script>   
                    </xf:action>
                </xf:model>
            </div>    	
            <div style="width: 100%; height: 100%;">
                <h1>Types / {$DOCNAME} / workflow / transition</h1>
                <br/>
                <a href="javascript:dojo.publish('/workflow/view',['{$DOCNAME}','workflow','statesDiv']);">
                    <img src="images/back_arrow.png" title="back to workflow states" alt="back to workflow states"/>
                </a>
                <div style="width: 100%;">
                    <br/>
                    <div style="width: 100%;">
                        <xf:group ref="transition[{$ATTR}]" appearance="bf:verticalTable">                                 
                            <xf:input id="transition-id" bind="b-title">
                                <xf:label>Transition Title</xf:label>
                                <xf:hint>edit id of the workflow</xf:hint>
                                <xf:help>... and no spaces in between words</xf:help>
                                <xf:alert>enter more than 3 characters...</xf:alert>
                            </xf:input> 
                            <xf:input bind="b-order">
                                <xf:label>Order</xf:label>
                                <xf:hint>ordering used on display</xf:hint>
                                <xf:alert>Invalid number.</xf:alert>
                                <xf:help>Enter an integer between 1 and 100 </xf:help>    
                                <xf:message ev:event="xforms-valid" level="ephemeral">Order is valid.</xf:message>                                
                            </xf:input>                              
                            <xf:select1 ref="@condition" appearance="minimal" incremental="true">
                                <xf:label>Condition</xf:label>
                               <xf:hint>where to derive permissions for state</xf:hint>
                               <xf:help>select one</xf:help>
                                <xf:itemset nodeset="instance('i-conditions')/conditions/condition">
                                    <xf:label ref="."></xf:label>
                                    <xf:value ref="."></xf:value>
                                </xf:itemset>
                            </xf:select1>                              
                            <xf:input id="transition-confirm" ref="@require_confirmation">
                                <xf:label>Require confirmation</xf:label>
                                <xf:hint>support confirmation when making a transition</xf:hint>
                            </xf:input>   
                            <xf:select1 ref="@trigger" appearance="minimal" incremental="true">
                                <xf:label>Triggered</xf:label>
                                <xf:hint>how this transition is triggered</xf:hint>
                                <xf:help>select one</xf:help>
                                <xf:item>
                                    <xf:label>by system</xf:label>
                                    <xf:value>system</xf:value>
                                </xf:item>
                                <xf:item>
                                    <xf:label>manually</xf:label>
                                    <xf:value>manual</xf:value>
                                </xf:item>
                                <xf:item>
                                    <xf:label>automatically</xf:label>
                                    <xf:value>automatic</xf:value>
                                </xf:item>                                
                            </xf:select1>                             
                            <xf:select1 ref="@permissions_from_state" appearance="minimal" incremental="true">
                                <xf:label>Permission from state</xf:label>
                               <xf:hint>where to derive permissions for state</xf:hint>
                               <xf:help>select one</xf:help>
                                <xf:itemset nodeset="instance()/state/@id">
                                    <xf:label ref="."></xf:label>
                                    <xf:value ref="."></xf:value>
                                </xf:itemset>
                            </xf:select1>           

                            <xf:group appearance="bf:verticalTable">
                                <xf:label>destinations</xf:label>
                                <xf:repeat id="r-destinations" nodeset="destinations/destination" appearance="compact">
                                    <xf:select1 ref="." appearance="minimal" incremental="true">
                                        <xf:itemset nodeset="instance()/state/@id">
                                            <xf:label ref="."></xf:label>
                                            <xf:value ref="."></xf:value>
                                        </xf:itemset>
                                    </xf:select1> 
                                    <xf:trigger>
                                        <xf:label>insert</xf:label>
                                        <xf:action>
                                            <xf:insert nodeset="."></xf:insert>
                                        </xf:action>
                                    </xf:trigger>
                                    <xf:trigger>
                                        <xf:label>delete</xf:label>
                                        <xf:action>
                                            <xf:delete nodeset="."  ev:event="DOMActivate"></xf:delete>
                                        </xf:action>
                                    </xf:trigger>                                        
                                </xf:repeat>
                            </xf:group>                           
                            
                            <xf:trigger>
                                <xf:label>Save</xf:label>
                                <xf:action>
                                    <xf:setvalue ref="instance('tmp')/wantsToClose" value="'true'"/>
                                    <xf:send submission="s-add"/>
                                </xf:action>                                
                            </xf:trigger>                            
                        </xf:group>
                    </div>
                
                </div>
            </div>                    
        </div>
    </body>
</html>