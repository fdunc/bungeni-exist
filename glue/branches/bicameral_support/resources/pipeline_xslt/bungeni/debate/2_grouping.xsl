<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:bdates="http://www.bungeni.org/xml/dates/1.0"
    xmlns:busers="http://www.bungeni.org/xml/users/1.0"
    xmlns:bctypes="http://www.bungeni.org/xml/contenttypes/1.0"    
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_dates.xsl" />
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_users.xsl" />
    <xsl:import href="resources/pipeline_xslt/bungeni/common/func_content_types.xsl" />    
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 24, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> anthony</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output indent="yes" method="xml" encoding="UTF-8"/>
    
    <!-- These values are set in first input which is grouping_Level1 -->        
    <xsl:variable name="country-code" select="data(/ontology/bungeni/country)" />
    <xsl:variable name="parliament-election-date" select="data(/ontology/bungeni/parliament/@date)" />
    <xsl:variable name="for-parliament" select="data(/ontology/bungeni/parliament/@href)" />  
    <xsl:variable name="parliament-id" select="data(/ontology/bungeni/@id)" />
    <xsl:variable name="type-mappings" select="//custom/value" />
    <xsl:variable name="bungeni-debaterecord-type" select="data(//custom/bungeni_grp_type)" />
    
    <!-- permission names for the type -->
    <xsl:variable name="perm-content-type-view" select="concat('bungeni.',$bungeni-debaterecord-type,'.View')" />
    <xsl:variable name="perm-content-type-edit" select="concat('bungeni.',$bungeni-debaterecord-type,'.View')" />    

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="*">
        <xsl:element name="{node-name(.)}">
            <xsl:for-each select="@*">
                <xsl:attribute name="{name(.)}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:for-each>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="field[@name='venue_id']">
        <venueId type="xs:integer">
            <xsl:value-of select="." />
        </venueId>
    </xsl:template>     
    
    <xsl:template match="field[@name='report_id']">
        <reportId type="xs:integer">
            <xsl:value-of select="." />
        </reportId>
    </xsl:template>     
    
    <xsl:template match="field[@name='meeting_type']">
        <meetingType isA="TLCObject">
            <value isA="TLCTerm">
                <xsl:attribute name="showAs" select="@displayAs"/>
                <xsl:value-of select="." />                
            </value>
        </meetingType>
    </xsl:template>
    
    <xsl:template match="field[@name='item_type']">
        <itemType isA="TLCTerm">
            <value type="xs:string">
                <xsl:value-of select="bctypes:get_content_type_uri_name(., $type-mappings)" />                
            </value>
        </itemType>
    </xsl:template>    
    
    <xsl:template match="field[@name='convocation_type']">
        <convocationType isA="TLCObject">
            <value isA="TLCTerm">
                <xsl:attribute name="showAs" select="@displayAs"/>
                <xsl:value-of select="." />                
            </value>
        </convocationType>
    </xsl:template>
    
    <xsl:template match="field[@name='activity_type']">
        <activityType isA="TLCProcess">
            <value isA="TLCTerm">
                <xsl:attribute name="showAs" select="@displayAs"/>
                <xsl:value-of select="." />                
            </value>
        </activityType>
    </xsl:template>
    
    <xsl:template match="field[@name='type']">
        <type isA="TLCTerm">
            <value type="xs:string">
                <xsl:value-of select="." />                
            </value>
        </type>
    </xsl:template>      
    
    <xsl:template match="field[@name='user_id']">
        <userId type="xs:integer">
            <xsl:value-of select="." />
        </userId>
    </xsl:template> 
    
    <xsl:template match="field[@name='sitting_id']">
        <sittingId type="xs:integer">
            <xsl:value-of select="." />
        </sittingId>
    </xsl:template>     
    
    <xsl:template match="field[@name='debate_record_id']">
        <debateRecordId type="xs:integer">
            <xsl:value-of select="." />
        </debateRecordId>
    </xsl:template>      

    <xsl:template match="field[@name='tag']">
        <tag isA="TLCTerm">
            <value type="xs:string">
                <xsl:value-of select="." />
            </value>    
        </tag>
    </xsl:template>  
    
    <xsl:template match="field[@name='membership_id']">
        <membershipId type="xs:integer">
            <xsl:value-of select="." />
        </membershipId>
    </xsl:template>  
    
    <xsl:template match="field[@name='group_principal_id']">
        <groupPrincipalId isA="TLCReference">
            <value type="xs:string">
                <xsl:value-of select="." />                
            </value>
        </groupPrincipalId>
    </xsl:template>      
    
    <xsl:template match="field[@name='group_id']">
        <groupId type="xs:integer">
            <xsl:value-of select="." />
        </groupId>
    </xsl:template>      
    
    <xsl:template match="field[@name='parliament_id']">
        <parliamentId type="xs:integer">
            <xsl:value-of select="." />
        </parliamentId>
    </xsl:template>      
    
    <xsl:template match="field[@name='parent_group_id']">
        <parentGroupId type="xs:integer">
            <xsl:value-of select="." />
        </parentGroupId>
    </xsl:template>  
    
    <xsl:template match="field[@name='election_date']">
        <electionDate type="xs:date">
            <xsl:value-of select="." />
        </electionDate>
    </xsl:template>
    
    <xsl:template match="field[@name='dissolution_date']">
        <dissolutionDate type="xs:date">
            <xsl:value-of select="." />
        </dissolutionDate>
    </xsl:template>  
    
    <xsl:template match="field[@name='dissolution_date']">
        <resultsDate type="xs:date">
            <xsl:value-of select="." />
        </resultsDate>
    </xsl:template>   
    
    <xsl:template match="field[@name='short_name']">
        <shortName type="xs:string">
            <xsl:value-of select="." />
        </shortName>
    </xsl:template>    
    
    <xsl:template match="field[@name='num_members']">
        <numMembers type="xs:integer">
            <xsl:value-of select="." />
        </numMembers>
    </xsl:template>    
    
    <xsl:template match="field[@name='quorum']">
        <quorum type="xs:integer">
            <xsl:value-of select="." />
        </quorum>
    </xsl:template>
    
    <xsl:template match="permissions">
        <permissions id="groupsittingPermissions">
            <xsl:apply-templates />
        </permissions>
    </xsl:template>
    
    <xsl:template match="permission">
        <xsl:variable name="perm-name" select="data(field[@name='permission'])" />
        <xsl:variable name="perm-role" select="data(field[@name='role'])" />
        <xsl:variable name="perm-setting" select="data(field[@name='setting'])" />
        <permission 
            setting="{$perm-setting}" 
            name="{$perm-name}"  
            role="{$perm-role}" />
        <xsl:choose>
            <xsl:when test="$perm-name eq $perm-content-type-view">
                <control name="View" setting="{$perm-setting}" role="{$perm-role}" />  
            </xsl:when>
            <xsl:when test="$perm-name eq $perm-content-type-edit">
                <control name="Edit" setting="{$perm-setting}" role="{$perm-role}" />  
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:template>  
    
    <xsl:template match="field[@name='active']">
        <active type="xs:boolean">
            <xsl:value-of select="." />
        </active>
    </xsl:template>   
    
    <xsl:template match="field[@name='schedule_id']">
        <scheduleId type="xs:integer">
            <xsl:value-of select="." />
        </scheduleId>
    </xsl:template>
    
    <xsl:template match="field[@name='group_sitting_id']">
        <groupSittingId type="xs:integer">
            <xsl:value-of select="." />
        </groupSittingId>
    </xsl:template>
    
    <xsl:template match="field[@name='planned_order']">
        <plannedOrder type="xs:integer">
            <xsl:value-of select="." />
        </plannedOrder>
    </xsl:template>
    
    <xsl:template match="field[@name='country_code']">
        <country>
            <xsl:attribute name="code">
                <xsl:value-of select="$country-code"/>
            </xsl:attribute>
            <!-- !+FIX_THIS (ao, 24-Apr-2012) Is country name
                available set correct, else remove it altogether 
            -->
            <xsl:text>Kenya</xsl:text>
        </country>
    </xsl:template>

    
    <xsl:template match="field[@name='gender']">
        <xsl:variable name="field_gender" select="." />
        <gender type="xs:string">
            <xsl:choose >
                <xsl:when test="$field_gender eq 'M'">male</xsl:when>
                <xsl:when test="$field_gender eq 'F'">female</xsl:when>
                <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
        </gender>
    </xsl:template>  
    
    <xsl:template match="field[@name='committee_id']">
        <committeeId type="xs:integer">
            <xsl:value-of select="." />
        </committeeId>
    </xsl:template>    
    
    <xsl:template match="field[@name='proportional_representation']">
        <proportionalRepresentation  type="xs:boolean">
            <xsl:value-of select="." />
        </proportionalRepresentation>
    </xsl:template>  
    
    <xsl:template match="field[@name='acronym']">
        <acronym type="xs:string">
            <xsl:value-of select="." />
        </acronym>
    </xsl:template>  
    
    <xsl:template match="field[@name='sub_type']">
        <subType isA="TLCObject">
            <xsl:attribute name="showAs" select="@displayAs"/>
            <value isA="TLCTerm">
                <xsl:value-of select="." />                
            </value>
        </subType>
    </xsl:template>     
    
    <xsl:template match="field[@name='num_clerks']">
        <numClerks type="xs:integer">
            <xsl:value-of select="." />
        </numClerks>
    </xsl:template>         

    <xsl:template match="field[@name='status_date']">
        <xsl:variable name="status_date" select="." />
        <statusDate type="xs:dateTime">
            <xsl:value-of select="bdates:parse-date($status_date)" />
        </statusDate>        
    </xsl:template>
 
    <xsl:template match="field[@name='start_date']">
        <xsl:variable name="start_date" select="." />
        <startDate type="xs:dateTime">
            <xsl:value-of select="bdates:parse-date($start_date)" />
        </startDate>
    </xsl:template>    
    
    <xsl:template match="field[@name='end_date']">
        <xsl:variable name="end_date" select="." />
        <endDate type="xs:dateTime">
            <xsl:value-of select="bdates:parse-date($end_date)" />
        </endDate>
    </xsl:template>
    
    <xsl:template match="field[@name='timestamp' or 
        @name='date_active' or 
        @name='date_audit']">
        <xsl:element name="{local-name()}" >
            <xsl:variable name="misc_dates" select="." />
            <xsl:attribute name="name" select="@name" />      
            <xsl:value-of select="bdates:parse-date($misc_dates)" />
        </xsl:element>
    </xsl:template>   
    
    <xsl:template match="field[@name='status']">
        <status isA="TLCTerm">
            <xsl:attribute name="showAs" select="@displayAs"/>
            <value type="xs:string">
                <xsl:value-of select="."/>
            </value>
        </status>
    </xsl:template>     

    <xsl:template match="field[@name='language']">
        <!-- !+RENDERED NOW as xml:lang on the legislativeItem
            <language type="xs"><xsl:value-of select="." /></language>
        -->
    </xsl:template>

    <xsl:template match="field[@name='email']">
        <email><xsl:value-of select="."/></email>
    </xsl:template>    

    <xsl:template match="field[@name='receive_notification']">
        <receiveNotification type="xs:boolean">
            <xsl:value-of select="."/>
        </receiveNotification>
    </xsl:template>
    
    <xsl:template match="custom"/>     
</xsl:stylesheet>