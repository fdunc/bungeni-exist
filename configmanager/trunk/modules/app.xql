xquery version "3.0";

module namespace app="http://exist-db.org/apps/configmanager/templates";
declare namespace xhtml="http://www.w3.org/1999/xhtml" ;
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace ev="http://www.w3.org/2001/xml-events" ;


import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace appconfig = "http://exist-db.org/apps/configmanager/config" at "appconfig.xqm";
import module namespace config = "http://exist-db.org/xquery/apps/config" at "config.xqm";

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with a class attribute: class="app:test". The function
 : has to take exactly 3 parameters.
 : 
 : @param $node the HTML node with the class attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare 
%templates:wrap 
function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};


declare 
function app:get-roles-menu($node as node(), $model as map(*)) {
    <xhtml:div dojoType="dijit.MenuItem" onclick="javascript:dojo.publish('/view',['roles','custom.xml','roles','none','none']);">
    Roles
    </xhtml:div>
};

declare 
function app:get-separator($node as node(), $model as map(*)) {
   <xhtml:div dojoType="dijit.MenuSeparator"/> 
};

declare 
function app:get-system-menu($node as node(), $model as map(*)) {
    <xhtml:div dojoType="dijit.PopupMenuItem"> 
        <xhtml:span>
            System            
        </xhtml:span>                        
        <xhtml:div dojoType="dijit.Menu" id="submenusys">
            <xhtml:div dojoType="dijit.MenuItem" 
                onClick="showDialogAb();document.getElementById('fs_path').focus();">
                store from file-system
            </xhtml:div>
            <xhtml:div dojoType="dijit.MenuItem" onclick="javascript:dojo.publish('/sys/write');">sync back to filesystem</xhtml:div>           
        </xhtml:div>
    </xhtml:div>
};

declare 
function app:input-path($node as node(), $model as map(*)) {
    <xhtml:input dojoType="dijit.form.TextBox" type="text" style="width:120%;"
        id="fs_path" name="fs_path" 
        value="{$appconfig:doc/ce-config/configs[@collection eq 'bungeni_custom']/fs-path/text()}"/>
};

declare 
  %templates:default("active", "search") 
function app:get-types-menu($node as node(), $model as map(*), $active as xs:string) {
     <xhtml:div dojoType="dijit.PopupMenuItem"> 
        <xhtml:span>
            Types            
        </xhtml:span>
        <xhtml:div dojoType="dijit.Menu" id="submenu">       
            <xhtml:div dojoType="dijit.MenuItem" onClick="alert('new!');">add new</xhtml:div>
            <xhtml:div dojoType="dijit.MenuSeparator"/>
            {
                for $docu in doc(concat($appconfig:CONFIGS-FOLDER,'/types.xml'))/types/*
                return    
                    <xhtml:div dojoType="dijit.PopupMenuItem">
                        <xhtml:span>{data($docu/@name)}</xhtml:span>
                        <xhtml:div dojoType="dijit.Menu" id="formsMenu{data($docu/@name)}">
                            <xhtml:div dojoType="dijit.MenuItem" onclick="javascript:dojo.publish('/form/view',['{data($docu/@name)}','details']);">form</xhtml:div>
                            <xhtml:div dojoType="dijit.MenuItem" onclick="javascript:dojo.publish('/workflow/view',['{data($docu/@name)}.xml','workflow','documentDiv']);">workflow</xhtml:div>
                            <xhtml:div dojoType="dijit.MenuItem">workspace</xhtml:div>
                        </xhtml:div>
                    </xhtml:div>
            }      
        </xhtml:div>
     </xhtml:div>      
};

(:

This is the main XFOrms declaration in index.html 

:)
declare function app:xforms-declare($node as node(), $model as map(*)) {
     let $CXT := request:get-context-path()
     let $REST-CXT-VIEWS :=  $CXT || "/rest" || $config:app-root || "/views"
     let $REST-CXT-ACTNS :=  $CXT || "/rest" || $config:app-root || "/doc_actions"
     return      
            <div style="display:none;">
                <xf:model id="modelone">
                    <xf:instance>
                        <data xmlns="">
                            <lastupdate>2000-01-01</lastupdate>
                            <user>admin</user>
                        </data>
                    </xf:instance>

                    <xf:submission id="s-query-workflows"
                                    resource="{$REST-CXT-VIEWS}/about.html"
                                    method="get"
                                    replace="embedHTML"
                                    targetid="embedInline"
                                    ref="instance()"
                                    validate="false">
                        <xf:action ev:event="xforms-submit-done">
                            <xf:message level="ephemeral">Request for about page successful</xf:message>
                        </xf:action>                                    
                        <xf:action ev:event="xforms-submit-error">
                            <xf:message>Submission failed</xf:message>
                        </xf:action>
                    </xf:submission>
                    
                    <xf:instance id="i-vars">
                        <data xmlns="">
                            <default-duration>120</default-duration>
                            <currentTask/>
                            <currentView/>
                            <currentDoc/>
                            <currentNode/>
                            <currentAttr/>
                            <currentField/>
                            <showTab/>
                            <selectedTasks/>
                        </data>
                    </xf:instance>
                    <xf:bind nodeset="instance('i-vars')/default-duration" type="xf:integer"/>

                    <xf:action ev:event="xforms-ready">
                        <xf:message level="ephemeral">Default: show about</xf:message>
                        <xf:action ev:event="xforms-value-changed">
                            <xf:dispatch name="DOMActivate" targetid="overviewTrigger"/>
                        </xf:action>
                    </xf:action>
                </xf:model>

                <xf:trigger id="overviewTrigger">
                    <xf:label>Overview</xf:label>
                    <xf:send submission="s-query-workflows"/>
                </xf:trigger>
                
                <xf:trigger id="storeSys">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/sys-store-custom.xql#xforms?fs_path=',
                            instance('i-vars')/currentDoc
                            )"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger> 
                
                <xf:trigger id="writeSys">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/sys-sync-custom.xql#xforms?fs_path=',
                            instance('i-vars')/currentDoc
                            )"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                
                
                <xf:trigger id="viewForm">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/get-form.xql#xforms?doc=',
                            instance('i-vars')/currentDoc,
                            '&amp;tab=',instance('i-vars')/showTab
                            )"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>   
                
                <xf:trigger id="viewWorkflow">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/get-workflow.xql#xforms?doc=',
                            instance('i-vars')/currentDoc,
                            '&amp;tab=',instance('i-vars')/showTab
                            )"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>         
                
                <xf:trigger id="addPopup">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedDialog">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/add-',
                            instance('i-vars')/currentView,
                            '.xql#xforms?doc=',
                            instance('i-vars')/currentDoc,
                            '&amp;node=',instance('i-vars')/currentNode,
                            '&amp;attr=',instance('i-vars')/currentAttr,
                            '&amp;tab=',instance('i-vars')/showTab
                            )"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                 
                
                <xf:trigger id="editPopup">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedDialog">
                            <xf:resource value="concat(
                            '{$REST-CXT-VIEWS}/edit-',
                            instance('i-vars')/currentView,
                            '.xql#xforms?doc=',
                            instance('i-vars')/currentDoc,
                            '&amp;node=',
                            instance('i-vars')/currentNode,
                            '&amp;attr=',
                            instance('i-vars')/currentAttr,
                            '&amp;tab=',
                            instance('i-vars')/showTab)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>     
                
                <xf:trigger id="view">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat('{$REST-CXT-VIEWS}/get-',instance('i-vars')/currentView,'.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;node=',instance('i-vars')/currentNode,'&amp;attr=',instance('i-vars')/currentAttr,'&amp;tab=',instance('i-vars')/showTab)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                  
                
                <xf:trigger id="addField">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedDialog">
                            <xf:resource value="concat('{$REST-CXT-VIEWS}/add-field.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;field=',instance('i-vars')/currentField,'&amp;mode=new')"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                

                <xf:trigger id="editField">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedDialog">
                            <xf:resource value="concat('{$REST-CXT-VIEWS}/get-field.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;field=',instance('i-vars')/currentField)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>
                
                <xf:trigger id="editRole">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedDialog">
                            <xf:resource value="concat('{$REST-CXT-VIEWS}/edit-role.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;role=',instance('i-vars')/currentNode)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                
                
                <xf:trigger id="moveFieldUp">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat('{$REST-CXT-ACTNS}/move-node.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;move=up&amp;field=',instance('i-vars')/currentField)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger> 
                
                <xf:trigger id="moveFieldDown">
                    <xf:label>new</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat('{$REST-CXT-ACTNS}/move-node.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;move=down&amp;field=',instance('i-vars')/currentField)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>  
                
                <xf:trigger id="deleteField">
                    <xf:label>delete</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat('{$REST-CXT-ACTNS}/delete-node.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;field=',instance('i-vars')/currentField)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>   
                
                <xf:trigger id="deleteRole">
                    <xf:label>delete</xf:label>
                    <xf:action>
                        <xf:load show="embed" targetid="embedInline">
                            <xf:resource value="concat('{$REST-CXT-ACTNS}/delete-role.xql#xforms?doc=',instance('i-vars')/currentDoc,'&amp;field=',instance('i-vars')/currentField)"/>
                        </xf:load>
                    </xf:action>
                </xf:trigger>                    

                <xf:trigger id="deleteTask">
                    <xf:label>delete</xf:label>
                    <xf:send submission="s-delete-workflow"/>
                </xf:trigger>

                <xf:input id="currentTask" ref="instance('i-vars')/currentTask">
                    <xf:label>This is just a dummy used by JS</xf:label>
                </xf:input>
                <xf:input id="currentView" ref="instance('i-vars')/currentView">
                    <xf:label>This is just a hidden used by JS</xf:label>
                </xf:input>                
                <xf:input id="currentDoc" ref="instance('i-vars')/currentDoc">
                    <xf:label>This is just an ephemeral used by JS</xf:label>
                </xf:input>
                <xf:input id="currentNode" ref="instance('i-vars')/currentNode">
                    <xf:label>This is just a dummy placeholder by JS</xf:label>
                </xf:input>
                <xf:input id="currentAttr" ref="instance('i-vars')/currentAttr">
                    <xf:label>This is just a value placeholder by JS</xf:label>
                </xf:input>                
                <xf:input id="currentField" ref="instance('i-vars')/currentField">
                    <xf:label>This is just a random placeholder by JS</xf:label>
                </xf:input>
                <xf:input id="showTab" ref="instance('i-vars')/showTab">
                    <xf:label>This is just a renderlook placeholder by JS</xf:label>
                </xf:input>                 
            </div>
};


};


