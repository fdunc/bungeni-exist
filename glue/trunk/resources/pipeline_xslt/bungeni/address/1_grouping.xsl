<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:bctype="http://www.bungeni.org/xml/contenttypes/1.0"    
    exclude-result-prefixes="xs bctype"
    version="2.0">
    
    <!-- INCLUDE FUNCTIONS -->
    <xsl:include href="resources/pipeline_xslt/bungeni/common/func_content_types.xsl" />
    <xsl:include href="resources/pipeline_xslt/bungeni/common/include_tmpls.xsl" />
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 24, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> Anthony</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- INPUT PARAMETERS TO TRANSFORM-->
    
    <!-- INPUT PARAMETERS TO TRANSFORM-->
    <!--
        <xsl:param name="country-code"  />
        <xsl:param name="parliament-id"/>
        <xsl:param name="parliament-election-date"  />
        <xsl:param name="for-parliament" /> -->
    
    <xsl:include href="resources/pipeline_xslt/bungeni/common/include_params.xsl"/>

    
    <xsl:template match="/">
        <xsl:apply-templates />
    </xsl:template>
    
    <xsl:template match="contenttype">
        <xsl:variable name="address_id" select="field[@name='address_id']" />
        <xsl:variable name="content-type" select="@name" />
        <xsl:variable name="group_id" select="head/field[@name='group_id']" />
        <xsl:variable name="user_id" select="head/field[@name='user_id']" />        
        <xsl:variable name="group-type" select="head/field[@name='type']" />
        
        <xsl:variable name="parl-info">
            <xsl:choose>
                <xsl:when test="$origin-parliament eq 'None'">
                    <xsl:value-of select="$legislature-full-uri" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$parliament-full-uri" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        
        <!-- this field identifies the type of the input xml bill, question , motion etc. -->
        <xsl:variable name="bungeni-content-type" select="@name" />
        <!-- We map the bungeni internal content type name to a alternative name to prevent tie-in to internal representations -->
        <!-- the type mapping specifies both the name in the URI and the Element name -->
        <xsl:variable name="content-type-element-name" select="bctype:get_content_type_element_name($bungeni-content-type, $type-mappings)" />
        <xsl:variable name="content-type-uri-name" select="bctype:get_content_type_uri_name($bungeni-content-type, $type-mappings)" /> 
        
        <!-- 
            !+NOTE (ao, jan-2012)
            Take country_id as opposed to $country-code as with other documents 
        -->
        <ontology for="address">
            <address isA="TLCConcept" >
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="country/field[@name='language']" />
                </xsl:attribute>            
                <!-- !+NOTE (ao, jan-2012) 
                    This generally takes the $group-type but its not being always set for address document
                     such as those for individuals like a clerk. This is simply stop-gap measure whilst this 
                     issue is pending. -->            

                <xsl:attribute name="id">
                    <xsl:choose>
                        <xsl:when test="field[@name='group_id']">
                            <xsl:text>bungeniGroupAddress</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>bungeniPersonAddress</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>                
                
                <xsl:variable name="full-user-identifier"
                    select="translate(concat($country-code, '.',
                                    head/field[@name='last_name'], '.', 
                                    head/field[@name='first_name'], '.', 
                                    head/field[@name='date_of_birth'], '.', 
                                    head/field[@name='user_id']),' ','')" />   
                        
                <xsl:variable name="full-group-identifier" 
                    select="translate(concat( bctype:get_content_type_uri_name($group-type, $type-mappings), '.',$for-parliament,'-',
                                    $parliament-election-date,'-',
                                    $parliament-id, '.','group',
                                    '.',$group_id),' ','')" /> 
                
                <!-- !+URI_GENERATOR,!+FIX_THIS(ah,nov-2011) use ontology uri
                for group since its non-document entity -->
                <!-- In relation to the !+NOTE above... -->
                
                <xsl:attribute name="uri" 
                    select="concat($parl-info, '/', $content-type-uri-name ,'/',$address_id)" 
                />
                
                <xsl:attribute name="unique-id">
                    <!-- this attribute uniquely identifies the document in the system -->
                    <xsl:variable name="container-id">
                        <xsl:choose>
                            <xsl:when test="field[@name='group_id']">
                                <xsl:value-of select="concat('group.', $group_id)"></xsl:value-of>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('user.', $user_id)"></xsl:value-of>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:choose>
                        <xsl:when test="$origin-parliament ne 'None'">
                            <xsl:value-of select="concat(
                                $legislature-type-name, '.', $legislature-identifier, 
                                '-', 
                                $parliament-type-name, '.', $parliament-identifier, 
                                '-',
                                $container-id,
                                '-',
                                $content-type,'.',  $address_id
                                )" />
                       </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(
                                $legislature-type-name, '.', $legislature-identifier, 
                                '-',
                                $container-id,
                                '-',
                                $content-type,'.',  $address_id
                                )" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                    
                
                <xsl:if test="$origin-parliament ne 'None'">                
                    <xsl:call-template name="incl_origin">
                        <xsl:with-param name="parl-id" select="$parliament-id" />
                        <xsl:with-param name="parl-identifier" select="$parliament-identifier" />
                    </xsl:call-template>
                </xsl:if>
                <assignedTo isA="TLCReference">
                    <xsl:attribute name="uri">
                        <xsl:choose>
                            <xsl:when test="field[@name='group_id']">
                                <xsl:value-of select="concat('/ontology/',bctype:get_content_type_uri_name($group-type, $type-mappings) ,'/',$full-group-identifier)" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('/ontology/Person/',$full-user-identifier)">          
                                </xsl:value-of>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>                    
                </assignedTo>
                
                <!--<xsl:attribute name="uri" 
                    select="concat(
                     '/ontology/',
                     $content-type,'/',
                     $country_id, '/',
                     $address_id
                     )" />-->
                
                <xsl:copy-of select="field[ @name='parent_group_id' or 
                                            @name='address_id' or 
                                            @name='group_principal_id' or 
                                            @name='min_num_members' or 
                                            @name='num_researchers' or 
                                            @name='num_members' or 
                                            @name='quorum' or 
                                            @name='start_date' or 
                                            @name='election_date' or 
                                            @name='titles' or 
                                            @name='first_name' or
                                            @name='last_name' or 
                                            @name='short_name' or 
                                            @name='full_name' or                                         
                                            @name='city' or 
                                            @name='country_name' or 
                                            @name='postal_address_type' or 
                                            @name='zipcode' or 
                                            @name='logical_address_type' or 
                                            @name='phone' or 
                                            @name='street' or 
                                            @name='fax' or 
                                            @name='email' or 
                                            @name='active_p' or 
                                            @name='status' or 
                                            @name='description' or 
                                            @name='status_date' or 
                                            @name='proportional_presentation' or                                             
                                            @name='type' or 
                                            @name='iso_name' or 
                                            @name='numcode' or 
                                            @name='full_name' or                     
                                            @name='iso3' or                                          
                                            @name='country_id' ]"></xsl:copy-of>
                
                <groupType isA="TLCTerm">
                    <value type="xs:string">
                        <xsl:value-of select="bctype:get_content_type_uri_name($group-type, $type-mappings)"></xsl:value-of>                        
                    </value>
                </groupType>                        
                <xsl:copy-of select="permissions" />                
            </address>
            <!--    !+FIX_THIS (ao, jan 2012. Some address documents for individuals like clerk dont have 'type' field and 
                this broke the pipeline processor
                
                <xsl:element name="{$group-type}">
                <xsl:attribute name="isA">TLCOrganization</xsl:attribute>
                <xsl:attribute name="refersTo" select="concat('#', $address_id)" />
                </xsl:element>
            -->
            <!-- i.e. not yet grouped ontologically (ao, Jan 2012) -->
            
            <xsl:call-template name="incl_legislature">
                <xsl:with-param name="leg-uri" select="$legislature-full-uri" />
                <xsl:with-param name="leg-election-date" select="$legislature-election-date" />
                <xsl:with-param name="leg-identifier" select="$legislature-identifier" />
            </xsl:call-template>
            
            <xsl:if test="$origin-parliament ne 'None'">
                <chamber isA="TLCConcept" href="{$parliament-full-uri}">
                    <xsl:copy-of select="parent_group" />             
                </chamber>
            </xsl:if>
            
            <bungeni id="bungeniMeta" showAs="Bungeni Specific info" isA="TLCObject">
                <xsl:copy-of select="tags"/>
                <xsl:copy-of select="field[@name='timestamp']" />
                <withPermissions href="#addressPermissions" />
            </bungeni> 
            
            
            <custom>
                <xsl:copy-of select="$type-mappings" />
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
    
</xsl:stylesheet>
