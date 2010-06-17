<xsl:stylesheet version="1.0"
	xmlns:c="http://cnx.rice.edu/cnxml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    >
<!-- This file:
	* Does all the logging
	* Optionally provides an XPath to the current context (where the error occurred)
	* Logs any unmatched elements
-->


<!-- Used for logging to know what the current module is -->
<xsl:param name="cnx.module.id" select="/c:document/@id"/>
<!-- The following parameters are used for batch processing and gathering statistics -->
<xsl:param name="cnx.log.onlybugs">no</xsl:param> 
<xsl:param name="cnx.log.onlyaggregate">yes</xsl:param>
<xsl:param name="cnx.log.nowarn">no</xsl:param> 

<xsl:template name="cnx.nsprefix">
    <xsl:param name="c" select="."/>
    <xsl:param name="ns" select="namespace-uri($c)"/>
    <xsl:choose>
        <xsl:when test="$ns='http://cnx.rice.edu/cnxml'">c</xsl:when>
        <xsl:when test="$ns='http://www.w3.org/2000/svg'">svg</xsl:when>
        <xsl:when test="$ns='https://sourceforge.net/projects/pmml2svg/'">pmml2svg</xsl:when>
        <xsl:when test="$ns='http://cnx.rice.edu/collxml'">col</xsl:when>
        <xsl:when test="$ns='http://cnx.rice.edu/mdml'">md</xsl:when>
        <xsl:when test="$ns='http://www.w3.org/1998/Math/MathML'">mml</xsl:when>
        <xsl:when test="$ns='http://cnx.rice.edu/qml/1.0'">quiz</xsl:when>
        <xsl:otherwise><xsl:value-of select="$ns"/></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Catch-all -->
<xsl:template match="*">
	<xsl:call-template name="cnx.log">
		<xsl:with-param name="isBug">yes</xsl:with-param>
		<xsl:with-param name="msg">
			<xsl:text>BUG: Could not match Element (could be strange attributes or children) </xsl:text>
		    <xsl:call-template name="cnx.nsprefix">
		        <xsl:with-param name="c" select=".."/>
		    </xsl:call-template>
		    <xsl:text>:</xsl:text>
		    <xsl:value-of select="local-name(..)"/>
			<xsl:text>/</xsl:text>
		    <xsl:call-template name="cnx.nsprefix"/>
		    <xsl:text>:</xsl:text>
	  		<xsl:value-of select="local-name(.)"/>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template name="debugPathPrinter">
	<xsl:if test="../.."><!-- Root is a node, and confuses the printing -->
		<xsl:for-each select="..">
			<xsl:call-template name="debugPathPrinter"/>
		</xsl:for-each>
	</xsl:if>
	<xsl:text>/</xsl:text>
	<xsl:variable name="ns">
	    <xsl:call-template name="cnx.nsprefix"/>
    </xsl:variable>
    <xsl:if test="not(starts-with($ns, 'http'))">
        <xsl:value-of select="$ns"/>
        <xsl:text>:</xsl:text>
    </xsl:if>
	<xsl:value-of select="local-name(.)"/>
	<xsl:text>[</xsl:text>
	<xsl:choose>
		<xsl:when test="@xml:id">
			<xsl:text>@xml:id='</xsl:text>
			<xsl:value-of select="@xml:id"/>
			<xsl:text>'</xsl:text>
		</xsl:when>
		<xsl:when test="@id">
			<xsl:text>@id='</xsl:text>
			<xsl:value-of select="@id"/>
			<xsl:text>'</xsl:text>
		</xsl:when>
		<xsl:otherwise>
		    <!-- Can't use position() because that returns the position relative to _all_ children, not just children with the same name -->
		    <xsl:variable name="name" select="local-name()"/>
		    <xsl:variable name="namespace" select="namespace-uri()"/>
			<xsl:value-of select="count(preceding-sibling::*[local-name()=$name and namespace-uri()=$namespace])+1"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:text>]</xsl:text>
</xsl:template>

<xsl:template name="cnx.log">
	<xsl:param name="msg" />
	<xsl:param name="isBug">no</xsl:param>
	<xsl:param name="node" select="."/>
	<xsl:if test="($cnx.log.onlybugs != 'no' and $isBug != 'no') or $cnx.log.onlybugs = 'no'">
	<xsl:if test="not(starts-with($msg, 'WARNING: ')) or $cnx.log.nowarn='no'"> 
		<xsl:choose>
			<xsl:when test="$cnx.log.onlyaggregate != 'no'">
				<xsl:message>
					<xsl:text>LOG: </xsl:text>
				  	<xsl:value-of select="$msg"/>
				</xsl:message>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>
					<xsl:text>LOG: </xsl:text>
					<xsl:text>{ module: "</xsl:text>
				  	<xsl:value-of select="$cnx.module.id"/>
					<xsl:text>", message: "</xsl:text>
				  	<xsl:value-of select="$msg"/>
				  	<xsl:text>", xpath: "</xsl:text>
				  	<xsl:call-template name="debugPathPrinter"/>
				  	<xsl:text>"}</xsl:text>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose> 
	</xsl:if>
	</xsl:if>
</xsl:template>

<xsl:template name="cnx.personlist">
	<xsl:param name="nodes"/>
	<xsl:for-each select="$nodes">
		<xsl:if test="position()=last() and position()!=1">
			<xsl:text> and </xsl:text>
		</xsl:if>
		<xsl:apply-templates select="."/>
		<xsl:if test="position()!=last() and last()!=2">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<!-- Construct an id for a node if none exists -->
<xsl:template name="cnx.id">
	<xsl:param name="object" select="."/>
	<xsl:if test="$cnx.module.id != ''">
		<xsl:value-of select="$cnx.module.id"/>
		<xsl:value-of select="$cnx.module.separator"/>
	</xsl:if>
	<xsl:if test="not($object/@xml:id)">
		<xsl:if test="not($object/@id)">
				<xsl:value-of select="generate-id($object)"/>
		</xsl:if>
		<xsl:value-of select="$object/@id"/>
	</xsl:if>
	<xsl:value-of select="$object/@xml:id"/>
</xsl:template>


</xsl:stylesheet>