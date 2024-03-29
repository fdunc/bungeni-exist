<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:bctype="http://www.bungeni.org/xml/contenttypes/1.0"
                xmlns:busers="http://www.bungeni.org/xml/users/1.0"
                xmlns:bdates="http://www.bungeni.org/xml/dates/1.0"
                exclude-result-prefixes="xs bctype busers bdates"
                version="2.0">
    
    <!-- INCLUDE FUNCTIONS -->
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_content_types.xsl" />
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_users.xsl" />
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_dates.xsl" />
    <xsl:import href="resources/pipeline_xslt/bungeni/common/include_owner.xsl" />
    
    <xsl:include href="resources/pipeline_xslt/bungeni/common/include_tmpls.xsl" />
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 17, 2011</xd:p>
            <xd:p><xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- INPUT PARAMETERS TO TRANSFORM-->
    
    <xsl:include href="resources/pipeline_xslt/bungeni/common/include_params.xsl" />
    
    <xsl:template match="/">
        <xsl:apply-templates />
    </xsl:template>

    <!-- Content Type matcher -->
    <xsl:template match="contenttype">
  
        <!-- this field identifies the type of the input xml bill, question , motion etc. -->
        <xsl:variable name="bungeni-content-type" select="field[@name='type']" />
        <!-- We map the bungeni internal content type name to a alternative name to prevent tie-in to internal representations -->
        <!-- the type mapping specifies both the name in the URI and the Element name -->
        <xsl:variable name="content-type-element-name" select="bctype:get_content_type_element_name($bungeni-content-type, $type-mappings)" />
        <xsl:variable name="content-type-uri-name" select="bctype:get_content_type_uri_name($bungeni-content-type, $type-mappings)" />
        
        <!--
        <xsl:variable name="head-type" select="head/field[@name='type']" />
        <xsl:variable name="head-type-uri-name" select="bctype:get_content_type_uri_name($head-type, $type-mappings)" />
        <xsl:variable name="head-item-internal-id" select="head/field[@name='doc_id']" />
        <xsl:variable name="head-item-internal-uri" select="concat(
            $parliament-full-uri, '/',
            $head-type-uri-name, '/',
            $head-item-internal-id
            )" />
        -->
        <xsl:variable name="language" select="field[@name='language']" />
        <xsl:variable name="doc_id" select="field[@name='doc_id']" />
        
        <xsl:variable name="uri-generator-type">
            <!-- generate @uri use progressive number -->
            
            <xsl:choose>
                
                <xsl:when test="field[@name='type_number']">
                    <xsl:text>PROGRESSIVE</xsl:text>
                </xsl:when>
                
                <!-- agendaitem, Event is progressive internal -->
                <xsl:otherwise>
                    <xsl:text>PROGRESSIVE-INTERNAL</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="doc-uri">
            <xsl:choose>
                <xsl:when test="$uri-generator-type eq 'PROGRESSIVE'">
                    <xsl:variable name="progressive-number" select="field[@name='type_number']" />
                    <xsl:value-of select="concat(
                        $parliament-full-uri, '/',
                        $content-type-uri-name, '/',
                        $progressive-number
                        )" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>NO_URI</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="internal-uri">
            <xsl:value-of select="concat(
                $parliament-full-uri, '/',
                $content-type-uri-name, '/',
                $doc_id
                )" />
        </xsl:variable>

        <!--
        <xsl:variable name="internal-doc-uri">
            <xsl:value-of select="concat(
                $parliament-full-uri, '/',
                $content-type-uri-name, '/',
                $doc_id
               )" />
        </xsl:variable>    
        -->
  
        <!-- ROOT ELEMENT OF DOCUMENT -->
        <ontology for="document">
            
            <document id="bungeniDocument" isA="TLCConcept">
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="field[@name='language']" />
                </xsl:attribute>
                
                <xsl:attribute name="unique-id">
                    <xsl:value-of select="concat(
                        $legislature-type-name, '.', $legislature-identifier, 
                        '-', 
                        $parliament-type-name, '.', $parliament-id, 
                        '-',
                        $content-type-uri-name, '.', $doc_id
                        )" />
                </xsl:attribute>
                
                <xsl:if test="$uri-generator-type eq 'PROGRESSIVE'">
                        <xsl:attribute name="uri" select="$doc-uri" />
                </xsl:if> 
                
                <xsl:attribute name="internal-uri" 
                    select="$internal-uri" />
                
                <!-- 
                    THe URI is generated further up the pipeline -->
                
                <xsl:call-template name="incl_origin">
                    <xsl:with-param name="parl-id" select="$parliament-id" />
                    <xsl:with-param name="parl-identifier" select="$parliament-identifier" />
                </xsl:call-template>

                <docType isA="TLCTerm">
                    <value type="xs:string"><xsl:value-of select="$content-type-uri-name" /></value>
                </docType>
 
 
                <xsl:copy-of select="field[
                    @name='status_date' or 
                    @name='registry_number' or 
                    @name='doc_id'
                    ] | 
                    changes |
                    audits |
                    sa_events | 
                    sittingreport | 
                    versions
                    " />
                <!-- for <event> and <attachment> -->
                <!--
                <xsl:copy-of select="head" />    
                -->
                
                <xsl:copy-of select="field[
                    @name='status' or 
                    @name='mimetype' or 
                    @name='title' or 
                    @name='sub_title' or 
                    @name='summary' or 
                    @name='description' or 
                    @name='long_title' or 
                    @name='body' or 
                    @name='language'  or 
                    @name='owner_id' or 
                    @name='attachment_id' or 
                    @name='type'
                    ]" />
                
                <!-- NUMBER AND IDENTIFIERS -->
                
                <xsl:copy-of select="field[
                    @name='type_number' 
                    ]" />                  
                
                <!-- for <tableddocument> 
                    <xsl:copy-of select="field[
                    @name='tabled_document_id' or 
                    @name='tabled_document_number' 
                    ]" />    
                    
                    
                    <xsl:copy-of select="field[
                    @name='bill_id' or 
                    @name='bill_type_id' or 
                    @name='bill_number'
                    ]" />
                    
                    <xsl:copy-of select="field[
                    @name='motion_id' or 
                    @name='motion_number'
                    ]" />
                -->
                
                <!-- for <motion> & <bill> !+FIX_THIS(ah,17-04-2012)
                    <xsl:copy-of select="field[
                    @name='publication_date' or
                    @name='doc_type' 
                    ]" />  -->
                
                <!-- for <event> -->
                <xsl:copy-of select="field[
                    @name='doc_type' or 
                    @name='acronym' or 
                    @name='long_title'
                    ]" />                
                
                <!-- PERMISSIONS -->
                <xsl:copy-of select="permissions" />
                
                <!-- for <question> !+FIX_THIS(ah,17-04-2012)
                    <xsl:if test="ministry/*">
                    <assignedTo group="ministry">
                    <xsl:copy-of select="ministry" />
                    </assignedTo>
                    </xsl:if>                 
                -->               
                <xsl:apply-templates select="owner" />
                
                
            </document>
            <xsl:call-template name="incl_legislature">
                <xsl:with-param name="leg-uri" select="$legislature-full-uri" />
                <xsl:with-param name="leg-election-date" select="$legislature-election-date" />
                <xsl:with-param name="leg-identifier" select="$legislature-identifier" />
            </xsl:call-template>
            <xsl:call-template name="incl_chamber">
                <xsl:with-param name="parl-uri" select="$parliament-full-uri" />
                <xsl:with-param name="parl-id" select="$parliament-id" />
                <xsl:with-param name="elect-date" select="$parliament-election-date" />
                <xsl:with-param name="country-code" select="$country-code" />
                <xsl:with-param name="type" select="$parliament-type" />
                <xsl:with-param name="type-display" select="$parliament-type-display" />
            </xsl:call-template>
            <!--
            <chamber isA="TLCConcept" href="{$parliament-full-uri}">
               <parliamentId key="true" type="xs:integer" select="{$parliament-id}" />
               <electionDate type="xs:date" select="{$parliament-election-date}"></electionDate> 
                <country isA="TLCLocation">
                    <value type="xs:string"><xsl:value-of select="$country-code" /></value>
                </country>
            </chamber>
            -->
            <bungeni id="bungeniMeta" showAs="Bungeni Specific info" isA="TLCObject">
                <xsl:copy-of select="tags" />
                <xsl:copy-of select="field[@name='timestamp']" />
                <withPermissions href="#documentPermissions" />
            </bungeni>
                        
            <!-- 
            e.g. <question> or <motion> or <tableddocument> or <bill> are Bungeni "object" concepts and not 
            really documents so we model them as TLCObject items
            -->
            
            <xsl:element name="{$content-type-element-name}" >
                
                <xsl:attribute name="isA"><xsl:text>TLCObject</xsl:text></xsl:attribute>
                
                <document href="#bungeniDocument" />
                
                <xsl:copy-of select="field[
                        @name='doc_type'
                        ] |
                        _vp_response_type " /> <!-- was question_type and response_tyep -->
                
                <!-- This is a reference to a group from the parliamentary item -->         
                <xsl:if test="group">
                   <xsl:for-each select="group">
                       
                       <group isA="TLCReference">
                           
                           <xsl:variable name="group-id" select="field[@name='group_id']" />
                           
                           <xsl:variable name="group-type" select="field[@name='type']" />
                           
                           <xsl:variable name="group-identifier" select="field[@name='identifier']" />
                           
                           
                           <xsl:variable name="group-type-element-name" select="translate(bctype:get_content_type_element_name(
                               $group-type, 
                               $type-mappings
                               ),' ','')" />
                           
                           <xsl:variable name="group-type-uri-name" select="translate(bctype:get_content_type_uri_name(
                               $group-type, 
                               $type-mappings
                               ),' ','')" />
                           
                           
                           <xsl:attribute name="href" select="concat(
                               $parliament-full-uri, '/',
                               $group-type-uri-name, '/',
                               $group-identifier
                               )" />
                           
                           <xsl:copy-of select="field[@name='group_id' or 
                               @name='short_name' or
                               @name='full_name' or 
                               @name='acronym' or 
                               @name='status_date' or 
                               @name='identifier' or 
                               @name='type' or  
                               @name='start_date' ]"/>                           
                       </group>
                       
                   </xsl:for-each>
                </xsl:if>
            </xsl:element>

            
            <!-- End of Legislative Item -->
            
            <xsl:copy-of select="attachments" />
           
            <xsl:copy-of select="item_signatories" />        
            
            <custom>
                <xsl:copy-of select="$type-mappings" />
                <internal-uri><xsl:value-of select="$internal-uri" /></internal-uri>
                <xsl:if test="$doc-uri">
                    <doc-uri><xsl:value-of select="$doc-uri" /></doc-uri>
                </xsl:if>
                <bungeni_doc_type>
                    <xsl:value-of select="$bungeni-content-type"/>
                </bungeni_doc_type>
                <uri-base><xsl:value-of select="$uri-base" /></uri-base>
                <legislature-uri><xsl:value-of select="$legislature-uri" /></legislature-uri>
                <parliament-uri><xsl:value-of select="$parliament-uri" /></parliament-uri>
                <legislature-full-uri><xsl:value-of select="$legislature-full-uri" /></legislature-full-uri>
                <parliament-full-uri><xsl:value-of select="$parliament-full-uri" /></parliament-full-uri>
            </custom>
            
           </ontology>
    </xsl:template>

    <xsl:template match="owner">
        <xsl:call-template name="ownerRender">
            <xsl:with-param name="type-mappings" select="$type-mappings" />
            <xsl:with-param name="country-code" select="$country-code" />
            <xsl:with-param name="uri-base" select="$uri-base" />
        </xsl:call-template>
    </xsl:template>
    
    
    <!--
    <xsl:template match="owner">
        <xsl:variable name="user-type-uri-name" select="bctype:get_content_type_uri_name('user', $type-mappings)" />
        <xsl:variable name="first-name" select="data(field[@name='first_name'])" />
        <xsl:variable name="last-name" select="data(field[@name='last_name'])" />
        <xsl:variable name="user-id" select="data(field[@name='user_id'])" />
        <xsl:variable name="yyyy-mm-dd-dob" select="bdates:parse-datepart-only(data(field[@name='date_of_birth']))" />
        <xsl:variable name="user-identifier" select="busers:get_user_identifer(
            $country-code, 
            $last-name, 
            $first-name, 
            $user-id, 
            $yyyy-mm-dd-dob
            )" 
        />
        <xsl:variable name="user-uri" select="busers:get_user_uri(
            concat(
            $uri-base,
            $user-type-uri-name
            ),
            $user-identifier
            )" />
        <owner isA="TLCPerson">
            <person href="{$user-uri}" showAs="{concat($last-name, ', ', $first-name)}" />
            <role type="TLCConcept">
                <value type="xs:string">
                    <xsl:value-of select="bctype:get_content_type_uri_name(
                        'member_of_parliament',
                        $type-mappings
                        )" />
                </value>
            </role>
        </owner>
    </xsl:template>
    -->
    
</xsl:stylesheet>