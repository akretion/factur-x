<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                xmlns:qdt="urn:un:unece:uncefact:data:standard:QualifiedDataType:100"
                xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"
                xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:schold="http://www.ascc.net/xml/schematron"
                xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"><!--Implementers: please note that overriding process-prolog or process-root is
    the preferred method for meta-stylesheets to use where possible. -->
   <xsl:param name="archiveDirParameter"/>
   <xsl:param name="archiveNameParameter"/>
   <xsl:param name="fileNameParameter"/>
   <xsl:param name="fileDirParameter"/>
   <xsl:variable name="document-uri">
      <xsl:value-of select="document-uri(/)"/>
   </xsl:variable>
   <!--PHASES-->

   <!--PROLOG-->
   <xsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
               method="xml"
               omit-xml-declaration="no"
               standalone="yes"
               indent="yes"/>
   <!--XSD TYPES FOR XSLT2-->

   <!--KEYS AND FUNCTIONS-->

   <!--DEFAULT RULES-->

   <!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-select-full-path">
      <xsl:apply-templates select="." mode="schematron-get-full-path"/>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">
            <xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>*:</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>[namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="preceding"
                    select="count(preceding-sibling::*[local-name()=local-name(current())                                   and namespace-uri() = namespace-uri(current())])"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="@*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>@*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>' and namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-2-->
   <!--This mode can be used to generate prefixed XPath for humans-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-2">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-3-->
   <!--This mode can be used to generate prefixed XPath for humans
	(Top-level element has index)-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-3">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="parent::*">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: GENERATE-ID-FROM-PATH -->
   <xsl:template match="/" mode="generate-id-from-path"/>
   <xsl:template match="text()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
   </xsl:template>
   <xsl:template match="comment()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.@', name())"/>
   </xsl:template>
   <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
   </xsl:template>
   <!--MODE: GENERATE-ID-2 -->
   <xsl:template match="/" mode="generate-id-2">U</xsl:template>
   <xsl:template match="*" mode="generate-id-2" priority="2">
      <xsl:text>U</xsl:text>
      <xsl:number level="multiple" count="*"/>
   </xsl:template>
   <xsl:template match="node()" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>n</xsl:text>
      <xsl:number count="node()"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="string-length(local-name(.))"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="translate(name(),':','.')"/>
   </xsl:template>
   <!--Strip characters-->
   <xsl:template match="text()" priority="-1"/>
   <!--SCHEMA SETUP-->
   <xsl:template match="/">
      <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                              title="Schema for Factur-X; 1.08; EN16931-COMPLIANT-BASIC"
                              schemaVersion="iso">
         <xsl:comment>
            <xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
         </xsl:comment>
         <svrl:ns-prefix-in-attribute-values uri="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"
                                             prefix="rsm"/>
         <svrl:ns-prefix-in-attribute-values uri="urn:un:unece:uncefact:data:standard:QualifiedDataType:100"
                                             prefix="qdt"/>
         <svrl:ns-prefix-in-attribute-values uri="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"
                                             prefix="ram"/>
         <svrl:ns-prefix-in-attribute-values uri="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"
                                             prefix="udt"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M5"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M6"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M7"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M8"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M9"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M10"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M11"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M12"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M13"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M14"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M15"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M16"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M17"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M18"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M19"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M20"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M21"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M22"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M23"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M24"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M25"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M26"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M27"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M28"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M29"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M30"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M31"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M32"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M33"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M34"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M35"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M36"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M37"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M38"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M39"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M40"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M41"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M42"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M43"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M44"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M45"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M46"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M47"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M48"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M49"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M50"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M51"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M52"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M53"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M54"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M55"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M56"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M57"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M58"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M59"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M60"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M61"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M62"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M63"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M64"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M65"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M66"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M67"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M68"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M69"/>
      </svrl:schematron-output>
   </xsl:template>
   <!--SCHEMATRON PATTERNS-->
   <svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Schema for Factur-X; 1.08; EN16931-COMPLIANT-BASIC</svrl:text>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//*[not(*) and not(normalize-space())]"
                 priority="1000"
                 mode="M5">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//*[not(*) and not(normalize-space())]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="false"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="false">
               <xsl:attribute name="flag">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[PEPPOL-EN16931-R008]-Document MUST not contain empty elements. (still status warning)</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M5"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M5"/>
   <xsl:template match="@*|node()" priority="-2" mode="M5">
      <xsl:apply-templates select="*" mode="M5"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax"
                 priority="1000"
                 mode="M6">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:BasisAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:BasisAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-45]-Each VAT breakdown (BG-23) shall have a VAT category taxable amount (BT-116).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:CalculatedAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:CalculatedAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-46]-Each VAT breakdown (BG-23) shall have a VAT category tax amount (BT-117).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:CategoryCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:CategoryCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-47]-Each VAT breakdown (BG-23) shall be defined through a VAT category code (BT-118).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:RateApplicablePercent) or (ram:CategoryCode = 'O')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:RateApplicablePercent) or (ram:CategoryCode = 'O')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-48]-Each VAT breakdown (BG-23) shall have a VAT category rate (BT-119), except if the Invoice is not subject to VAT.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="((ram:TaxPointDate) and not (ram:DueDateTypeCode)) or (not (ram:TaxPointDate) and (ram:DueDateTypeCode)) or (not (ram:TaxPointDate) and not (ram:DueDateTypeCode))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="((ram:TaxPointDate) and not (ram:DueDateTypeCode)) or (not (ram:TaxPointDate) and (ram:DueDateTypeCode)) or (not (ram:TaxPointDate) and not (ram:DueDateTypeCode))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-03]-Value added tax point date (BT-7) and Value added tax point date code (BT-8) are mutually exclusive.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(round(.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent)) = 0 and (round(xs:decimal(ram:CalculatedAmount)) = 0)) or (round(.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent)) != 0 and ((abs(xs:decimal(ram:CalculatedAmount)) - 1 &lt;= round(abs(xs:decimal(ram:BasisAmount)) * (.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent) div 100) * 10 * 10) div 100 ) and (abs(xs:decimal(ram:CalculatedAmount)) + 1 &gt;= round(abs(xs:decimal(ram:BasisAmount)) * (.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent) div 100) * 10 * 10) div 100 ))) or (not(exists(.[normalize-space(upper-case(ram:TypeCode))='VAT']/xs:decimal(ram:RateApplicablePercent))) and (round(xs:decimal(ram:CalculatedAmount)) = 0))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(round(.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent)) = 0 and (round(xs:decimal(ram:CalculatedAmount)) = 0)) or (round(.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent)) != 0 and ((abs(xs:decimal(ram:CalculatedAmount)) - 1 &lt;= round(abs(xs:decimal(ram:BasisAmount)) * (.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent) div 100) * 10 * 10) div 100 ) and (abs(xs:decimal(ram:CalculatedAmount)) + 1 &gt;= round(abs(xs:decimal(ram:BasisAmount)) * (.[normalize-space(upper-case(ram:TypeCode)) = 'VAT']/xs:decimal(ram:RateApplicablePercent) div 100) * 10 * 10) div 100 ))) or (not(exists(.[normalize-space(upper-case(ram:TypeCode))='VAT']/xs:decimal(ram:RateApplicablePercent))) and (round(xs:decimal(ram:CalculatedAmount)) = 0))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-17]-VAT category tax amount (BT-117) = VAT category taxable amount (BT-116) x (VAT category rate (BT-119) / 100), rounded to two decimals.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:BasisAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:BasisAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-19]-The allowed maximum number of decimals for the VAT category taxable amount (BT-116) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:CalculatedAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:CalculatedAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-20]-The allowed maximum number of decimals for the VAT category tax amount (BT-117) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M6"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M6"/>
   <xsl:template match="@*|node()" priority="-2" mode="M6">
      <xsl:apply-templates select="*" mode="M6"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'Z']"
                 priority="1000"
                 mode="M7">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'Z']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'Z']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'Z']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'Z']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'Z']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='Z']/xs:decimal(ram:ActualAmount))*10*10)div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-08]-In a VAT breakdown (BG-23) where VAT category code (BT-118) is "Zero rated" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amount (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Zero rated".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="../ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="../ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where VAT category code (BT-118) is "Zero rated" shall equal 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(../ram:ExemptionReason) and not (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(../ram:ExemptionReason) and not (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "Zero rated" shall not have a VAT exemption reason code (BT-121) or VAT exemption reason text (BT-120).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M7"/>
   <xsl:template match="@*|node()" priority="-2" mode="M7">
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[.='S']"
                 priority="1000"
                 mode="M8">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[.='S']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(abs(xs:decimal(../ram:CalculatedAmount)) - 1 &lt; round(abs(xs:decimal(../ram:BasisAmount)) * ../ram:RateApplicablePercent) div 100 ) and (abs(xs:decimal(../ram:CalculatedAmount)) + 1 &gt; round(abs(xs:decimal(../ram:BasisAmount)) * ../ram:RateApplicablePercent) div 100 )"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(abs(xs:decimal(../ram:CalculatedAmount)) - 1 &lt; round(abs(xs:decimal(../ram:BasisAmount)) * ../ram:RateApplicablePercent) div 100 ) and (abs(xs:decimal(../ram:CalculatedAmount)) + 1 &gt; round(abs(xs:decimal(../ram:BasisAmount)) * ../ram:RateApplicablePercent) div 100 )">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where VAT category code (BT-118) is "Standard rated" shall equal the VAT category taxable amount (BT-116) multiplied by the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(../ram:ExemptionReason) and not (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(../ram:ExemptionReason) and not (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "Standard rate" shall not have a VAT exemption reason code (BT-121) or VAT exemption reason text (BT-120).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'S' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='S' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='S' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'S' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='S' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='S' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-08]-For each different value of VAT category rate (BT-119) where the VAT category code (BT-118) is "Standard rated", the VAT category taxable amount (BT-116) in a VAT breakdown (BG-23) shall equal the sum of Invoice line net amounts (BT-131) plus the sum of document level charge amounts (BT-99) minus the sum of document level allowance amounts (BT-92) where the VAT category code (BT-151, BT-102, BT-95) is "Standard rated" and the VAT rate (BT-152, BT-103, BT-96) equals the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M8"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M8"/>
   <xsl:template match="@*|node()" priority="-2" mode="M8">
      <xsl:apply-templates select="*" mode="M8"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod"
                 priority="1000"
                 mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:EndDateTime/udt:DateTimeString[@format = '102']) &gt;= (ram:StartDateTime/udt:DateTimeString[@format = '102']) or not (ram:EndDateTime) or not (ram:StartDateTime)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:EndDateTime/udt:DateTimeString[@format = '102']) &gt;= (ram:StartDateTime/udt:DateTimeString[@format = '102']) or not (ram:EndDateTime) or not (ram:StartDateTime)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-29]-If both Invoicing period start date (BT-73) and Invoicing period end date (BT-74) are given then the Invoicing period end date (BT-74) shall be later or equal to the Invoicing period start date (BT-73).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:StartDateTime) or (ram:EndDateTime)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:StartDateTime) or (ram:EndDateTime)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-19]-If Invoicing period (BG-14) is used, the Invoicing period start date (BT-73) or the Invoicing period end date (BT-74) shall be filled, or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M9"/>
   <xsl:template match="@*|node()" priority="-2" mode="M9">
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator='false']"
                 priority="1000"
                 mode="M10">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator='false']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ActualAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(../ram:ActualAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-31]-Each Document level allowance (BG-20) shall have a Document level allowance amount (BT-92).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:CategoryTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:CategoryTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-32]-Each Document level allowance (BG-20) shall have a Document level allowance VAT category code (BT-95).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-33]-Each Document level allowance (BG-20) shall have a Document level allowance reason (BT-97) or a Document level allowance reason code (BT-98).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-05]-Document level allowance reason code (BT-98) and Document level allowance reason (BT-97) shall indicate the same type of allowance.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-21]-Each Document level allowance (BG-20) shall contain a Document level allowance reason (BT-97) or a Document level allowance reason code (BT-98), or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-01]-The allowed maximum number of decimals for the Document level allowance amount (BT-92) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-02]-The allowed maximum number of decimals for the Document level allowance base amount (BT-93) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M10"/>
   <xsl:template match="@*|node()" priority="-2" mode="M10">
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator='true']"
                 priority="1000"
                 mode="M11">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator='true']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ActualAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(../ram:ActualAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-36]-Each Document level charge (BG-21) shall have a Document level charge amount (BT-99).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:CategoryTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:CategoryTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-37]-Each Document level charge (BG-21) shall have a Document level charge VAT category code (BT-102).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-38]-Each Document level charge (BG-21) shall have a Document level charge reason (BT-104) or a Document level charge reason code (BT-105).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-06]-Document level charge reason code (BT-105) and Document level charge reason (BT-104) shall indicate the same type of charge.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-22]-Each Document level charge (BG-21) shall contain a Document level charge reason (BT-104) or a Document level charge reason code (BT-105), or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-05]-The allowed maximum number of decimals for the Document level charge amount (BT-99) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-06]-The allowed maximum number of decimals for the Document level charge base amount (BT-100) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M11"/>
   <xsl:template match="@*|node()" priority="-2" mode="M11">
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:ApplicableProductCharacteristic"
                 priority="1000"
                 mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:ApplicableProductCharacteristic"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:Description) and (ram:Value)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:Description) and (ram:Value)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-54]-Each Item attribute (BG-32) shall contain an Item attribute name (BT-160) and an Item attribute value (BT-161).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M12"/>
   <xsl:template match="@*|node()" priority="-2" mode="M12">
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:IncludedSupplyChainTradeLineItem"
                 priority="1000"
                 mode="M13">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:IncludedSupplyChainTradeLineItem"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:AssociatedDocumentLineDocument/ram:LineID!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:AssociatedDocumentLineDocument/ram:LineID!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-21]-Each Invoice line (BG-25) shall have an Invoice line identifier (BT-126).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeDelivery/ram:BilledQuantity)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeDelivery/ram:BilledQuantity)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-22]-Each Invoice line (BG-25) shall have an Invoiced quantity (BT-129).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-23]-An Invoice line (BG-25) shall have an Invoiced quantity unit of measure code (BT-130).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-24]-Each Invoice line (BG-25) shall have an Invoice line net amount (BT-131).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedTradeProduct/ram:Name!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedTradeProduct/ram:Name!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-25]-Each Invoice line (BG-25) shall contain the Item name (BT-153).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-26]-Each Invoice line (BG-25) shall contain the Item net price (BT-146).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount) &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount) &gt;= 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-27]-The Item net price (BT-146) shall NOT be negative.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount &gt;= 0) or not(ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount &gt;= 0) or not(ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-28]-The Item gross price (BT-148) shall NOT be negative.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:SpecifiedTradeProduct/ram:GlobalID/@schemeID!='' or not (ram:SpecifiedTradeProduct/ram:GlobalID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:SpecifiedTradeProduct/ram:GlobalID/@schemeID!='' or not (ram:SpecifiedTradeProduct/ram:GlobalID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-64]-The Item standard identifier (BT-157) shall have a Scheme identifier.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedTradeProduct/ram:DesignatedProductClassification/ram:ClassCode/@listID!='') or not (ram:SpecifiedTradeProduct/ram:DesignatedProductClassification)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedTradeProduct/ram:DesignatedProductClassification/ram:ClassCode/@listID!='') or not (ram:SpecifiedTradeProduct/ram:DesignatedProductClassification)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-65]-The Item classification identifier (BT-158) shall have a Scheme identifier.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[upper-case(ram:TypeCode) = 'VAT']/ram:CategoryCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-04]-Each Invoice line (BG-25) shall be categorized with an Invoiced item VAT category code (BT-151).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-23]-The allowed maximum number of decimals for the Invoice line net amount (BT-131) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M13"/>
   <xsl:template match="@*|node()" priority="-2" mode="M13">
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:PayeeTradeParty" priority="1000" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//ram:PayeeTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:Name) and (not(ram:Name = ../ram:SellerTradeParty/ram:Name) and not(ram:ID = ../ram:SellerTradeParty/ram:ID) and not(ram:SpecifiedLegalOrganization/ram:ID = ../ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:Name) and (not(ram:Name = ../ram:SellerTradeParty/ram:Name) and not(ram:ID = ../ram:SellerTradeParty/ram:ID) and not(ram:SpecifiedLegalOrganization/ram:ID = ../ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-17]-The Payee name (BT-59) shall be provided in the Invoice, if the Payee (BG-10) is different from the Seller (BG-4).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M14"/>
   <xsl:template match="@*|node()" priority="-2" mode="M14">
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SellerTaxRepresentativeTradeParty"
                 priority="1000"
                 mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SellerTaxRepresentativeTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:Name)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:Name)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-18]-The Seller tax representative name (BT-62) shall be provided in the Invoice, if the Seller (BG-4) has a Seller tax representative party (BG-11).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:PostalTradeAddress)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:PostalTradeAddress)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-19]-The Seller tax representative postal address (BG-12) shall be provided in the Invoice, if the Seller (BG-4) has a Seller tax representative party (BG-11).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:PostalTradeAddress/ram:CountryID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:PostalTradeAddress/ram:CountryID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-20]-The Seller tax representative postal address (BG-12) shall contain a Tax representative country code (BT-69), if the Seller (BG-4) has a Seller tax representative party (BG-11).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-56]-Each Seller tax representative party (BG-11) shall have a Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M15"/>
   <xsl:template match="@*|node()" priority="-2" mode="M15">
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SellerTradeParty" priority="1000" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SellerTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:ID) or (ram:GlobalID) or (ram:SpecifiedLegalOrganization/ram:ID) or (ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:ID) or (ram:GlobalID) or (ram:SpecifiedLegalOrganization/ram:ID) or (ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-26]-In order for the buyer to automatically identify a supplier, the Seller identifier (BT-29), the Seller legal registration identifier (BT-30) and/or the Seller VAT identifier (BT-31) shall be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M16"/>
   <xsl:template match="@*|node()" priority="-2" mode="M16">
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod"
                 priority="1000"
                 mode="M17">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:EndDateTime/udt:DateTimeString[@format = '102']) &gt;= (ram:StartDateTime/udt:DateTimeString[@format = '102']) or not (ram:EndDateTime) or not (ram:StartDateTime)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:EndDateTime/udt:DateTimeString[@format = '102']) &gt;= (ram:StartDateTime/udt:DateTimeString[@format = '102']) or not (ram:EndDateTime) or not (ram:StartDateTime)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-30]-If both Invoice line period start date (BT-134) and Invoice line period end date (BT-135) are given then the Invoice line period end date (BT-135) shall be later or equal to the Invoice line period start date (BT-134).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:StartDateTime) or (ram:EndDateTime)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:StartDateTime) or (ram:EndDateTime)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-20]-If Invoice line period (BG-26) is used, the Invoice line period start date (BT-134) or the Invoice line period end date (BT-135) shall be filled, or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M17"/>
   <xsl:template match="@*|node()" priority="-2" mode="M17">
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'false']"
                 priority="1000"
                 mode="M18">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'false']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-42]-Each Invoice line allowance (BG-27) shall have an Invoice line allowance reason (BT-139) or an Invoice line allowance reason code (BT-140).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M18"/>
   <xsl:template match="@*|node()" priority="-2" mode="M18">
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'false']&#xD;&#xA;"
                 priority="1000"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'false']&#xD;&#xA;"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ActualAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(../ram:ActualAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-41]-Each Invoice line allowance (BG-27) shall have an Invoice line allowance amount (BT-136).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-07]-Invoice line allowance reason code (BT-140) and Invoice line allowance reason (BT-139) shall indicate the same type of allowance reason.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-23]-Each Invoice line allowance (BG-27) shall contain an Invoice line allowance reason (BT-139) or an Invoice line allowance reason code (BT-140), or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-24]-The allowed maximum number of decimals for the Invoice line allowance amount (BT-136) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-25]-The allowed maximum number of decimals for the Invoice line allowance base amount (BT-137) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M19"/>
   <xsl:template match="@*|node()" priority="-2" mode="M19">
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'true']"
                 priority="1000"
                 mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ChargeIndicator[udt:Indicator = 'true']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ActualAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(../ram:ActualAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-43]-Each Invoice line charge (BG-28) shall have an Invoice line charge amount (BT-141).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-44]-Each Invoice line charge (BG-28) shall have an Invoice line charge reason (BT-144) or an Invoice line charge reason code (BT-145).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-08]-Invoice line charge reason code (BT-145) and Invoice line charge reason (BT-144) shall indicate the same type of charge reason.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:Reason) or (../ram:ReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:Reason) or (../ram:ReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-24]-Each Invoice line charge (BG-28) shall contain an Invoice line charge reason (BT-144) or an Invoice line charge reason code (BT-145), or both.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:ActualAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-27]-The allowed maximum number of decimals for the Invoice line charge amount (BT-141) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(../ram:BasisAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-28]-The allowed maximum number of decimals for the Invoice line charge base amount (BT-142) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M20"/>
   <xsl:template match="@*|node()" priority="-2" mode="M20">
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']"
                 priority="1000"
                 mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="contains(' 1A AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BL BJ BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH EL ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS XI YE YT ZA ZM ZW ', concat(' ', substring(.,1,2), ' '))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="contains(' 1A AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BL BJ BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH EL ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS XI YE YT ZA ZM ZW ', concat(' ', substring(.,1,2), ' '))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-09]-The Seller VAT identifier (BT-31), the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48) shall have a prefix in accordance with ISO code ISO 3166-1 alpha-2 by which the country of issue may be identified. Nevertheless, Greece may use the prefix ‘EL’.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M21"/>
   <xsl:template match="@*|node()" priority="-2" mode="M21">
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge"
                 priority="1000"
                 mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:ChargeIndicator)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:ChargeIndicator)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[CII-SR-463]-Each Specified Trade Allowance Charge (BG-20)(BG-21) shall contain a Charge Indicator.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M22"/>
   <xsl:template match="@*|node()" priority="-2" mode="M22">
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'AE']"
                 priority="1000"
                 mode="M23">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'AE']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Reverse charge" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48) and/or the Buyer legal registration identifier (BT-47).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Reverse charge" the Document level allowance VAT rate (BT-96) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M23"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M23"/>
   <xsl:template match="@*|node()" priority="-2" mode="M23">
      <xsl:apply-templates select="*" mode="M23"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'E']"
                 priority="1000"
                 mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'E']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Exempt from VAT" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Exempt from VAT", the Document level allowance VAT rate (BT-96) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M24"/>
   <xsl:template match="@*|node()" priority="-2" mode="M24">
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'G']"
                 priority="1000"
                 mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'G']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Export outside the EU" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Export outside the EU" the Document level allowance VAT rate (BT-96) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M25"/>
   <xsl:template match="@*|node()" priority="-2" mode="M25">
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'K']"
                 priority="1000"
                 mode="M26">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'K']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Intra-community supply" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Intra-community supply" the Document level allowance VAT rate (BT-96) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M26"/>
   <xsl:template match="@*|node()" priority="-2" mode="M26">
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'L']"
                 priority="1000"
                 mode="M27">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'L']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "IGIC" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "IGIC" the Document level allowance VAT rate (BT-96) shall be 0 (zero) or greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M27"/>
   <xsl:template match="@*|node()" priority="-2" mode="M27">
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'M']"
                 priority="1000"
                 mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'M']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "IPSI" shall contain the Seller VAT Identifier (BT-31), the Seller Tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt;= 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "IPSI" the Document level allowance VAT rate (BT-96) shall be 0 (zero) or greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M28"/>
   <xsl:template match="@*|node()" priority="-2" mode="M28">
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'O']"
                 priority="1000"
                 mode="M29">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'O']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test=" not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Not subject to VAT" shall not contain the Seller VAT identifier (BT-31), the Seller tax representative VAT identifier (BT-63) or the Buyer VAT identifier (BT-48).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:RateApplicablePercent)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:RateApplicablePercent)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-06]-A Document level allowance (BG-20) where VAT category code (BT-95) is "Not subject to VAT" shall not contain a Document level allowance VAT rate (BT-96).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M29"/>
   <xsl:template match="@*|node()" priority="-2" mode="M29">
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'S']"
                 priority="1000"
                 mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'S']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Standard rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Standard rated" the Document level allowance VAT rate (BT-96) shall be greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M30"/>
   <xsl:template match="@*|node()" priority="-2" mode="M30">
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'Z']"
                 priority="1000"
                 mode="M31">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:CategoryTradeTax[ram:CategoryCode = 'Z']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-03]-An Invoice that contains a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Zero rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-06]-In a Document level allowance (BG-20) where the Document level allowance VAT category code (BT-95) is "Zero rated" the Document level allowance VAT rate (BT-96) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M31"/>
   <xsl:template match="@*|node()" priority="-2" mode="M31">
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'AE']"
                 priority="1000"
                 mode="M32">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'AE']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Reverse charge" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48) and/or the Buyer legal registration identifier (BT-47).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Reverse charge" the Document level charge VAT rate (BT-103) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M32"/>
   <xsl:template match="@*|node()" priority="-2" mode="M32">
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'E']"
                 priority="1000"
                 mode="M33">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'E']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Exempt from VAT" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Exempt from VAT", the Document level charge VAT rate (BT-103) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M33"/>
   <xsl:template match="@*|node()" priority="-2" mode="M33">
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'G']"
                 priority="1000"
                 mode="M34">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'G']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Export outside the EU" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Export outside the EU" the Document level charge VAT rate (BT-103) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M34"/>
   <xsl:template match="@*|node()" priority="-2" mode="M34">
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'K']"
                 priority="1000"
                 mode="M35">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'K']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Intra-community supply" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Intra-community supply" the Document level charge VAT rate (BT-103) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M35"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M35"/>
   <xsl:template match="@*|node()" priority="-2" mode="M35">
      <xsl:apply-templates select="*" mode="M35"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'L']"
                 priority="1000"
                 mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'L']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "IGIC" shall contain the Seller VAT Identifier (BT-31), the Seller Tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "IGIC" the Document level charge VAT rate (BT-103) shall be 0 (zero) or greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M36"/>
   <xsl:template match="@*|node()" priority="-2" mode="M36">
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'M']"
                 priority="1000"
                 mode="M37">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'M']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "IPSI" shall contain the Seller VAT Identifier (BT-31), the Seller Tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt;= 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "IPSI" the Document level charge VAT rate (BT-103) shall be 0 (zero) or greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M37"/>
   <xsl:template match="@*|node()" priority="-2" mode="M37">
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'O']"
                 priority="1000"
                 mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'O']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test=" not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Not subject to VAT" shall not contain the Seller VAT identifier (BT-31), the Seller tax representative VAT identifier (BT-63) or the Buyer VAT identifier (BT-48).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:RateApplicablePercent)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:RateApplicablePercent)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-07]-A Document level charge (BG-21) where the VAT category code (BT-102) is "Not subject to VAT" shall not contain a Document level charge VAT rate (BT-103).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M38"/>
   <xsl:template match="@*|node()" priority="-2" mode="M38">
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'S']"
                 priority="1000"
                 mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'S']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-04]-An Invoice that contains a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Standard rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Standard rated" the Document level charge VAT rate (BT-103) shall be greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M39"/>
   <xsl:template match="@*|node()" priority="-2" mode="M39">
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'Z']"
                 priority="1000"
                 mode="M40">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:CategoryTradeTax[ram:CategoryCode = 'Z']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-04]-An Invoice that contains a Document level charge where the Document level charge VAT category code (BT-102) is "Zero rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-07]-In a Document level charge (BG-21) where the Document level charge VAT category code (BT-102) is "Zero rated" the Document level charge VAT rate (BT-103) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M40"/>
   <xsl:template match="@*|node()" priority="-2" mode="M40">
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeSettlementHeaderMonetarySummation"
                 priority="1000"
                 mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeSettlementHeaderMonetarySummation"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="xs:decimal(ram:LineTotalAmount) = round(xs:decimal(sum(../../ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)) * xs:decimal(100)) div xs:decimal(100)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="xs:decimal(ram:LineTotalAmount) = round(xs:decimal(sum(../../ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)) * xs:decimal(100)) div xs:decimal(100)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-10]-Sum of Invoice line net amount (BT-106) = Σ Invoice line net amount (BT-131).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:LineTotalAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:LineTotalAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-12]-An Invoice shall have the Sum of Invoice line net amount (BT-106).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:TaxBasisTotalAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:TaxBasisTotalAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-13]-An Invoice shall have the Invoice total amount without VAT (BT-109).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:GrandTotalAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:GrandTotalAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-14]-An Invoice shall have the Invoice total amount with VAT (BT-112).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:DuePayableAmount)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:DuePayableAmount)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-15]-An Invoice shall have the Amount due for payment (BT-115).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false'])and not (ram:AllowanceTotalAmount)) or ram:AllowanceTotalAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:ActualAmount)* 10 * 10 ) div 100)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false'])and not (ram:AllowanceTotalAmount)) or ram:AllowanceTotalAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']/ram:ActualAmount)* 10 * 10 ) div 100)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-11]-Sum of allowances on document level (BT-107) = Σ Document level allowance amount (BT-92).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true'])and not (ram:ChargeTotalAmount)) or (round (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount * 10 * 10) div 100)= &#xD;&#xA;round(((round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:ActualAmount)* 10 * 10 ) div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedLogisticsServiceCharge/ram:AppliedAmount)* 10 * 10 ) div 100))*10*10) div 100"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true'])and not (ram:ChargeTotalAmount)) or (round (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount * 10 * 10) div 100)= round(((round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']/ram:ActualAmount)* 10 * 10 ) div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedLogisticsServiceCharge/ram:AppliedAmount)* 10 * 10 ) div 100))*10*10) div 100">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-12]-Sum of charges on document level (BT-108) = Σ Document level charge amount (BT-99).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) - xs:decimal(ram:AllowanceTotalAmount) + xs:decimal(ram:ChargeTotalAmount)) *10 * 10) div 100) or &#xD;&#xA;    ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) - xs:decimal(ram:AllowanceTotalAmount)) *10 * 10) div 100)  and not (ram:ChargeTotalAmount)) or &#xD;&#xA;    ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) + xs:decimal(ram:ChargeTotalAmount)) *10 * 10) div 100)  and not (ram:AllowanceTotalAmount)) or &#xD;&#xA;    ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount))  *10 * 10) div 100) and not (ram:ChargeTotalAmount) and not (ram:AllowanceTotalAmount))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) - xs:decimal(ram:AllowanceTotalAmount) + xs:decimal(ram:ChargeTotalAmount)) *10 * 10) div 100) or ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) - xs:decimal(ram:AllowanceTotalAmount)) *10 * 10) div 100) and not (ram:ChargeTotalAmount)) or ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount) + xs:decimal(ram:ChargeTotalAmount)) *10 * 10) div 100) and not (ram:AllowanceTotalAmount)) or ((xs:decimal(ram:TaxBasisTotalAmount) = round((xs:decimal(ram:LineTotalAmount)) *10 * 10) div 100) and not (ram:ChargeTotalAmount) and not (ram:AllowanceTotalAmount))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-13]-Invoice total amount without VAT (BT-109) = Σ Invoice line net amount (BT-131) - Sum of allowances on document level (BT-107) + Sum of charges on document level (BT-108).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="every $Currency &#xD;&#xA;                                in rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode&#xD;&#xA;                                satisfies (  &#xD;&#xA;                                  count ( rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=$Currency] ) eq 1 and  &#xD;&#xA;                                  (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:GrandTotalAmount) = round( &#xD;&#xA;                                    (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxBasisTotalAmount) + &#xD;&#xA;                                    (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxTotalAmount[@currencyID=$Currency]))) * 10 * 10) div 100)) or&#xD;&#xA;                                (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:GrandTotalAmount) = (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxBasisTotalAmount)))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="every $Currency in rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode satisfies ( count ( rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=$Currency] ) eq 1 and (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:GrandTotalAmount) = round( (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxBasisTotalAmount) + (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxTotalAmount[@currencyID=$Currency]))) * 10 * 10) div 100)) or (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:GrandTotalAmount) = (//ram:SpecifiedTradeSettlementHeaderMonetarySummation/xs:decimal(ram:TaxBasisTotalAmount)))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-15]-Invoice total amount with VAT (BT-112) = Invoice total amount without VAT (BT-109) + Invoice total VAT amount (BT-110).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) - xs:decimal(ram:TotalPrepaidAmount) + xs:decimal(ram:RoundingAmount)) or &#xD;&#xA;    ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) + xs:decimal(ram:RoundingAmount)) and not (xs:decimal(ram:TotalPrepaidAmount))) or &#xD;&#xA;    ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) - xs:decimal(ram:TotalPrepaidAmount)) and not (xs:decimal(ram:RoundingAmount))) or &#xD;&#xA;    ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount)) and not (xs:decimal(ram:TotalPrepaidAmount)) and not (xs:decimal(ram:RoundingAmount)))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) - xs:decimal(ram:TotalPrepaidAmount) + xs:decimal(ram:RoundingAmount)) or ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) + xs:decimal(ram:RoundingAmount)) and not (xs:decimal(ram:TotalPrepaidAmount))) or ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount) - xs:decimal(ram:TotalPrepaidAmount)) and not (xs:decimal(ram:RoundingAmount))) or ((xs:decimal(ram:DuePayableAmount) = xs:decimal(ram:GrandTotalAmount)) and not (xs:decimal(ram:TotalPrepaidAmount)) and not (xs:decimal(ram:RoundingAmount)))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-16]-Amount due for payment (BT-115) = Invoice total amount with VAT (BT-112) -Paid amount (BT-113) +Rounding amount (BT-114).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:LineTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:LineTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-09]-The allowed maximum number of decimals for the Sum of Invoice line net amount (BT-106) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:AllowanceTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:AllowanceTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-10]-The allowed maximum number of decimals for the Sum of allowanced on document level (BT-107) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:ChargeTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:ChargeTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-11]-The allowed maximum number of decimals for the Sum of charges on document level (BT-108) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:TaxBasisTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:TaxBasisTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-12]-The allowed maximum number of decimals for the Invoice total amount without VAT (BT-109) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:TaxTotalAmount) or ram:TaxTotalAmount[(@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode and . = round(. * 100) div 100) or not (@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode)]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:TaxTotalAmount) or ram:TaxTotalAmount[(@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode and . = round(. * 100) div 100) or not (@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode)]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-13]-The allowed maximum number of decimals for the Invoice total VAT amount (BT-110) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:GrandTotalAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:GrandTotalAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-14]-The allowed maximum number of decimals for the Invoice total amount with VAT (BT-112) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:TaxTotalAmount) or ram:TaxTotalAmount[(@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode and . = round(. * 100) div 100) or not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode)]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:TaxTotalAmount) or ram:TaxTotalAmount[(@currencyID =/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode and . = round(. * 100) div 100) or not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode)]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-15]-The allowed maximum number of decimals for the Invoice total VAT amount in accounting currency (BT-111) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:TotalPrepaidAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:TotalPrepaidAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-16]-The allowed maximum number of decimals for the Paid amount (BT-113) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:RoundingAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:RoundingAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-17]-The allowed maximum number of decimals for the Rounding amount (BT-114) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length(substring-after(ram:DuePayableAmount,'.'))&lt;=2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(substring-after(ram:DuePayableAmount,'.'))&lt;=2">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-DEC-18]-The allowed maximum number of decimals for the Amount due for payment (BT-115) is 2.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode) or (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode and (ram:TaxTotalAmount/@currencyID = /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode) and not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode = /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode) or (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode and (ram:TaxTotalAmount/@currencyID = /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode) and not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode = /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-53]-If the VAT accounting currency code (BT-6) is present, then the Invoice total VAT amount in accounting currency (BT-111) shall be provided.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M41"/>
   <xsl:template match="@*|node()" priority="-2" mode="M41">
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode]"
                 priority="1000"
                 mode="M42">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test=". = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount)*10*10)div 100)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test=". = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount)*10*10)div 100)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-14]-Invoice total VAT amount (BT-110) = Σ VAT category tax amount (BT-117).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M42"/>
   <xsl:template match="@*|node()" priority="-2" mode="M42">
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeSettlementPaymentMeans"
                 priority="1000"
                 mode="M43">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeSettlementPaymentMeans"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:TypeCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(ram:TypeCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-49]-A Payment instruction (BG-16) shall specify the Payment means type code (BT-81).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:PayeeSpecifiedCreditorFinancialInstitution or ram:PayerSpecifiedDebtorFinancialInstitution) or (not(ram:PayeeSpecifiedCreditorFinancialInstitution) and not(ram:PayerSpecifiedDebtorFinancialInstitution))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:PayeeSpecifiedCreditorFinancialInstitution or ram:PayerSpecifiedDebtorFinancialInstitution) or (not(ram:PayeeSpecifiedCreditorFinancialInstitution) and not(ram:PayerSpecifiedDebtorFinancialInstitution))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[CII-SR-464]-Only one BT-86 element is allowed on an invoice.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M43"/>
   <xsl:template match="@*|node()" priority="-2" mode="M43">
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeSettlementPaymentMeans[ram:TypeCode='30' or ram:TypeCode='58']/ram:PayeePartyCreditorFinancialAccount"
                 priority="1000"
                 mode="M44">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeSettlementPaymentMeans[ram:TypeCode='30' or ram:TypeCode='58']/ram:PayeePartyCreditorFinancialAccount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:IBANID) or (ram:ProprietaryID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:IBANID) or (ram:ProprietaryID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-50]-A Payment account identifier (BT-84) shall be present if Credit transfer (BG-16) information is provided in the Invoice.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:IBANID) or (ram:ProprietaryID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:IBANID) or (ram:ProprietaryID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-61]-If the Payment means type code (BT-81) means SEPA credit transfer, Local credit transfer or Non-SEPA international credit transfer, the Payment account identifier (BT-84) shall be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M44"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M44"/>
   <xsl:template match="@*|node()" priority="-2" mode="M44">
      <xsl:apply-templates select="*" mode="M44"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//ram:SpecifiedTradeSettlementPaymentMeans[some $code in tokenize('30 58', '\s')  satisfies normalize-space(ram:TypeCode) = $code]"
                 priority="1000"
                 mode="M45">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//ram:SpecifiedTradeSettlementPaymentMeans[some $code in tokenize('30 58', '\s')  satisfies normalize-space(ram:TypeCode) = $code]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:PayeePartyCreditorFinancialAccount/ram:IBANID or ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID) and not(ram:PayeePartyCreditorFinancialAccount/ram:IBANID and ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID)&#xD;&#xA;"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:PayeePartyCreditorFinancialAccount/ram:IBANID or ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID) and not(ram:PayeePartyCreditorFinancialAccount/ram:IBANID and ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-27]-Either the IBAN or a Proprietary ID (BT-84) shall be used.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M45"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M45"/>
   <xsl:template match="@*|node()" priority="-2" mode="M45">
      <xsl:apply-templates select="*" mode="M45"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement"
                 priority="1000"
                 mode="M46">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:ApplicableTradeTax"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ram:ApplicableTradeTax">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-18]-An Invoice shall at least have one VAT breakdown group (BG-23).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M46"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M46"/>
   <xsl:template match="@*|node()" priority="-2" mode="M46">
      <xsl:apply-templates select="*" mode="M46"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'AE']"
                 priority="1000"
                 mode="M47">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'AE']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'AE']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'AE']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'AE']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'AE']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='AE']/xs:decimal(ram:ActualAmount))*10*10)div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-08]-In a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Reverse charge" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amounts (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Reverse charge".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="../ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="../ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Reverse charge" shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "Reverse charge" shall have a VAT exemption reason code (BT-121), meaning "Reverse charge" or the VAT exemption reason text (BT-120) "Reverse charge" (or the equivalent standard text in another language).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M47"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M47"/>
   <xsl:template match="@*|node()" priority="-2" mode="M47">
      <xsl:apply-templates select="*" mode="M47"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'E']"
                 priority="1000"
                 mode="M48">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'E']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:BasisAmount - 1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'E']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount + 1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'E']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:BasisAmount - 1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'E']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount + 1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'E']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='E']/xs:decimal(ram:ActualAmount))*10*10)div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-08]-In a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Exempt from VAT" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amounts (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Exempt from VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="../ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="../ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-09]-The VAT category tax amount (BT-117) In a VAT breakdown (BG-23) where the VAT category code (BT-118) equals "Exempt from VAT" shall equal 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "Exempt from VAT" shall have a VAT exemption reason code (BT-121) or a VAT exemption reason text (BT-120).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M48"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M48"/>
   <xsl:template match="@*|node()" priority="-2" mode="M48">
      <xsl:apply-templates select="*" mode="M48"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'G']"
                 priority="1000"
                 mode="M49">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[. = 'G']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'G']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'G']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:BasisAmount -1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'G']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100)) and (../ram:BasisAmount +1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'G']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='G']/xs:decimal(ram:ActualAmount))*10*10)div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-08]-In a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Export outside the EU" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amounts (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Export outside the EU".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="../ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="../ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Export outside the EU" shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-10]-A VAT Breakdown (BG-23) with the VAT Category code (BT-118) "Export outside the EU" shall have a VAT exemption reason code (BT-121), meaning "Export outside the EU" or the VAT exemption reason text (BT-120) "Export outside the EU" (or the equivalent standard text in another language).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M49"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M49"/>
   <xsl:template match="@*|node()" priority="-2" mode="M49">
      <xsl:apply-templates select="*" mode="M49"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[.= 'K']"
                 priority="1000"
                 mode="M50">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[.= 'K']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:BasisAmount - 1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'K']/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100)) and (../ram:BasisAmount + 1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'K']/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:BasisAmount - 1 &lt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'K']/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100)) and (../ram:BasisAmount + 1 &gt; (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'K']/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount)*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='K']/ram:ActualAmount)*10*10)div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-08]-In a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Intra-community supply" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amounts (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Intra-community supply".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="../ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="../ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Intra-community supply" shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(../ram:ExemptionReason) or (../ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-10]-A VAT Breakdown (BG-23) with the VAT Category code (BT-118) "Intra-community supply" shall have a VAT exemption reason code (BT-121), meaning "Intra-community supply" or the VAT exemption reason text (BT-120) "Intra-community supply" (or the equivalent standard text in another language).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString) or (../../ram:BillingSpecifiedPeriod/ram:StartDateTime) or (../../ram:BillingSpecifiedPeriod/ram:EndDateTime)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString) or (../../ram:BillingSpecifiedPeriod/ram:StartDateTime) or (../../ram:BillingSpecifiedPeriod/ram:EndDateTime)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-11]-In an Invoice with a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Intra-community supply" the Actual delivery date (BT-72) or the Invoicing period (BG-14) shall not be blank.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-12]-In an Invoice with a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Intra-community supply" the Deliver to country code (BT-80) shall not be blank.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M50"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M50"/>
   <xsl:template match="@*|node()" priority="-2" mode="M50">
      <xsl:apply-templates select="*" mode="M50"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'L']"
                 priority="1000"
                 mode="M51">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'L']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'L' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='L' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='L' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'L' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='L' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='L' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-08]-For each different value of VAT category rate (BT-119) where the VAT category code (BT-118) is "IGIC", the VAT category taxable amount (BT-116) in a VAT breakdown (BG-23) shall equal the sum of Invoice line net amounts (BT-131) plus the sum of document level charge amounts (BT-99) minus the sum of document level allowance amounts (BT-92) where the VAT category code (BT-151, BT-102, BT-95) is "IGIC" and the VAT rate (BT-152, BT-103, BT-96) equals the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where VAT category code (BT-118) is "IGIC" shall equal the VAT category taxable amount (BT-116) multiplied by the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:ExemptionReason) and not (ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:ExemptionReason) and not (ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "IGIC" shall not have a VAT exemption reason code (BT-121) or VAT exemption reason text (BT-120).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M51"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M51"/>
   <xsl:template match="@*|node()" priority="-2" mode="M51">
      <xsl:apply-templates select="*" mode="M51"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'M']"
                 priority="1000"
                 mode="M52">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'M']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'M' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='M' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='M' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="every $rate in ../ram:RateApplicablePercent/xs:decimal(.) satisfies (../ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'M' and ram:ApplicableTradeTax/xs:decimal(ram:RateApplicablePercent) =$rate]/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount)) * 10 * 10) div 100 + round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=true() and ram:CategoryTradeTax/ram:CategoryCode='M' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100 - round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=false() and ram:CategoryTradeTax/ram:CategoryCode='M' and ram:CategoryTradeTax/xs:decimal(ram:RateApplicablePercent)=$rate]/xs:decimal(ram:ActualAmount)) * 10 * 10) div 100))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-08]-For each different value of VAT category rate (BT-119) where the VAT category code (BT-118) is "IPSI", the VAT category taxable amount (BT-116) in a VAT breakdown (BG-23) shall equal the sum of Invoice line net amounts (BT-131) plus the sum of document level charge amounts (BT-99) minus the sum of document level allowance amounts (BT-92) where the VAT category code (BT-151, BT-102, BT-95) is "IPSI" and the VAT rate (BT-152, BT-103, BT-96) equals the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="true()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where VAT category code (BT-118) is "IPSI" shall equal the VAT category taxable amount (BT-116) multiplied by the VAT category rate (BT-119).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:ExemptionReason) and not (ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:ExemptionReason) and not (ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) "IPSI" shall not have a VAT exemption reason code (BT-121) or VAT exemption reason text (BT-120).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M52"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M52"/>
   <xsl:template match="@*|node()" priority="-2" mode="M52">
      <xsl:apply-templates select="*" mode="M52"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'O']"
                 priority="1000"
                 mode="M53">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'O']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'O']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='O']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='O']/xs:decimal(ram:ActualAmount))*10*10)div 100)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:BasisAmount = (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement[ram:ApplicableTradeTax/ram:CategoryCode = 'O']/ram:SpecifiedTradeSettlementLineMonetarySummation/xs:decimal(ram:LineTotalAmount))*10*10)div 100) + (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=true() and ram:CategoryTradeTax/ram:CategoryCode='O']/xs:decimal(ram:ActualAmount))*10*10)div 100) - (round(sum(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[(ram:ChargeIndicator/udt:Indicator cast as xs:boolean)=false() and ram:CategoryTradeTax/ram:CategoryCode='O']/xs:decimal(ram:ActualAmount))*10*10)div 100)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-08]-In a VAT breakdown (BG-23) where the VAT category code (BT-118) is " Not subject to VAT" the VAT category taxable amount (BT-116) shall equal the sum of Invoice line net amounts (BT-131) minus the sum of Document level allowance amounts (BT-92) plus the sum of Document level charge amounts (BT-99) where the VAT category codes (BT-151, BT-95, BT-102) are "Not subject to VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:CalculatedAmount = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ram:CalculatedAmount = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-09]-The VAT category tax amount (BT-117) in a VAT breakdown (BG-23) where the VAT category code (BT-118) is "Not subject to VAT" shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:ExemptionReason) or (ram:ExemptionReasonCode)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:ExemptionReason) or (ram:ExemptionReasonCode)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-10]-A VAT Breakdown (BG-23) with VAT Category code (BT-118) " Not subject to VAT" shall have a VAT exemption reason code (BT-121), meaning " Not subject to VAT" or a VAT exemption reason text (BT-120) " Not subject to VAT" (or the equivalent standard text in another language).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//ram:ApplicableTradeTax[ram:CategoryCode != 'O'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(//ram:ApplicableTradeTax[ram:CategoryCode != 'O'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-11]-An Invoice that contains a VAT breakdown group (BG-23) with a VAT category code (BT-118) "Not subject to VAT" shall not contain other VAT breakdown groups (BG-23).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//ram:ApplicableTradeTax[ram:CategoryCode != 'O'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(//ram:ApplicableTradeTax[ram:CategoryCode != 'O'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-12]-An Invoice that contains a VAT breakdown group (BG-23) with a VAT category code (BT-118) "Not subject to VAT" shall not contain an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is not "Not subject to VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//ram:CategoryTradeTax[ram:CategoryCode != 'O'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(//ram:CategoryTradeTax[ram:CategoryCode != 'O'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-13]-An Invoice that contains a VAT breakdown group (BG-23) with a VAT category code (BT-118) "Not subject to VAT" shall not contain Document level allowances (BG-20) where Document level allowance VAT category code (BT-95) is not "Not subject to VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//ram:CategoryTradeTax[ram:CategoryCode != 'O'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(//ram:CategoryTradeTax[ram:CategoryCode != 'O'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-14]-An Invoice that contains a VAT breakdown group (BG-23) with a VAT category code (BT-118) "Not subject to VAT" shall not contain Document level charges (BG-21) where Document level charge VAT category code (BT-102) is not "Not subject to VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M53"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M53"/>
   <xsl:template match="@*|node()" priority="-2" mode="M53">
      <xsl:apply-templates select="*" mode="M53"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'AE']"
                 priority="1000"
                 mode="M54">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'AE']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Reverse charge" shall contain the Seller VAT Identifier (BT-31), the Seller Tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48) and/or the Buyer legal registration identifier (BT-47).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Reverse charge" the Invoiced item VAT rate (BT-152) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M54"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M54"/>
   <xsl:template match="@*|node()" priority="-2" mode="M54">
      <xsl:apply-templates select="*" mode="M54"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'E']"
                 priority="1000"
                 mode="M55">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'E']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Exempt from VAT" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Exempt from VAT", the Invoiced item VAT rate (BT-152) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M55"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M55"/>
   <xsl:template match="@*|node()" priority="-2" mode="M55">
      <xsl:apply-templates select="*" mode="M55"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'G']"
                 priority="1000"
                 mode="M56">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'G']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Export outside the EU" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Export outside the EU" the Invoiced item VAT rate (BT-152) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M56"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M56"/>
   <xsl:template match="@*|node()" priority="-2" mode="M56">
      <xsl:apply-templates select="*" mode="M56"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'K']"
                 priority="1000"
                 mode="M57">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'K']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'] or //ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and //ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Intra-community supply" shall contain the Seller VAT Identifier (BT-31) or the Seller tax representative VAT identifier (BT-63) and the Buyer VAT identifier (BT-48).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Intracommunity supply" the Invoiced item VAT rate (BT-152) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M57"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M57"/>
   <xsl:template match="@*|node()" priority="-2" mode="M57">
      <xsl:apply-templates select="*" mode="M57"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'L']"
                 priority="1000"
                 mode="M58">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'L']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "IGIC" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "IGIC" the invoiced item VAT rate (BT-152) shall be greater than 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M58"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M58"/>
   <xsl:template match="@*|node()" priority="-2" mode="M58">
      <xsl:apply-templates select="*" mode="M58"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'M']"
                 priority="1000"
                 mode="M59">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'M']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "IPSI" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt;= 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt;= 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "IPSI" the Invoiced item VAT rate (BT-152) shall be 0 (zero) or greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M59"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M59"/>
   <xsl:template match="@*|node()" priority="-2" mode="M59">
      <xsl:apply-templates select="*" mode="M59"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'O']"
                 priority="1000"
                 mode="M60">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'O']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test=" not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']) and not (//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA'])">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Not subject to VAT" shall not contain the Seller VAT identifier (BT-31), the Seller tax representative VAT identifier (BT-63) or the Buyer VAT identifier (BT-46).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:RateApplicablePercent)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:RateApplicablePercent)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-05]-An Invoice line (BG-25) where the VAT category code (BT-151) is "Not subject to VAT" shall not contain an Invoiced item VAT rate (BT-152).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M60"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M60"/>
   <xsl:template match="@*|node()" priority="-2" mode="M60">
      <xsl:apply-templates select="*" mode="M60"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'S']"
                 priority="1000"
                 mode="M61">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'S']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-02]-An Invoice that contains an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Standard rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent &gt; 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent &gt; 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Standard rated" the Invoiced item VAT rate (BT-152) shall be greater than zero.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M61"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M61"/>
   <xsl:template match="@*|node()" priority="-2" mode="M61">
      <xsl:apply-templates select="*" mode="M61"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'Z']"
                 priority="1000"
                 mode="M62">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode = 'Z']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = ('VA', 'FC')] or /rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID[@schemeID = 'VA']">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-02]-An Invoice that contains an Invoice line where the Invoiced item VAT category code (BT-151) is "Zero rated" shall contain the Seller VAT Identifier (BT-31), the Seller tax registration identifier (BT-32) and/or the Seller tax representative VAT identifier (BT-63).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="ram:RateApplicablePercent = 0"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ram:RateApplicablePercent = 0">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-05]-In an Invoice line (BG-25) where the Invoiced item VAT category code (BT-151) is "Zero rated" the Invoiced item VAT rate (BT-152) shall be 0 (zero).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M62"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M62"/>
   <xsl:template match="@*|node()" priority="-2" mode="M62">
      <xsl:apply-templates select="*" mode="M62"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="//udt:DateTimeString[@format = '102']"
                 priority="1000"
                 mode="M63">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//udt:DateTimeString[@format = '102']"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="matches(.,'^\s*(\d{4})(1[0-2]|0[1-9]){1}(3[01]|[12][0-9]|0[1-9]){1}\s*$')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="matches(.,'^\s*(\d{4})(1[0-2]|0[1-9]){1}(3[01]|[12][0-9]|0[1-9]){1}\s*$')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[CII-DT-097] - Date time string with format attribute 102 shall be YYYYMMDD.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M63"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M63"/>
   <xsl:template match="@*|node()" priority="-2" mode="M63">
      <xsl:apply-templates select="*" mode="M63"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice" priority="1000" mode="M64">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="//ram:IncludedSupplyChainTradeLineItem"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="//ram:IncludedSupplyChainTradeLineItem">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-16]-An Invoice shall have at least one Invoice line (BG-25).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(number(//ram:DuePayableAmount) &gt; 0 and ((//ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime) or (//ram:SpecifiedTradePaymentTerms/ram:Description))) or not(number(//ram:DuePayableAmount) &gt; 0)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(number(//ram:DuePayableAmount) &gt; 0 and ((//ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime) or (//ram:SpecifiedTradePaymentTerms/ram:Description))) or not(number(//ram:DuePayableAmount) &gt; 0)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-CO-25]-In case the Amount due for payment (BT-115) is positive, either the Payment due date (BT-9) or the Payment terms (BT-20) shall be present.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID != '')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID != '')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-01]-An Invoice shall have a Specification identifier (BT-24).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:ExchangedDocument/ram:ID !='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:ExchangedDocument/ram:ID !='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-02]-An Invoice shall have an Invoice number (BT-1).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString[@format='102']!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString[@format='102']!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-03]-An Invoice shall have an Invoice issue date (BT-2).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:ExchangedDocument/ram:TypeCode!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:ExchangedDocument/ram:TypeCode!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-04]-An Invoice shall have an Invoice type code (BT-3).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-05]-An Invoice shall have an Invoice currency code (BT-5).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-06]-An Invoice shall contain the Seller name (BT-27).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-07]-An Invoice shall contain the Buyer name (BT-44).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="//ram:SellerTradeParty/ram:PostalTradeAddress"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="//ram:SellerTradeParty/ram:PostalTradeAddress">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-08]-An Invoice shall contain the Seller postal address (BG-5).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID!=''"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID!=''">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-09]-The Seller postal address (BG-5) shall contain a Seller country code (BT-40).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="//ram:BuyerTradeParty/ram:PostalTradeAddress"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="//ram:BuyerTradeParty/ram:PostalTradeAddress">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-10]-An Invoice shall contain the Buyer postal address (BG-8).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="//ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID!=''"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="//ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID!=''">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-11]-The Buyer postal address shall contain a Buyer country code (BT-55).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication[1]/ram:URIID/@schemeID) != '' or not (rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="normalize-space(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication[1]/ram:URIID/@schemeID) != '' or not (rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-62]-The Seller electronic address (BT-34) shall have a Scheme identifier.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="normalize-space(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication[1]/ram:URIID/@schemeID) != '' or not (rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="normalize-space(rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication[1]/ram:URIID/@schemeID) != '' or not (rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-63]-The Buyer electronic address (BT-49) shall have a Scheme identifier.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) and     ((count(//ram:CategoryTradeTax[ram:CategoryCode='S']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='S']))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) and ((count(//ram:CategoryTradeTax[ram:CategoryCode='S']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='S'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='S']))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-S-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Standard rated" shall contain in the VAT breakdown (BG-23) at least one VAT category code (BT-118) equal with "Standard rated".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='Z'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='Z'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='Z'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='Z']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='Z'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-Z-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Zero rated" shall contain in the VAT breakdown (BG-23) exactly one VAT category code (BT-118) equal with "Zero rated".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='E'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='E'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='E'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='E']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='E'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-E-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is “Exempt from VAT” shall contain exactly one VAT breakdown (BG-23) with the VAT category code (BT-118) equal to "Exempt from VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='AE'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='AE'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='AE'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='AE']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='AE'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AE-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Reverse charge" shall contain in the VAT breakdown (BG-23) exactly one VAT category code (BT-118) equal with "VAT reverse charge".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='K'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='K'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='K'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='K']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='K'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-IC-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Intra-community supply" shall contain in the VAT breakdown (BG-23) exactly one VAT category code (BT-118) equal with "Intra-community supply".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='G'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='G'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=0 and count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=0 and count(//ram:CategoryTradeTax[ram:CategoryCode='G'])=0) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='G']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='G'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-G-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Export outside the EU" shall contain in the VAT breakdown (BG-23) exactly one VAT category code (BT-118) equal with "Export outside the EU".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O']) or ( &#xD;&#xA;    count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O'])=1 and &#xD;&#xA;    (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O']) or&#xD;&#xA;    exists(//ram:CategoryTradeTax[ram:CategoryCode='O'])))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O']) or ( count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O'])=1 and (exists(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='O']) or exists(//ram:CategoryTradeTax[ram:CategoryCode='O'])))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-O-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "Not subject to VAT" shall contain exactly one VAT breakdown group (BG-23) with the VAT category code (BT-118) equal to "Not subject to VAT".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) and &#xD;&#xA;    ((count(//ram:CategoryTradeTax[ram:CategoryCode='L']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='L']))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) and ((count(//ram:CategoryTradeTax[ram:CategoryCode='L']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='L'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='L']))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AF-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "IGIC" shall contain in the VAT breakdown (BG-23) at least one VAT category code (BT-118) equal with "IGIC".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) and &#xD;&#xA;    ((count(//ram:CategoryTradeTax[ram:CategoryCode='M']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='M']))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="((count(//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) &gt;=2 or not (//ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) and ((count(//ram:CategoryTradeTax[ram:CategoryCode='M']) + count(//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode='M'])) &gt;=2 or not (//ram:CategoryTradeTax[ram:CategoryCode='M']))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-AG-01]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is "IPSI" shall contain in the VAT breakdown (BG-23) at least one VAT category code (BT-118) equal with "IPSI".</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(not(//ram:CountryID != 'IT') and //ram:CategoryCode ='B') or (not(//ram:CategoryCode ='B'))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(not(//ram:CountryID != 'IT') and //ram:CategoryCode ='B') or (not(//ram:CategoryCode ='B'))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-B-01]-An Invoice where the VAT category code (BT-151, BT-95 or BT-102) is “Split payment” shall be a domestic Italian invoice.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(//ram:CategoryCode ='B' and (not(//ram:CategoryCode ='S'))) or (not(//ram:CategoryCode ='B'))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(//ram:CategoryCode ='B' and (not(//ram:CategoryCode ='S'))) or (not(//ram:CategoryCode ='B'))">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-B-02]-An Invoice that contains an Invoice line (BG-25), a Document level allowance (BG-20) or a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is “Split payment" shall not contain an invoice line (BG-25), a Document level allowance (BG-20) or  a Document level charge (BG-21) where the VAT category code (BT-151, BT-95 or BT-102) is “Standard rated”.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M64"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M64"/>
   <xsl:template match="@*|node()" priority="-2" mode="M64">
      <xsl:apply-templates select="*" mode="M64"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement"
                 priority="1000"
                 mode="M65">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:SellerTradeParty/ram:DefinedTradeContact/ram:PersonName and ram:SellerTradeParty/ram:DefinedTradeContact/ram:DepartmentName)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:SellerTradeParty/ram:DefinedTradeContact/ram:PersonName and ram:SellerTradeParty/ram:DefinedTradeContact/ram:DepartmentName)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[CII-SR-465]-Only one BT-41 element is allowed on an invoice.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="not(ram:BuyerTradeParty/ram:DefinedTradeContact/ram:PersonName and ram:BuyerTradeParty/ram:DefinedTradeContact/ram:DepartmentName)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(ram:BuyerTradeParty/ram:DefinedTradeContact/ram:PersonName and ram:BuyerTradeParty/ram:DefinedTradeContact/ram:DepartmentName)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[CII-SR-466]-Only one BT-56 element is allowed on an invoice.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SellerTradeParty)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SellerTradeParty)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SellerTradeParty' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:BuyerTradeParty)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:BuyerTradeParty)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:BuyerTradeParty' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M65"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M65"/>
   <xsl:template match="@*|node()" priority="-2" mode="M65">
      <xsl:apply-templates select="*" mode="M65"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery"
                 priority="1000"
                 mode="M66">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:ShipToTradeParty/ram:PostalTradeAddress and ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID!='') or not (ram:ShipToTradeParty/ram:PostalTradeAddress)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:ShipToTradeParty/ram:PostalTradeAddress and ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID!='') or not (ram:ShipToTradeParty/ram:PostalTradeAddress)">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-57]-Each Deliver to address (BG-15) shall contain a Deliver to country code (BT-80).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M66"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M66"/>
   <xsl:template match="@*|node()" priority="-2" mode="M66">
      <xsl:apply-templates select="*" mode="M66"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument"
                 priority="1000"
                 mode="M67">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(ram:IssuerAssignedID!='')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="(ram:IssuerAssignedID!='')">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-55]-Each Preceding Invoice reference (BG-3) shall contain a Preceding Invoice reference (BT-25).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IssuerAssignedID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IssuerAssignedID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IssuerAssignedID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M67"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M67"/>
   <xsl:template match="@*|node()" priority="-2" mode="M67">
      <xsl:apply-templates select="*" mode="M67"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice[&#xD;&#xA;  rsm:ExchangedDocument/ram:TypeCode != '386'&#xD;&#xA;]/rsm:SupplyChainTradeTransaction[&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoiceeTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoicerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoicerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoiceeTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;]"
                 priority="1000"
                 mode="M68">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice[&#xD;&#xA;  rsm:ExchangedDocument/ram:TypeCode != '386'&#xD;&#xA;]/rsm:SupplyChainTradeTransaction[&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoiceeTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoicerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;  or&#xD;&#xA;  (&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoicerTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;    and&#xD;&#xA;    ram:ApplicableHeaderTradeSettlement/ram:InvoiceeTradeParty/ram:PostalTradeAddress/ram:CountryID[upper-case(normalize-space(.))='DE']&#xD;&#xA;  )&#xD;&#xA;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="(&#xD;&#xA;        ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime&#xD;&#xA;        or ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod&#xD;&#xA;        or (every $line in ram:IncludedSupplyChainTradeLineItem&#xD;&#xA;            satisfies $line/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod)&#xD;&#xA;      )&#xD;&#xA;      and&#xD;&#xA;      (&#xD;&#xA;        ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime&#xD;&#xA;        or normalize-space(string-join(ram:ApplicableHeaderTradeDelivery//text(),'')) != ''&#xD;&#xA;      )"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="( ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime or ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod or (every $line in ram:IncludedSupplyChainTradeLineItem satisfies $line/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod) ) and ( ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime or normalize-space(string-join(ram:ApplicableHeaderTradeDelivery//text(),'')) != '' )">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	[BR-FX-EN-04]-An invoice that is not a down payment invoice (code 386) must contain either BT-72 "Actual delivery date", BG-14 "Invoicing period" or BG-26 "Invoice line period" in each invoice item to indicate the delivery/service date. If BT-72 is not used, at least the country of delivery (BT-80) must be specified for technical reasons.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M68"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M68"/>
   <xsl:template match="@*|node()" priority="-2" mode="M68">
      <xsl:apply-templates select="*" mode="M68"/>
   </xsl:template>
   <!--PATTERN -->

   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument"
                 priority="1183"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:ID"
                 priority="1182"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IncludedNote"
                 priority="1181"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IncludedNote"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Content)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Content)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Content' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SubjectCode)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SubjectCode)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SubjectCode' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IncludedNote/ram:SubjectCode"
                 priority="1180"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IncludedNote/ram:SubjectCode"/>
      <xsl:variable name="codeValue4" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue4)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=4]/enumeration[@value=$codeValue4]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue4)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=4]/enumeration[@value=$codeValue4]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:SubjectCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString"
                 priority="1179"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:TypeCode"
                 priority="1178"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:TypeCode"/>
      <xsl:variable name="codeValue2" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue2)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=2]/enumeration[@value=$codeValue2]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue2)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=2]/enumeration[@value=$codeValue2]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext"
                 priority="1177"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:BusinessProcessSpecifiedDocumentContextParameter)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:BusinessProcessSpecifiedDocumentContextParameter)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:BusinessProcessSpecifiedDocumentContextParameter' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:GuidelineSpecifiedDocumentContextParameter)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:GuidelineSpecifiedDocumentContextParameter)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:GuidelineSpecifiedDocumentContextParameter' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter"
                 priority="1176"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID"
                 priority="1175"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter"
                 priority="1174"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID"
                 priority="1173"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID"/>
      <xsl:variable name="codeValue1" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue1)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=1]/enumeration[@value=$codeValue1]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue1)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=1]/enumeration[@value=$codeValue1]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"
                 priority="1172"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IncludedSupplyChainTradeLineItem)&gt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IncludedSupplyChainTradeLineItem)&gt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IncludedSupplyChainTradeLineItem' must occur at least 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument"
                 priority="1171"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IssuerAssignedID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IssuerAssignedID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IssuerAssignedID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:FormattedIssueDateTime"
                 priority="1170"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:FormattedIssueDateTime"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:FormattedIssueDateTime' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID"
                 priority="1169"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty"
                 priority="1168"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:GlobalID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:GlobalID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:GlobalID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Name)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Name)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Name' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:PostalTradeAddress)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:PostalTradeAddress)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:PostalTradeAddress' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:URIUniversalCommunication)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:URIUniversalCommunication)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:URIUniversalCommunication' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTaxRegistration)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTaxRegistration)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTaxRegistration' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:GlobalID"
                 priority="1167"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:GlobalID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue12" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:ID"
                 priority="1166"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress"
                 priority="1165"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountryID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:CountryID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountryID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountrySubDivisionName)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CountrySubDivisionName)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountrySubDivisionName' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID"
                 priority="1164"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID"/>
      <xsl:variable name="codeValue14" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CountryID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID"
                 priority="1163"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:ID"/>
      <xsl:variable name="codeValue13" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:TradingBusinessName"
                 priority="1162"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedLegalOrganization/ram:TradingBusinessName"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:TradingBusinessName' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedTaxRegistration"
                 priority="1161"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedTaxRegistration"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID"
                 priority="1160"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue16" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue16)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=16]/enumeration[@value=$codeValue16]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue16)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=16]/enumeration[@value=$codeValue16]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication"
                 priority="1159"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:URIID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:URIID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:URIID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID"
                 priority="1158"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue15" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue15)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=15]/enumeration[@value=$codeValue15]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue15)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=15]/enumeration[@value=$codeValue15]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument"
                 priority="1157"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IssuerAssignedID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IssuerAssignedID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IssuerAssignedID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/ram:FormattedIssueDateTime"
                 priority="1156"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/ram:FormattedIssueDateTime"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:FormattedIssueDateTime' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/ram:IssuerAssignedID"
                 priority="1155"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/ram:IssuerAssignedID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty"
                 priority="1154"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Name)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Name)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Name' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:PostalTradeAddress)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:PostalTradeAddress)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:PostalTradeAddress' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTaxRegistration)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTaxRegistration)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTaxRegistration' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:GlobalID"
                 priority="1153"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:GlobalID"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:GlobalID' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:ID"
                 priority="1152"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ID' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:PostalTradeAddress"
                 priority="1151"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:PostalTradeAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountryID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:CountryID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountryID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountrySubDivisionName)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CountrySubDivisionName)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountrySubDivisionName' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:PostalTradeAddress/ram:CountryID"
                 priority="1150"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:PostalTradeAddress/ram:CountryID"/>
      <xsl:variable name="codeValue14" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CountryID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedLegalOrganization"
                 priority="1149"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedLegalOrganization"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:SpecifiedLegalOrganization' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration"
                 priority="1148"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID"
                 priority="1147"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue17" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue17)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=17]/enumeration[@value=$codeValue17]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue17)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=17]/enumeration[@value=$codeValue17]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:URIUniversalCommunication"
                 priority="1146"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty/ram:URIUniversalCommunication"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:URIUniversalCommunication' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty"
                 priority="1145"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Name)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Name)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Name' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:PostalTradeAddress)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:PostalTradeAddress)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:PostalTradeAddress' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:URIUniversalCommunication)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:URIUniversalCommunication)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:URIUniversalCommunication' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;])&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;])&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element variant 'ram:SpecifiedTaxRegistration[ram:ID/@schemeID="VA"]' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;])&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;])&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element variant 'ram:SpecifiedTaxRegistration[ram:ID/@schemeID="FC"]' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:GlobalID"
                 priority="1144"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:GlobalID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue12" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:ID"
                 priority="1143"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress"
                 priority="1142"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountryID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:CountryID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountryID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountrySubDivisionName)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CountrySubDivisionName)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountrySubDivisionName' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID"
                 priority="1141"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID"/>
      <xsl:variable name="codeValue14" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CountryID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID"
                 priority="1140"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID"/>
      <xsl:variable name="codeValue13" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ not(ram:ID/@schemeID=&#34;VA&#34;) and  not(ram:ID/@schemeID=&#34;FC&#34;)]"
                 priority="1139"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ not(ram:ID/@schemeID=&#34;VA&#34;) and  not(ram:ID/@schemeID=&#34;FC&#34;)]"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element variant 'ram:SpecifiedTaxRegistration[ not(ram:ID/@schemeID="VA") and  not(ram:ID/@schemeID="FC")]' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;]"
                 priority="1138"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;]/ram:ID"
                 priority="1137"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;FC&#34;]/ram:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;]"
                 priority="1136"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;]/ram:ID"
                 priority="1135"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID=&#34;VA&#34;]/ram:ID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication"
                 priority="1134"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:URIID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:URIID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:URIID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID"
                 priority="1133"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue15" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue15)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=15]/enumeration[@value=$codeValue15]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue15)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=15]/enumeration[@value=$codeValue15]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent"
                 priority="1132"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:OccurrenceDateTime)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:OccurrenceDateTime)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:OccurrenceDateTime' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString"
                 priority="1131"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument"
                 priority="1130"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IssuerAssignedID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IssuerAssignedID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IssuerAssignedID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument/ram:FormattedIssueDateTime"
                 priority="1129"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument/ram:FormattedIssueDateTime"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:FormattedIssueDateTime' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument/ram:IssuerAssignedID"
                 priority="1128"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument/ram:IssuerAssignedID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty"
                 priority="1127"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:GlobalID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:GlobalID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:GlobalID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:GlobalID"
                 priority="1126"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:GlobalID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue12" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:ID"
                 priority="1125"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress"
                 priority="1124"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountryID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:CountryID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountryID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CountrySubDivisionName)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CountrySubDivisionName)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CountrySubDivisionName' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID"
                 priority="1123"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:PostalTradeAddress/ram:CountryID"/>
      <xsl:variable name="codeValue14" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue14)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=14]/enumeration[@value=$codeValue14]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CountryID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:SpecifiedLegalOrganization"
                 priority="1122"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:SpecifiedLegalOrganization"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:SpecifiedLegalOrganization' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:SpecifiedTaxRegistration"
                 priority="1121"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:SpecifiedTaxRegistration"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:SpecifiedTaxRegistration' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:URIUniversalCommunication"
                 priority="1120"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:URIUniversalCommunication"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:URIUniversalCommunication' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement"
                 priority="1119"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:PaymentReference)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:PaymentReference)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:PaymentReference' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:InvoiceCurrencyCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:InvoiceCurrencyCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:InvoiceCurrencyCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ApplicableTradeTax)&gt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ApplicableTradeTax)&gt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ApplicableTradeTax' must occur at least 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTradePaymentTerms)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTradePaymentTerms)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTradePaymentTerms' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTradeSettlementHeaderMonetarySummation)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTradeSettlementHeaderMonetarySummation)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTradeSettlementHeaderMonetarySummation' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ReceivableSpecifiedTradeAccountingAccount)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ReceivableSpecifiedTradeAccountingAccount)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ReceivableSpecifiedTradeAccountingAccount' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax"
                 priority="1118"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CalculatedAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CalculatedAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CalculatedAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:BasisAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:BasisAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:BasisAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount"
                 priority="1117"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount"
                 priority="1116"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode"
                 priority="1115"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode"/>
      <xsl:variable name="codeValue8" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CategoryCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:DueDateTypeCode"
                 priority="1114"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:DueDateTypeCode"/>
      <xsl:variable name="codeValue9" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue9)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=9]/enumeration[@value=$codeValue9]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue9)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=9]/enumeration[@value=$codeValue9]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:DueDateTypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReasonCode"
                 priority="1113"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReasonCode"/>
      <xsl:variable name="codeValue20" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue20)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=20]/enumeration[@value=$codeValue20]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue20)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=20]/enumeration[@value=$codeValue20]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ExemptionReasonCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode"
                 priority="1112"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode"/>
      <xsl:variable name="codeValue7" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString"
                 priority="1111"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString"
                 priority="1110"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:CreditorReferenceID"
                 priority="1109"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:CreditorReferenceID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode"
                 priority="1108"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode"/>
      <xsl:variable name="codeValue18" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue18)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=18]/enumeration[@value=$codeValue18]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue18)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=18]/enumeration[@value=$codeValue18]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:InvoiceCurrencyCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/qdt:DateTimeString"
                 priority="1107"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/qdt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue25" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue25)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=25]/enumeration[@value=$codeValue25]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue25)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=25]/enumeration[@value=$codeValue25]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:IssuerAssignedID"
                 priority="1106"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:IssuerAssignedID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty"
                 priority="1105"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:ID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:GlobalID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:GlobalID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:GlobalID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Name)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Name)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Name' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:GlobalID"
                 priority="1104"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:GlobalID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue12" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue12)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=12]/enumeration[@value=$codeValue12]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:ID"
                 priority="1103"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:PostalTradeAddress"
                 priority="1102"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:PostalTradeAddress"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:PostalTradeAddress' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedLegalOrganization/ram:ID"
                 priority="1101"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedLegalOrganization/ram:ID"/>
      <xsl:variable name="codeValue13" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue13)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=13]/enumeration[@value=$codeValue13]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedLegalOrganization/ram:TradingBusinessName"
                 priority="1100"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedLegalOrganization/ram:TradingBusinessName"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:TradingBusinessName' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedTaxRegistration"
                 priority="1099"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:SpecifiedTaxRegistration"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:SpecifiedTaxRegistration' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:URIUniversalCommunication"
                 priority="1098"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:URIUniversalCommunication"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:URIUniversalCommunication' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID"
                 priority="1097"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"
                 priority="1096"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element variant 'ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator="false") and  not(ram:ChargeIndicator/udt:Indicator="true")]' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"
                 priority="1095"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeIndicator)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeIndicator)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeIndicator' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ActualAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ActualAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ActualAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryTradeTax)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryTradeTax)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryTradeTax' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"
                 priority="1094"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"
                 priority="1093"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"
                 priority="1092"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:BasisAmount"
                 priority="1091"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:CalculatedAmount"
                 priority="1090"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:CalculatedAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculatedAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:CategoryCode"
                 priority="1089"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:CategoryCode"/>
      <xsl:variable name="codeValue8" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CategoryCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:DueDateTypeCode"
                 priority="1088"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:DueDateTypeCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:DueDateTypeCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:ExemptionReason"
                 priority="1087"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:ExemptionReason"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReason' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:ExemptionReasonCode"
                 priority="1086"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:ExemptionReasonCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReasonCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:TypeCode"
                 priority="1085"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax/ram:TypeCode"/>
      <xsl:variable name="codeValue7" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"
                 priority="1084"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"/>
      <xsl:variable name="codeValue21" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue21)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=21]/enumeration[@value=$codeValue21]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue21)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=21]/enumeration[@value=$codeValue21]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ReasonCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]"
                 priority="1083"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeIndicator)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeIndicator)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeIndicator' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ActualAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ActualAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ActualAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryTradeTax)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryTradeTax)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryTradeTax' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ActualAmount"
                 priority="1082"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ActualAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:BasisAmount"
                 priority="1081"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax"
                 priority="1080"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:BasisAmount"
                 priority="1079"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:CalculatedAmount"
                 priority="1078"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:CalculatedAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculatedAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:CategoryCode"
                 priority="1077"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:CategoryCode"/>
      <xsl:variable name="codeValue8" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CategoryCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:DueDateTypeCode"
                 priority="1076"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:DueDateTypeCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:DueDateTypeCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:ExemptionReason"
                 priority="1075"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:ExemptionReason"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReason' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:ExemptionReasonCode"
                 priority="1074"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:ExemptionReasonCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReasonCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:TypeCode"
                 priority="1073"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax/ram:TypeCode"/>
      <xsl:variable name="codeValue7" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ReasonCode"
                 priority="1072"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ReasonCode"/>
      <xsl:variable name="codeValue22" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue22)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=22]/enumeration[@value=$codeValue22]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue22)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=22]/enumeration[@value=$codeValue22]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ReasonCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms"
                 priority="1071"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Description)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:Description)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Description' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:DirectDebitMandateID)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:DirectDebitMandateID)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:DirectDebitMandateID' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/ram:DirectDebitMandateID"
                 priority="1070"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/ram:DirectDebitMandateID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString"
                 priority="1069"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation"
                 priority="1068"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:LineTotalAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:LineTotalAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:LineTotalAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeTotalAmount)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeTotalAmount)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeTotalAmount' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:AllowanceTotalAmount)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:AllowanceTotalAmount)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:AllowanceTotalAmount' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TaxBasisTotalAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:TaxBasisTotalAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TaxBasisTotalAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TaxTotalAmount[@currencyID=../../ram:InvoiceCurrencyCode])&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:TaxTotalAmount[@currencyID=../../ram:InvoiceCurrencyCode])&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element variant 'ram:TaxTotalAmount[@currencyID=../../ram:InvoiceCurrencyCode]' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TaxTotalAmount[@currencyID=../../ram:TaxCurrencyCode])&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:TaxTotalAmount[@currencyID=../../ram:TaxCurrencyCode])&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element variant 'ram:TaxTotalAmount[@currencyID=../../ram:TaxCurrencyCode]' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:GrandTotalAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:GrandTotalAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:GrandTotalAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TotalPrepaidAmount)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:TotalPrepaidAmount)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TotalPrepaidAmount' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:DuePayableAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:DuePayableAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:DuePayableAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount"
                 priority="1067"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount"
                 priority="1066"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount"
                 priority="1065"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount"
                 priority="1064"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount"
                 priority="1063"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount"
                 priority="1062"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[ not(@currencyID=../../ram:InvoiceCurrencyCode) and  not(@currencyID=../../ram:TaxCurrencyCode)]"
                 priority="1061"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[ not(@currencyID=../../ram:InvoiceCurrencyCode) and  not(@currencyID=../../ram:TaxCurrencyCode)]"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element variant 'ram:TaxTotalAmount[ not(@currencyID=../../ram:InvoiceCurrencyCode) and  not(@currencyID=../../ram:TaxCurrencyCode)]' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=../../ram:InvoiceCurrencyCode]"
                 priority="1060"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=../../ram:InvoiceCurrencyCode]"/>
      <xsl:variable name="codeValue23" select="@currencyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue23)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=23]/enumeration[@value=$codeValue23]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue23)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=23]/enumeration[@value=$codeValue23]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@currencyID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=../../ram:TaxCurrencyCode]"
                 priority="1059"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount[@currencyID=../../ram:TaxCurrencyCode]"/>
      <xsl:variable name="codeValue24" select="@currencyID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue24)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=24]/enumeration[@value=$codeValue24]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue24)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=24]/enumeration[@value=$codeValue24]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@currencyID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TotalPrepaidAmount"
                 priority="1058"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TotalPrepaidAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans"
                 priority="1057"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:PayeePartyCreditorFinancialAccount)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:PayeePartyCreditorFinancialAccount)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:PayeePartyCreditorFinancialAccount' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:IBANID"
                 priority="1056"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:IBANID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID"
                 priority="1055"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayerPartyDebtorFinancialAccount"
                 priority="1054"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayerPartyDebtorFinancialAccount"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IBANID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:IBANID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IBANID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayerPartyDebtorFinancialAccount/ram:IBANID"
                 priority="1053"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayerPartyDebtorFinancialAccount/ram:IBANID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode"
                 priority="1052"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode"/>
      <xsl:variable name="codeValue19" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue19)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=19]/enumeration[@value=$codeValue19]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue19)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=19]/enumeration[@value=$codeValue19]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode"
                 priority="1051"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode"/>
      <xsl:variable name="codeValue18" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue18)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=18]/enumeration[@value=$codeValue18]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue18)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=18]/enumeration[@value=$codeValue18]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TaxCurrencyCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem"
                 priority="1050"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:AssociatedDocumentLineDocument)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:AssociatedDocumentLineDocument)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:AssociatedDocumentLineDocument' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTradeProduct)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTradeProduct)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTradeProduct' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedLineTradeAgreement)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedLineTradeAgreement)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedLineTradeAgreement' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedLineTradeDelivery)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedLineTradeDelivery)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedLineTradeDelivery' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument"
                 priority="1049"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:LineID)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:LineID)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:LineID' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:IncludedNote)&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:IncludedNote)&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:IncludedNote' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:IncludedNote"
                 priority="1048"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:IncludedNote"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Content)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Content)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Content' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:IncludedNote/ram:SubjectCode"
                 priority="1047"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:IncludedNote/ram:SubjectCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:SubjectCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID"
                 priority="1046"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID"/>
      <!--REPORT -->
      <xsl:if test="@schemeID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @schemeID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement"
                 priority="1045"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:NetPriceProductTradePrice)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:NetPriceProductTradePrice)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:NetPriceProductTradePrice' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice"
                 priority="1044"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;])&lt;=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;])&lt;=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element variant 'ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator="false"]' may occur at maximum 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"
                 priority="1043"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element variant 'ram:AppliedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator="false") and  not(ram:ChargeIndicator/udt:Indicator="true")]' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"
                 priority="1042"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeIndicator)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeIndicator)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeIndicator' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ActualAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ActualAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ActualAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"
                 priority="1041"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"
                 priority="1040"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CalculationPercent"
                 priority="1039"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CalculationPercent"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculationPercent' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"
                 priority="1038"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CategoryTradeTax' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:Reason"
                 priority="1037"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:Reason"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:Reason' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"
                 priority="1036"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ReasonCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:BasisQuantity"
                 priority="1035"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:BasisQuantity"/>
      <xsl:variable name="codeValue6" select="@unitCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@unitCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount"
                 priority="1034"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:GrossPriceProductTradePrice/ram:ChargeAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice"
                 priority="1033"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:AppliedTradeAllowanceCharge"
                 priority="1032"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:AppliedTradeAllowanceCharge"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:AppliedTradeAllowanceCharge' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:BasisQuantity"
                 priority="1031"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:BasisQuantity"/>
      <xsl:variable name="codeValue6" select="@unitCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@unitCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount"
                 priority="1030"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery"
                 priority="1029"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:BilledQuantity)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:BilledQuantity)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:BilledQuantity' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity"
                 priority="1028"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity"/>
      <xsl:variable name="codeValue6" select="@unitCode"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue6)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=6]/enumeration[@value=$codeValue6]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@unitCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement"
                 priority="1027"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ApplicableTradeTax)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ApplicableTradeTax)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ApplicableTradeTax' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:SpecifiedTradeSettlementLineMonetarySummation)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:SpecifiedTradeSettlementLineMonetarySummation)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:SpecifiedTradeSettlementLineMonetarySummation' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax"
                 priority="1026"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:TypeCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:TypeCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:TypeCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:CategoryCode)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:CategoryCode)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:CategoryCode' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount"
                 priority="1025"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount"
                 priority="1024"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculatedAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode"
                 priority="1023"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode"/>
      <xsl:variable name="codeValue8" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue8)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=8]/enumeration[@value=$codeValue8]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:CategoryCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:DueDateTypeCode"
                 priority="1022"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:DueDateTypeCode"/>
      <xsl:variable name="codeValue9" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue9)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=9]/enumeration[@value=$codeValue9]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue9)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=9]/enumeration[@value=$codeValue9]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:DueDateTypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReason"
                 priority="1021"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReason"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReason' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReasonCode"
                 priority="1020"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:ExemptionReasonCode"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:ExemptionReasonCode' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode"
                 priority="1019"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode"/>
      <xsl:variable name="codeValue7" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue7)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=7]/enumeration[@value=$codeValue7]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:TypeCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString"
                 priority="1018"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString"
                 priority="1017"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@format"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@format">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@format' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue3" select="@format"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue3)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=3]/enumeration[@value=$codeValue3]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@format' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"
                 priority="1016"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator=&#34;false&#34;) and  not(ram:ChargeIndicator/udt:Indicator=&#34;true&#34;)]"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element variant 'ram:SpecifiedTradeAllowanceCharge[ not(ram:ChargeIndicator/udt:Indicator="false") and  not(ram:ChargeIndicator/udt:Indicator="true")]' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"
                 priority="1015"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeIndicator)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeIndicator)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeIndicator' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ActualAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ActualAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ActualAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"
                 priority="1014"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ActualAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"
                 priority="1013"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CalculationPercent"
                 priority="1012"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CalculationPercent"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculationPercent' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"
                 priority="1011"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:CategoryTradeTax"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CategoryTradeTax' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"
                 priority="1010"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;false&#34;]/ram:ReasonCode"/>
      <xsl:variable name="codeValue10" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue10)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=10]/enumeration[@value=$codeValue10]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue10)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=10]/enumeration[@value=$codeValue10]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ReasonCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]"
                 priority="1009"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ChargeIndicator)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ChargeIndicator)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ChargeIndicator' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:ActualAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:ActualAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:ActualAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ActualAmount"
                 priority="1008"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ActualAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:BasisAmount"
                 priority="1007"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:BasisAmount"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:BasisAmount' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CalculationPercent"
                 priority="1006"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CalculationPercent"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CalculationPercent' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax"
                 priority="1005"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:CategoryTradeTax"/>
      <!--REPORT -->
      <xsl:if test="true()">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="true()">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Element 'ram:CategoryTradeTax' is marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ReasonCode"
                 priority="1004"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator=&#34;true&#34;]/ram:ReasonCode"/>
      <xsl:variable name="codeValue11" select="."/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue11)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=11]/enumeration[@value=$codeValue11]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue11)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=11]/enumeration[@value=$codeValue11]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of 'ram:ReasonCode' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation"
                 priority="1003"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:LineTotalAmount)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="count(ram:LineTotalAmount)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:LineTotalAmount' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount"
                 priority="1002"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount"/>
      <!--REPORT -->
      <xsl:if test="@currencyID">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@currencyID">
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
	Attribute @currencyID' marked as not used in the given context.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct"
                 priority="1001"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="count(ram:Name)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(ram:Name)=1">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Element 'ram:Name' must occur exactly 1 times.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:GlobalID"
                 priority="1000"
                 mode="M69">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:GlobalID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="@schemeID"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@schemeID">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Attribute '@schemeID' is required in this context.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="codeValue5" select="@schemeID"/>
      <!--ASSERT -->
      <xsl:choose>
         <xsl:when test="string-length($codeValue5)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=5]/enumeration[@value=$codeValue5]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length($codeValue5)=0 or document('Factur-X_1.08_BASIC_codedb.xml')/codedb/cl[@id=5]/enumeration[@value=$codeValue5]">
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
	Value of '@schemeID' is not allowed.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M69"/>
   <xsl:template match="@*|node()" priority="-2" mode="M69">
      <xsl:apply-templates select="*" mode="M69"/>
   </xsl:template>
</xsl:stylesheet>
