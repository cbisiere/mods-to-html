<?xml version="1.0" encoding="utf-8"?>
<!-- 
  Transforms MODS records to HTML
  
  Author: Christophe Bisière
  Documentation: https://github.com/cbisiere/mods-to-html


  Stylesheet parameters
    
  @param string $version          API version (1)
  @param string $displayLanguage  one or more display languages ('eng', 'fre', 
                                    'fre eng')
  @param string $headingLevel     heading level of the output sections (1-6)
  @param string $vitaeOf          ValueURI of the contributor this reference is 
                                    for (e.g., http://tse-fr.eu/aut/1234) 
                                  other contributors will be cited after "with"
  @param string $sections         sections to output (e.g. 'reference abstract 
                                    jelcodes');
                                  a postfix '-body' suppress the heading;
                                  a '*' replaces all the sections except 
                                    'fragments';  
  @param string $debug            output debug information ('no', 'warning', 
                                    'inplace')
                                  
-->

<xsl:stylesheet
  version="1.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:mods="http://www.loc.gov/mods/v3"
  exclude-result-prefixes="xlink mods"
>
  <xsl:param name="version" select="1"/>
  <xsl:param name="displayLanguage" select="'eng'"/>
  <xsl:param name="headingLevel" select="1"/>
  <xsl:param name="vitaeOf" select="''"/>
  <xsl:param name="sections" select="'*'"/>
  <xsl:param name="debug" select="'no'"/>

<xsl:output
  method="xml"
  indent="yes"
  encoding="utf-8"
/>


<!-- 
  ******************************************************************************

  Parameters and constants
  

  ******************************************************************************
 -->

<!--
 
  Create a global variable for some (cleaned-up) parameter.
  
-->

<xsl:variable name="gVersion" select="normalize-space($version)"/>

<xsl:variable name="gHeadingLevel" select="normalize-space($headingLevel)"/>

<xsl:variable name="gVitaeOf" select="normalize-space($vitaeOf)"/>

<xsl:variable name="gSections">

  <!-- default sections: all but fragments -->
  <xsl:variable name="defaultSections" select="'reference other-contributors urls abstract keywords jelcodes related'"/>

  <!-- expand * to the default sections -->
  <xsl:call-template name="string-replace-all">
    <xsl:with-param name="search" select="'*'"/>
    <xsl:with-param name="replace" select="$defaultSections"/>
    <xsl:with-param name="string" select="normalize-space($sections)"/>       
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="gDebug" select="normalize-space($debug)"/>


<!--
 
  Check the parameters passed to the stylesheet
  
-->

<xsl:template name="check-parameters">

  <xsl:call-template name="check-parameter-in">
    <xsl:with-param name="name" select="'version'"/>
    <xsl:with-param name="value" select="$gVersion"/>
    <xsl:with-param name="list" select="'1'"/>
  </xsl:call-template>

  <xsl:call-template name="check-parameter-in">
    <xsl:with-param name="name" select="'displayLanguage'"/>
    <xsl:with-param name="value" select="$displayLanguage"/>
    <xsl:with-param name="multiple" select="'true'"/>
    <xsl:with-param name="list" select="'eng fre'"/>
  </xsl:call-template>

  <xsl:call-template name="check-parameter-in">
    <xsl:with-param name="name" select="'sections'"/>
    <xsl:with-param name="value" select="$gSections"/>
    <xsl:with-param name="multiple" select="'true'"/>
    <xsl:with-param name="list" select="'reference other-contributors urls abstract keywords jelcodes related fragments'"/>
  </xsl:call-template>

  <xsl:call-template name="check-parameter-in">
    <xsl:with-param name="name" select="'headingLevel'"/>
    <xsl:with-param name="value" select="$gHeadingLevel"/>
    <xsl:with-param name="list" select="'1 2 3 4 5 6'"/>
  </xsl:call-template>

  <xsl:call-template name="check-parameter-in">
    <xsl:with-param name="name" select="'debug'"/>
    <xsl:with-param name="value" select="$gDebug"/>
    <xsl:with-param name="list" select="'no warning inplace'"/>
  </xsl:call-template>

</xsl:template>


<!--
 
  Constants
  
-->

<xsl:variable name="APOS">'</xsl:variable>

<!-- JEL codes lookup table: 
  http://www.aeaweb.org/econlit/classificationTree.xml 
-->
<xsl:variable name="JEL_CODES" select="document('classificationTree.xml')"/>

<!-- roles of primary responsibility -->
<xsl:variable name="ROLES_AUTHOR" select="'aut spk'"/>
<xsl:variable name="ROLES_EDITOR" select="'edt'"/>
<xsl:variable name="ROLES_TRANSLATOR" select="'trl'"/>
<xsl:variable name="ROLES_GRANTOR" select="'dgg'"/>


<!-- 
  ******************************************************************************

  Main templates
  

  ******************************************************************************
 -->

<!-- 
  Document root 

  Context node: /
  Target nodes: mods:modsCollection, mods:mods 

  Handles mods:mods and mods:modsCollection documents. 
  A mods:mods document is transformed into a single <div class='mods-item'> 
    element. 
  A mods:modsCollection is transformed into an unnumbered list of 
    <div class='mods-item'> elements.
  
-->

<xsl:template match="/">

  <xsl:variable name="displayLanguage" select="normalize-space($displayLanguage)"/>

  <xsl:variable name="errors">
    <xsl:call-template name="check-parameters"/>
  </xsl:variable>
  
  <xsl:choose>
    <!-- 'inplace' errors messages on parameters: output a div and stop here  -->
    <xsl:when test="$errors!=''">
      <div class="mods-warning">
        <xsl:copy-of select="$errors"/>
      </div>      
    </xsl:when>
    <xsl:otherwise>
      <div class="mods-root">
        <xsl:call-template name="mods-item-or-collection-per-language">
          <xsl:with-param name="displayLanguages" select="$displayLanguage"/>
        </xsl:call-template>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  A list of mods item (or collections), one per requested language 
  (recursive template)

  Context node: mods:modsCollection, mods:mods
  Target nodes: * 

  @param string $displayLanguages   display languages (e.g. 'fre eng')
-->

<xsl:template name="mods-item-or-collection-per-language">
  <xsl:param name="displayLanguages"/>
  
  <xsl:if test="string-length($displayLanguages)">
  
    <!-- first section to process -->
    <xsl:variable name="displayLanguage">
      <xsl:choose>
        <xsl:when test="not(contains($displayLanguages, ' '))">
          <xsl:value-of select="$displayLanguages"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-before($displayLanguages, ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- remaining sections -->
    <xsl:variable name="rest" select="substring-after($displayLanguages, ' ')"/>
    
    <!-- treat the section -->
    <xsl:call-template name="mods-item-or-collection">
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>

    <!-- recursive call to process the other languages -->
    <xsl:call-template name="mods-item-or-collection-per-language">
      <xsl:with-param name="displayLanguages" select="$rest"/>
    </xsl:call-template>
    
     </xsl:if>
</xsl:template>


<!-- 
  Document root 

  Context node: /
  Target nodes: mods:modsCollection, mods:mods 

  Handles mods:mods and mods:modsCollection documents. 
  A mods:mods document is transformed into a single <div class='mods-item'> 
    element. 
  A mods:modsCollection is transformed into an unnumbered list of 
    <div class='mods-item'> elements.
  
  FIXME: prevent empty collection from creating <ul> 
-->

<xsl:template name="mods-item-or-collection">
  <xsl:param name="displayLanguage"/>

  <xsl:choose>
    
    <!-- a collection of items -->
    <xsl:when test="mods:modsCollection/mods:mods">
      <div>
        <xsl:attribute name="class">
          <xsl:value-of select="concat('mods-items', ' ', 'mods-lang-', $displayLanguage)"/>
        </xsl:attribute>
        <ul>
          <xsl:for-each select="mods:modsCollection/mods:mods">
            <xsl:variable name="item">
              <xsl:call-template name="mods">
                <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$item">       
              <li>    
                <xsl:copy-of select="$item"/>
              </li>
            </xsl:if>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:when>
    
    <!-- a single item -->
    <xsl:when test="//mods:mods">
      <!-- fake for-each loop to set the context node -->
      <xsl:for-each select="//mods:mods">
        <xsl:call-template name="mods">
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:when>
  </xsl:choose>
</xsl:template>



<!-- 
  Mods root element 

  Context node: mods:mods
  Target nodes: * 

  TODO: number of pages; ISBN, ISSN, doi; objectPart
-->

<xsl:template name="mods">
  <xsl:param name="displayLanguage"/>

  <!-- language of cataloging
    This language is the default language of any element (e.g., an abstract) 
    with no @lang attribute
  -->
  <xsl:variable name="catalogingLanguage" select="mods:recordInfo/mods:languageOfCataloging/mods:languageTerm[@authority='iso639-2b' and @type='code']"/>

  <xsl:variable name="sections">
    <xsl:call-template name="mods-sections">
      <xsl:with-param name="sections" select="$gSections"/>
      <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="$sections!=''">
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('mods-item', ' ', 'mods-lang-', $displayLanguage)"/>
      </xsl:attribute>
      <xsl:copy-of select="$sections"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  A list of sections (recursive template)

  Context node: mods:mods
  Target nodes: * 

  @param string $sections           names of the sections requested (e.g. 
                                      'reference keywords')
  @param string $catalogingLanguage cataloging language (e.g. 'fre' or 'eng')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="mods-sections">
  <xsl:param name="sections"/>
  <xsl:param name="catalogingLanguage"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:if test="string-length($sections)">
  
    <!-- first section to process -->
    <xsl:variable name="section">
      <xsl:choose>
        <xsl:when test="not(contains($sections, ' '))">
          <xsl:value-of select="$sections"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-before($sections, ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- remaining sections -->
    <xsl:variable name="rest" select="substring-after($sections, ' ')"/>
    
    <!-- treat the section -->
    <xsl:call-template name="mods-section">
      <xsl:with-param name="section" select="$section"/>
      <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>

    <!-- recursive call to process the other sections -->
    <xsl:call-template name="mods-sections">
      <xsl:with-param name="sections" select="$rest"/>
      <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>
    
     </xsl:if>
</xsl:template>


<!-- 
  A single section 

  Context node: mods:mods
  Target nodes: * 

  @param string $section            name of the section requested (e.g. 
                                      'reference')
  @param string $catalogingLanguage cataloging language (e.g. 'fre' or 'eng')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="mods-section">
  <xsl:param name="section"/>
  <xsl:param name="catalogingLanguage"/>
  <xsl:param name="displayLanguage"/>
  
  <!-- search for a "-body" postfix in the section name -->
  <xsl:variable name="noPostfix" select="$section!=concat(substring-before($section, '-body'), '-body')"/>
  <xsl:variable name="sectionName">
    <xsl:choose>
      <xsl:when test="$noPostfix">
        <xsl:value-of select="$section"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before($section, '-body')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
  
    <!-- reference -->
    <xsl:when test="$sectionName='reference'">
      <xsl:call-template name="section-reference">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- other contributors -->
    <xsl:when test="$sectionName='other-contributors'">
      <xsl:call-template name="section-other-contributors">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- urls -->
    <xsl:when test="$sectionName='urls'">
      <xsl:call-template name="section-urls">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>
    
    <!-- abstract -->
    <xsl:when test="$sectionName='abstract'">
      <xsl:call-template name="section-abstract">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- keywords -->
    <xsl:when test="$sectionName='keywords'">
      <xsl:call-template name="section-keywords">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- JEL codes -->
    <xsl:when test="$sectionName='jelcodes'">
      <xsl:call-template name="section-jelcodes">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- related item sections -->
    <xsl:when test="$sectionName='related'">
      <xsl:call-template name="sections-related">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!--  fragments -->
    <xsl:when test="$sectionName='fragments'">
      <xsl:call-template name="section-fragments">
        <xsl:with-param name="withHeading" select="$noPostfix"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

  </xsl:choose>
</xsl:template>


<!-- 
  ******************************************************************************

  Section head:
  
    section-head
  
  
  ******************************************************************************
 -->

<!-- 
  Section head
  
  @param string  $key              key to form the class distinctive name
  @param string  $heading_fre      French heading
  @param string  $heading_eng      English heading
  @param integer $count            use plural form when greater than 1
  @param string  $displayLanguage  display language (e.g. 'fre' or 'eng')

  Example: 
    
    if $displayLanguage is 'fre' and $gHeadingLevel is 2
  
    section-head('keywords', 'Mots clés', 'Keywords') 
  
    ouputs the element
    
    <h2 class='mods-section-head mods-keywords'>Mots clés</h2>
-->

<xsl:template name="section-head">
  <xsl:param name="key"/>
  <xsl:param name="heading_fre"/>
  <xsl:param name="heading_eng"/>
  <xsl:param name="count" select="1"/>
  <xsl:param name="displayLanguage"/>

  <xsl:element name="h{$gHeadingLevel}">
  
    <xsl:attribute name="class">
      <xsl:value-of select="concat('mods-section-head', ' ',  'mods-', $key)"/>
    </xsl:attribute>
    
    <xsl:variable name="heading">
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:value-of select="$heading_fre"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$heading_eng"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="singular-or-plural">
      <xsl:with-param name="string" select="$heading"/>
      <xsl:with-param name="count" select="$count"/>
    </xsl:call-template>

  </xsl:element>
</xsl:template>



<!-- 
  ******************************************************************************

  Genre:
  
    eu-genre
    mods:genre    
  
  
  ******************************************************************************
 -->


<!-- 
  Genre (eu-repo vocabulary)
  
  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:genre
    
  Example output: 'article' (from 'info:eu-repo/semantics/article')
-->

<xsl:template name="eu-genre">
  <xsl:if test="mods:genre[@authority='info:eu-repo'][1]">
    <xsl:call-template name="substring-after-last">
      <xsl:with-param name="haystack" select="mods:genre[@authority='info:eu-repo'][1]"/>
      <xsl:with-param name="needle" select="'/'"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>



<!-- 
  ******************************************************************************

  Main section:
  
    section-reference
  

  ******************************************************************************
 -->

<!-- 
  Section: reference

  Context node: mods:mods
  Target nodes: * 

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->
 
<xsl:template name="section-reference">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>

  <!-- document language -->
  <xsl:variable name="documentLanguage">
    <xsl:call-template name="item-language"/>
  </xsl:variable>
  
  <!-- item -->
  <xsl:variable name="item">
    <xsl:apply-templates select=".">
      <xsl:with-param name="documentLanguage" select="$documentLanguage"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$item!=''">
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'reference'"/>
        <xsl:with-param name="heading_fre" select="'Référence'"/>
        <xsl:with-param name="heading_eng" select="'Reference'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  
    <!-- body -->
    <div class="mods-section-body mods-reference">
      <div class="mods-one-reference">
      
        <!-- item -->
        <xsl:copy-of select="$item"/>
        
        <!-- final dot -->
        <xsl:text>.</xsl:text>
        
        <!-- "with" -->
        <xsl:variable name="coauthors">
          <xsl:if test="$gVitaeOf!=''">
            <xsl:call-template name="contributors">
              <xsl:with-param name="roles" select="$ROLES_AUTHOR"/>
              <xsl:with-param name="context" select="'with'"/>
              <xsl:with-param name="uriToSkip" select="$gVitaeOf"/>
              <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>

        <xsl:if test="$coauthors!=''">
          <div>
            <xsl:copy-of select="$coauthors"/>
          </div>
        </xsl:if>
      </div>
    </div>
  </xsl:if>
</xsl:template>



<!-- 
  head roles: roles that start the reference

  These roles are, when available and in order: creators ('aut', 'spk'),
  editors ('edt'), translators ('trl') and degree grantors ('dgg').
  
  However, when the item is not the document itself (i.e., it is a
  container or a series) or when a "with" form is requested, no roles
  will start the reference.
  
  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name 
  
  @param string $type item level: 'document', 'container' or 'series'
-->


<xsl:template name="head-roles">
  <xsl:param name="type"/>

  <xsl:if test="($type='document') and ($gVitaeOf='')">
    <xsl:variable name="count-authors">
      <xsl:call-template name="number-of-contributors">
        <xsl:with-param name="roles" select="$ROLES_AUTHOR"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="count-editors">
      <xsl:call-template name="number-of-contributors">
        <xsl:with-param name="roles" select="$ROLES_EDITOR"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="count-translators">
      <xsl:call-template name="number-of-contributors">
        <xsl:with-param name="roles" select="$ROLES_TRANSLATOR"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="count-grantors">
      <xsl:call-template name="number-of-contributors">
        <xsl:with-param name="roles" select="$ROLES_GRANTOR"/>
      </xsl:call-template>
    </xsl:variable>
  
    <xsl:choose>
      <xsl:when test="$count-authors &gt; 0">
        <xsl:value-of select="$ROLES_AUTHOR"/>
      </xsl:when>
      <xsl:when test="$count-editors &gt; 0">
        <xsl:value-of select="$ROLES_EDITOR"/>
      </xsl:when>
      <xsl:when test="$count-translators &gt; 0">
        <xsl:value-of select="$ROLES_TRANSLATOR"/>
      </xsl:when>
      <xsl:when test="$count-grantors &gt; 0">
        <xsl:value-of select="$ROLES_GRANTOR"/>
      </xsl:when>
    </xsl:choose>
  </xsl:if>
</xsl:template>


<!-- 
  Must a title be quoted, given a type and a genre?

  @param string $type  type of item ('document', 'in', 'container', 'series')
  @param string $genre genre of item
-->

<xsl:template name="item-title-must-be-quoted">
  <xsl:param name="type"/>
  <xsl:param name="genre"/>
  
  <xsl:value-of select="$type='series' or 
    $type='document' and not($genre='' or $genre='book' or $genre='conferenceProceedings' or $genre='preprint')"/>
</xsl:template>


<!-- 
  Type of item: 'document', 'in', 'container', 'series'

  Context node: mods:mods or mods:relatedItem
  Target nodes: none 

  @param string $parentGenre eu-repo genre of the parent if any
-->

<xsl:template name="item-type">
  <xsl:param name="parentGenre" select="''"/>   

  <xsl:variable name="genre">
    <xsl:call-template name="eu-genre"/>
  </xsl:variable>

  <xsl:choose>

    <!-- case: 'document' (e.g. a book, an article, a working paper) -->
    <xsl:when test="self::mods:mods">
      <xsl:text>document</xsl:text>
    </xsl:when>

    <!-- case: 'in' (e.g. a book as a chapter container) -->
    <xsl:when test="@type='host' and ($genre='book' or $parentGenre='conferencePaper')">
      <xsl:text>in</xsl:text>
    </xsl:when>
    
    <!-- case: 'series' (e.g. a series of books) -->
    <xsl:when test="@type='series' and $parentGenre!='' and $parentGenre!='lecture' and $parentGenre!='workingPaper'">
      <xsl:text>series</xsl:text>
    </xsl:when>
    
    <!-- case: 'container' (e.g. a journal, a working paper series) -->
    <xsl:when test="@type='host' or @type='series'">
      <xsl:text>container</xsl:text>
    </xsl:when>
    
  </xsl:choose>
</xsl:template>


<!-- 
  Item language, e.g., 'fre', 'eng'

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:language/mods:languageTerm
-->

<xsl:template name="item-language">
  <xsl:value-of select="mods:language/mods:languageTerm[@authority='iso639-2b' and @type='code'][not(@objectPart)][@usage='primary' or count(.)=1]"/>
</xsl:template>


<!-- 
  Title caption to use for a given type of item
  
  @param string $type             type of item ('document', 'in', 'container', 
                                    'series')
  @param string $displayLanguage  display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="title-caption">
  <xsl:param name="type"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:choose>
  
    <!-- "in" -->
    <xsl:when test="$type='in'">
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:text>dans</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>in</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    
    <!-- "series" -->
    <xsl:when test="$type='series'">
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:text>collection</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>series</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    
  </xsl:choose>
</xsl:template>



<!-- 
  Mods item (recursive template) 

  Context node: mods:mods or mods:relatedItem
  Target nodes: * 
  
  @param string $types            blank-separated list of types to take into 
                                    account, in 'document', 'in', 'container', 
                                    'series', or '' for no restriction
  @param string $part             part to output:
                                    'creators': primary responsibility
                                    'title':
                                    'other':
                                    '' for all parts
  @param string $parentGenre      eu-repo genre of the parent if any
  @param string $documentLanguage language of the document (e.g. 'fre')
  @param string $displayLanguage  display language (e.g. 'fre' or 'eng')
-->

<xsl:template match="mods:mods|mods:relatedItem[not(@xlink:href) and (@type='host' or @type='series')]">
  <xsl:param name="types" select="''"/>
  <xsl:param name="part" select="''"/>
  <xsl:param name="parentGenre" select="''"/>
  <xsl:param name="documentLanguage"/>
  <xsl:param name="displayLanguage"/>

  <!-- type of the item-->
  <xsl:variable name="type">
    <xsl:call-template name="item-type">
      <xsl:with-param name="parentGenre" select="$parentGenre"/>    
    </xsl:call-template>
  </xsl:variable>

  <!-- was this type requested? -->
  <xsl:variable name="inTypes">
    <xsl:call-template name="key-in-list">
      <xsl:with-param name="key" select="$type"/>
      <xsl:with-param name="list" select="$types"/>
    </xsl:call-template>
  </xsl:variable>


  <xsl:if test="$types='' or $inTypes='true'">

    <!-- genre -->
    <xsl:variable name="genre">
      <xsl:call-template name="eu-genre"/>
    </xsl:variable>
  
  
    <!-- primary responsibility -->
  
    <xsl:variable name="head-roles">
      <xsl:if test="$type='document' and $gVitaeOf=''">
        <xsl:call-template name="head-roles">
          <xsl:with-param name="type" select="$type"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>
  
    <xsl:variable name="count-head-roles">
      <xsl:call-template name="number-of-contributors-in-set">
        <xsl:with-param name="roles" select="$head-roles"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="contributors">
      <xsl:if test="$part='' or $part='creators'">
        <xsl:call-template name="contributors">
          <xsl:with-param name="roles" select="$head-roles"/>
          <xsl:with-param name="context" select="'primary'"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>
  
    <!-- output -->
    <xsl:if test="$contributors!=''">
      <xsl:copy-of select="$contributors"/>
    </xsl:if>
    <xsl:variable name="sepAfterContributors" select="$contributors!=''"/>
  
  
    <!-- title -->
  
    <!-- a local identifier is considered as an href to the item -->
    <xsl:variable name="href" select="mods:identifier[@type='local']"/>
  
    <xsl:variable name="title">
      <xsl:if test="$part='' or $part='title'">
        <xsl:apply-templates select="mods:titleInfo[@usage='primary' or count(.)=1]">
          <xsl:with-param name="type" select="$type"/>
          <xsl:with-param name="genre" select="$genre"/>
          <xsl:with-param name="language" select="$documentLanguage"/>
          <xsl:with-param name="href" select="$href"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:if> 
    </xsl:variable>
  
    <!-- output -->
    <xsl:if test="$title!=''">
      <xsl:if test="$sepAfterContributors='true'">
        <xsl:call-template name="separator"/>
      </xsl:if>
      <xsl:copy-of select="$title"/>
    </xsl:if>
    <xsl:variable name="sepAfterTitle" select="$sepAfterContributors='true' or $title!=''"/>
  
    <xsl:if test="$part='' or $part='other'">

      <!-- container item --> 
      <xsl:variable name="container">
        <xsl:apply-templates select="mods:relatedItem[not(@xlink:href) and (@type='host' or @type='series')]">
          <xsl:with-param name="types" select="'in container'"/>
          <xsl:with-param name="part" select="$part"/>
          <xsl:with-param name="parentGenre" select="$genre"/>
          <xsl:with-param name="documentLanguage" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>
  
      <!-- output -->
      <xsl:if test="$container!=''">
        <xsl:if test="$sepAfterTitle='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$container"/>
      </xsl:if>
      <xsl:variable name="sepAfterContainer" select="$sepAfterTitle='true' or $container!=''"/>
      
      
      <!-- 
        subordinate responsibilities 
      -->
      
      <!-- editors -->
      <xsl:variable name="editors">
        <xsl:if test="$head-roles!=$ROLES_EDITOR">  
          <xsl:call-template name="contributors">
            <xsl:with-param name="roles" select="$ROLES_EDITOR"/>
            <xsl:with-param name="context" select="'subordinate'"/>
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$editors!=''">
        <xsl:if test="$sepAfterContainer='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$editors"/>
      </xsl:if>
      <xsl:variable name="sepAfterEditors" select="$sepAfterContainer='true' or $editors!=''"/>
        
        
      <!-- translators -->
      <xsl:variable name="translators">
        <xsl:if test="$head-roles!=$ROLES_TRANSLATOR">  
          <xsl:call-template name="contributors">
            <xsl:with-param name="roles" select="$ROLES_TRANSLATOR"/>
            <xsl:with-param name="context" select="'subordinate'"/>
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
      
      <!-- output -->
      <xsl:if test="$translators!=''">
        <xsl:if test="$sepAfterEditors='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$translators"/>
      </xsl:if>
      <xsl:variable name="sepAfterTranslators" select="$sepAfterEditors='true' or $translators!=''"/>

      
      <!-- degree grantors -->
      <xsl:variable name="grantors">
        <xsl:if test="$head-roles!=$ROLES_GRANTOR"> 
          <xsl:call-template name="contributors">
            <xsl:with-param name="roles" select="$ROLES_GRANTOR"/>
            <xsl:with-param name="context" select="'subordinate'"/>
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
    
      <!-- output -->
      <xsl:if test="$grantors!=''">
        <xsl:if test="$sepAfterTranslators='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$grantors"/>
      </xsl:if>
      <xsl:variable name="sepAfterGrantors" select="$sepAfterTranslators='true' or $grantors!=''"/>
    
      <!-- edition -->
      <xsl:variable name="edition">
        <xsl:apply-templates select="mods:originInfo/mods:edition"/>
      </xsl:variable>     
      
      <!-- output -->
      <xsl:if test="$edition!=''">
        <xsl:if test="$sepAfterGrantors='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$edition"/>
      </xsl:if>
      <xsl:variable name="sepAfterEdition" select="$sepAfterGrantors='true' or $edition!=''"/>
      
      <!-- place -->
      <xsl:variable name="place">
        <xsl:apply-templates select="mods:originInfo/mods:place"/>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$place!=''">
        <xsl:if test="$sepAfterEdition='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$place"/>
      </xsl:if>
      <xsl:variable name="sepAfterPlace" select="$sepAfterEdition='true' or $place!=''"/>


      <!-- publisher -->
      <xsl:variable name="publisher">
        <xsl:apply-templates select="mods:originInfo/mods:publisher"/>
      </xsl:variable>

      <!-- output (note that it is separated with the place by a colon) -->
      <xsl:if test="$publisher!=''">
        <xsl:choose>
          <xsl:when test="$place!=''">
            <xsl:call-template name="colon-separator">
              <xsl:with-param name="language" select="$displayLanguage"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="$sepAfterPlace='true'">
            <xsl:call-template name="separator"/>
          </xsl:when>
        </xsl:choose>
        <xsl:copy-of select="$publisher"/>
      </xsl:if>
      <xsl:variable name="sepAfterPublisher" select="$sepAfterPlace='true' or $publisher!=''"/> 
    
      <!-- NOTE: ISO 690 places date here -->


      <!-- series (or "collection" in French) -->
      <xsl:variable name="series">
        <xsl:apply-templates select="mods:relatedItem[not(@xlink:href) and (@type='host' or @type='series')]">
          <xsl:with-param name="types" select="'series'"/>
          <xsl:with-param name="parentGenre" select="$genre"/>
          <xsl:with-param name="documentLanguage" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$series!=''">
        <xsl:if test="$sepAfterPublisher='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$series"/>
      </xsl:if>
      <xsl:variable name="sepAfterSeries" select="$sepAfterPublisher='true' or $series!=''"/>

      
      <!-- volume -->
      <xsl:variable name="volume">
        <xsl:apply-templates select="mods:part/mods:detail[@type='volume']">
          <xsl:with-param name="useIssueCaption" select="$parentGenre='workingPaper' or $parentGenre='report'"/>
          <xsl:with-param name="language" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>
      
      <!-- output -->
      <xsl:if test="$volume!=''">
        <xsl:if test="$sepAfterSeries='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$volume"/>
      </xsl:if>
      <xsl:variable name="sepAfterVolume" select="$sepAfterSeries='true' or $volume!=''"/>
      
      
      <!-- part -->
      <xsl:variable name="mpart">
        <xsl:apply-templates select="mods:part/mods:detail[@type='part']">
          <xsl:with-param name="language" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$mpart!=''">
        <xsl:if test="$sepAfterVolume='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$mpart"/>
      </xsl:if>
      <xsl:variable name="sepAfterPart" select="$sepAfterVolume='true' or $mpart!=''"/>


      <!-- chapter -->
      <xsl:variable name="chapter">
        <xsl:apply-templates select="mods:part/mods:detail[@type='chapter']">
          <xsl:with-param name="language" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$chapter!=''">
        <xsl:if test="$sepAfterPart='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$chapter"/>
      </xsl:if>
      <xsl:variable name="sepAfterChapter" select="$sepAfterPart='true' or $chapter!=''"/>


      <!-- issue -->
      <xsl:variable name="issue">
        <xsl:apply-templates select="mods:part/mods:detail[@type='issue']">
          <xsl:with-param name="language" select="$documentLanguage"/>
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$issue!=''">
        <xsl:if test="$sepAfterChapter='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$issue"/>
      </xsl:if>
      <xsl:variable name="sepAfterIssue" select="$sepAfterChapter='true' or $issue!=''"/>

    
      <!-- dates issued, modified -->
      <xsl:variable name="date">
        <xsl:choose>
          <!-- parent has a date: use it -->
          <!-- FIXME: we should "merge" both dates instead. -->
          <xsl:when test="parent::mods:mods/mods:originInfo/*[self::mods:dateIssued or self::mods:dateOther or self::mods:dateModified]">
            <xsl:apply-templates select="../mods:originInfo" mode="dates">
              <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
            </xsl:apply-templates>
          </xsl:when>
          <!-- I am a child: use my date -->
          <xsl:when test="parent::mods:mods">
            <xsl:apply-templates select="mods:originInfo" mode="dates">
              <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
            </xsl:apply-templates>
          </xsl:when>
          <!-- I have no children: use my date -->
          <xsl:when test="not(mods:relatedItem[not(@xlink:href) and (@type='host' or @type='series')])">
            <xsl:apply-templates select="mods:originInfo" mode="dates">
              <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>

      <!-- output -->
      <xsl:if test="$date!=''">
        <xsl:if test="$sepAfterIssue='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$date"/>
      </xsl:if>
      <xsl:variable name="sepAfterDate" select="$sepAfterIssue='true' or $date!=''"/>


      <!-- extent (number of pages) -->
      <xsl:variable name="extent">
        <xsl:if test="$type='document'">
          <xsl:apply-templates select="mods:physicalDescription/mods:extent">   
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:variable>
      
      <!-- output -->
      <xsl:if test="$extent!=''">
        <xsl:if test="$sepAfterDate='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$extent"/>
      </xsl:if>
      <xsl:variable name="sepAfterExtent" select="$sepAfterDate='true' or $extent!=''"/>

      
      <!-- page range -->
      <xsl:variable name="range">
        <xsl:apply-templates select="mods:part" mode="pages">
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>   
    
      <!-- output -->
      <xsl:if test="$range!=''">
        <xsl:if test="$sepAfterExtent='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$range"/>
      </xsl:if>
      <xsl:variable name="sepAfterRange" select="$sepAfterExtent='true' or $range!=''"/>

    
      <!-- physical location (e.g., room) -->
      <xsl:variable name="location">
        <xsl:apply-templates select="mods:location/mods:physicalLocation">
          <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>
      
      <!-- output -->
      <xsl:if test="$location!=''">
        <xsl:if test="$sepAfterRange='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$location"/>
      </xsl:if>
      <xsl:variable name="sepAfterLocation" select="$sepAfterRange='true' or $location!=''"/>
      
      
      <!-- notes (e.g., 'forthcoming') -->
      <xsl:variable name="note">
        <xsl:if test="$type='document'">
          <xsl:apply-templates select="mods:note">  
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:variable>
      
      <!-- output -->
      <xsl:if test="$note!=''">
        <xsl:if test="$sepAfterLocation='true'">
          <xsl:call-template name="separator"/>
        </xsl:if>
        <xsl:copy-of select="$note"/>
      </xsl:if>
      <xsl:variable name="sepAfterNote" select="$sepAfterLocation='true' or $note!=''"/>
      
    </xsl:if>
  </xsl:if>
</xsl:template>



<!-- 
  ******************************************************************************

  Parts of a reference:
  
    mods:physicalDescription/mods:extent
    mods:edition
    mods:publisher
    mods:place/mods:placeTerm
    mods:note
    mods:physicalLocation
    mods:dateIssued, mods:dateModified, mods:dateOther
    mods:part
    mods:extent
    mods:detail
    mods:titleInfo
    

  ******************************************************************************
 -->



<!-- 
  Number of pages
  
  Context node: mods:physicalDescription/mods:extent
  Target nodes: none
    
  Example output: '123 pages'
-->

<xsl:template match="mods:extent[@unit='pages']">
  <span class='mods-number-of-pages'>
    <xsl:value-of select="concat(., ' pages')"/>
  </span>
</xsl:template>


<!-- 
  Edition
  
  Context node: mods:originInfo/mods:edition
  Target nodes: none
    
  Example output: 'second edition'

  TODO: use a caption whenever necessary 
-->

<xsl:template match="mods:edition">
  <span class='mods-edition'>
    <xsl:value-of select="."/>
  </span>
</xsl:template>


<!--
  Place

  Context node: mods:originInfo/mods:place/mods:placeTerm
  Target nodes: none
    
  Example output: 'London'
-->

<xsl:template match="mods:place/mods:placeTerm[@type='text']">
  <span class='mods-place'>
    <xsl:value-of select="."/>
  </span>
</xsl:template>


<!--
  Publisher

  Context node: mods:originInfo/mods:publisher
  Target nodes: none
    
  Example output: 'Princeton University Press' or 'PUF'
  
  TODO: remove 'Inc.', 'Co.', etc.
-->

<!-- publisher -->
<xsl:template match="mods:publisher">
  <span class='mods-publisher'>
    <xsl:value-of select="."/>
  </span>
</xsl:template>


<!--
  Forthcoming

  Context node: mods:note
  Target nodes: none

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
    
  Example output: 'forthcoming'
-->

<xsl:template match="mods:note[@type='local' and text()='forthcoming']">
  <xsl:param name="displayLanguage"/>

  <span class='mods-forthcoming'>
    <xsl:choose>
      <xsl:when test="$displayLanguage='fre'">
        <xsl:text>à paraître</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>forthcoming</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </span>
</xsl:template>


<!--
  Physical location

  Context node: mods:physicalLocation
  Target nodes: none

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
    
  Example output: 'room MS001'
-->

<xsl:template match="mods:physicalLocation">
  <xsl:param name="displayLanguage"/>

  <span class='mods-location'>
    <xsl:if test="@displayLabel">
    
      <!-- give us a chance to translate the most common labels -->
      <xsl:variable name="label">
        <xsl:choose>
        
          <!-- room -->
          <xsl:when test="@displayLabel='Room'">
            <xsl:choose>
              <xsl:when test="$displayLanguage='fre'">
                <xsl:text>salle</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>room</xsl:text>
              </xsl:otherwise>
            </xsl:choose> 
          </xsl:when>
          
          <!-- unknow display label: use it as-is -->
          <xsl:otherwise>
            <xsl:value-of select="@displayLabel"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:value-of select="$label"/>
      <xsl:call-template name="nbsp"/>
    </xsl:if>
    <xsl:value-of select="."/>
  </span>
</xsl:template>



<!-- 
  Dates

  Context node: mods:originInfo
  Target nodes: mods:dateIssued, mods:dateModified, mods:dateOther

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
  
  Example output: 'April 1, 2014, 12:30'
  Example output: 'April 1-5, 2014'
  Example output: 'January 31 to February 2, 2014'
  Example output: 'Winter 2014'
  Example output: 'March 2010, updated  May 2014'
  
  TODO: missing start or end 
-->

<!-- dates in an originInfo node -->
<xsl:template match="mods:originInfo" mode="dates">
  <xsl:param name="displayLanguage"/>
  <xsl:choose>
    <!-- if mods:dateOther is present, no other dates should be displayed -->
    <xsl:when test="mods:dateOther">
      <span class="mods-date-other">
        <xsl:value-of select="mods:dateOther"/>
      </span>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="issued">
        <xsl:if test="mods:dateIssued">
          <xsl:call-template name="format-datetime-interval">
            <xsl:with-param name="date1" select="mods:dateIssued[@point='start' or position()=1]"/>
            <xsl:with-param name="date2" select="mods:dateIssued[@point='end']"/>
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>

      <xsl:if test="$issued!=''">
        <span class="mods-date-issued">
          <xsl:copy-of select="$issued"/>
        </span>
      </xsl:if>

      <xsl:variable name="modifed">
        <xsl:if test="mods:dateModified">
          <xsl:call-template name="format-datetime-interval">
            <xsl:with-param name="date1" select="mods:dateModified[position()=1]"/>
            <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:variable>
      
      <xsl:if test="$modifed!=''">
        <xsl:if test="$issued!=''">
          <xsl:call-template name="separator"/>
        </xsl:if>
      
        <span class="mods-date-modified">
          <xsl:choose>
            <xsl:when test="$displayLanguage='fre'">
              <xsl:text>révision </xsl:text>    <!-- TODO: "révisé le/en" -->
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>revised </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:copy-of select="$modifed"/>
        </span>
      </xsl:if>
      
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Pages

  Context node: mods:part
  Target nodes: mods:extent

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
  
  TODO: other units
-->

<xsl:template match="mods:part" mode="pages">
  <xsl:param name="displayLanguage"/>

  <xsl:apply-templates select="mods:extent[@unit='page'][1]">
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:apply-templates>
</xsl:template>



<!-- 
  Page range

  Context node: mods:extent
  Target nodes: mods:start, mods:end

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
  
  Example output: 'pp. 10-35'
  Example output: 'p. 5'
  
  TODO: missing start or end 
-->

<xsl:template match="mods:extent[@unit='page']">
  <xsl:param name="displayLanguage"/>

  <xsl:if test="mods:start and mods:end">
    <span class='mods-pages'>
      <xsl:variable name="same" select="mods:start=mods:end"/>
      
      <!-- prefix: p. or pp. -->
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:text>p.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$same">
              <xsl:text>p.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>pp.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- separator -->
      <xsl:call-template name="nbsp"/>
      
      <!-- page number or page range -->
      <xsl:value-of select="mods:start"/>
      <xsl:if test="not($same)">
        <xsl:text>&#8211;</xsl:text>
        <xsl:value-of select="mods:end"/>
      </xsl:if>
    </span>
  </xsl:if>
</xsl:template>


<!-- 
  Details

  Context node: mods:detail
  Target nodes: mods:caption, mods:number, mods:title 
  
  @param string $useIssueCaption 'true' to use the caption for "issue number" 
                                   instead of the default caption
  @param string $language        language of the document (e.g. 'fre')
  @param string $displayLanguage display language (e.g. 'fre' or 'eng')
  
  Example output: 'vol. 4, n. 2'
  Example output: 'chapter 4: "state of the art"'
  Example output: '"special issue on market microstructure"'
  Example output: 'special issue: "market microstructure"'
  
  FIXME: no space after French "n°"
-->

<xsl:template match="mods:detail">
  <xsl:param name="useIssueCaption" select="'false'"/>
  <xsl:param name="language"/>
  <xsl:param name="displayLanguage"/>

  <!-- span element with a class equal to the detail type, if any -->
  <span>
    <xsl:if test="@type">
      <xsl:attribute name="class">
        <xsl:value-of select="concat('mods-detail-', @type)"/>
      </xsl:attribute>
    </xsl:if>
    
    <!-- default caption -->
    <xsl:variable name="default-caption">
      <xsl:choose>
        <xsl:when test="@type='issue' or $useIssueCaption='true'">
          <xsl:choose>
            <xsl:when test="$displayLanguage='fre'">
              <xsl:text>n°</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>n.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="@type='volume'">
          <xsl:choose>
            <xsl:when test="$displayLanguage='fre'">
              <xsl:text>vol.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>vol.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="@type='part'">
          <xsl:choose>
            <xsl:when test="$displayLanguage='fre'">
              <xsl:text>partie</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>part</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="@type='chapter'">
          <xsl:choose>
            <xsl:when test="$displayLanguage='fre'">
              <xsl:text>chapitre</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>chapter</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- a supplied caption is always displayed, even if no number are 
      available -->
    <xsl:value-of select="mods:caption"/>
    
    <xsl:if test="mods:number">
    
      <!-- use default caption when no caption are available -->
      <xsl:if test="not(mods:caption) and string-length($default-caption)">
        <xsl:value-of select="$default-caption"/>
      </xsl:if>
      
      <!-- separator between caption and number -->
      <xsl:if test="mods:caption or string-length($default-caption)">
        <xsl:call-template name="nbsp"/>
      </xsl:if>
      
      <!-- finaly, the number itself -->
      <xsl:value-of select="mods:number"/>
    </xsl:if>
    
    <xsl:if test="mods:title">
      <!-- separator (spacing follows the display language, not the document 
        language) -->
      <xsl:if test="mods:caption or mods:number">
        <xsl:call-template name="colon-separator">
          <xsl:with-param name="language" select="$displayLanguage"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:call-template name="title">
        <xsl:with-param name="language" select="$language"/>
        <xsl:with-param name="quoted" select="'true'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  </span>
</xsl:template>


<!-- 
  Complete title, with an optional caption and quotes

  Context node: mods:titleInfo
  Target nodes: mods:title, mods:parNumber, mods:partName 

  @param string $type               type of item ('document', 'in', 'container',
                                      'series')
  @param string $genre              genre of the item
  @param string $language           language of the document (e.g. 'fre')
  @param string $href               url (if any) the title must be href'ed to
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
  
  Example output: 'A Primer on Auction Design'
  Example output: 'series: "Topics in Regulatory Economics and Policy"'
  Example output: 'in: "The Olympics: a history" (Part I: Ancient)'
  
  TODO: type="uniform"
-->
  
<xsl:template match="mods:titleInfo">
  <xsl:param name="type"/>
  <xsl:param name="genre"/>
  <xsl:param name="language"/>
  <xsl:param name="href"/>
  <xsl:param name="displayLanguage"/>
  

  <xsl:variable name="quoted">
    <xsl:call-template name="item-title-must-be-quoted">
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="genre" select="$genre"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="caption">
    <xsl:call-template name="title-caption">
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>
  </xsl:variable>
  
  <span>
    <xsl:attribute name="class">
      <xsl:choose>
        <xsl:when test="$quoted='true'">
          <xsl:text>mods-quoted-title</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>mods-unquoted-title</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>


    <!-- optional caption -->
    <xsl:if test="string-length($caption)">
      <xsl:value-of select="$caption"/>
      <xsl:call-template name="nbsp"/>    
    </xsl:if>
  
    
    <!-- main title, possibly quoted and href'ed -->
    <xsl:call-template name="title">
      <xsl:with-param name="language" select="$language"/>
      <xsl:with-param name="quoted" select="$quoted"/>
      <xsl:with-param name="href" select="$href"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>

  
    <!-- part -->
    <xsl:if test="mods:parNumber|mods:partName">
    
      <xsl:text> (</xsl:text>
      
      <!-- part number, e.g. "Part I" -->
      <xsl:if test="mods:parNumber">
        <xsl:value-of select="mods:parNumber"/>
        <xsl:if test="mods:partName">
          <xsl:call-template name="colon-separator">
            <xsl:with-param name="language" select="$language"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:if>
      
      <!-- part name, e.g. "Ancient" -->
      <xsl:if test="mods:partName">
        <xsl:value-of select="mods:partName"/>
      </xsl:if>
  
      <xsl:text>)</xsl:text>
    </xsl:if>
  </span>
</xsl:template>


<!-- 
  Title and subtitle, optionally quoted and href'ed
  
  Sine most browsers do not support language dependent <q> nicely,
    we generate our own double quotes.

  Context node: mods:titleInfo
  Target nodes: mods:nonSort, mods:title, mods:subTitle 

  @param string $language         language of the document (e.g. 'fre')
  @param string $quoted           'true' if the title must be quoted
  @param string $href             url (if any) the title must be href'ed to
  @param string $displayLanguage  display language (e.g. 'fre' or 'eng')

  Example: 'The Olympics: a history'
  
  TODO: quote rules for other languages
-->

<xsl:template name="title">
  <xsl:param name="language"/>
  <xsl:param name="quoted" select="'false'"/>
  <xsl:param name="href" select="''"/>
  <xsl:param name="displayLanguage"/>

  <!-- opening quote -->
  <xsl:if test="$quoted='true'">
    <xsl:choose>
      <xsl:when test="$displayLanguage='fre'">
        <xsl:text>&#171;</xsl:text>
        <xsl:call-template name="nbsp"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#8220;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
  
  <!-- title and subtitle (w/ or w/o an href) -->
  <xsl:choose>
    <xsl:when test="string-length($href)">

      <!-- API: //a[@class='mods-link-item']/span -->
      <a class='mods-link-item'>
        <xsl:attribute name="href">
          <xsl:value-of select="$href"/>
        </xsl:attribute>
        
        <span>
          <xsl:call-template name="unquoted-title">
            <xsl:with-param name="language" select="$language"/>
          </xsl:call-template>
        </span>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="unquoted-title">
        <xsl:with-param name="language" select="$language"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>

  <!-- closing quote -->
  <xsl:if test="$quoted='true'">
    <xsl:choose>
      <xsl:when test="$displayLanguage='fre'">
        <xsl:call-template name="nbsp"/>
        <xsl:text>&#187;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#8221;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
  
</xsl:template>



<!-- 
  Unquoted title and subtitle

  Context node: mods:titleInfo
  Target nodes: mods:nonSort, mods:title, mods:subTitle 

  @param string $language language of the document (e.g. 'fre')

  Example: 'The Olympics: a history'
  
  TODO: other languages
  
  FIXME: no classes should be generated when called from mods:part
-->

<xsl:template name="unquoted-title">
  <xsl:param name="language"/>
  
  <!-- main title -->
  <span class="mods-title">
    <xsl:value-of select="mods:nonSort"/>
    <xsl:value-of select="mods:title"/>
  </span>
  
  <!-- subtitle -->
  <xsl:if test="mods:subTitle">
    <xsl:call-template name="colon-separator">
      <xsl:with-param name="language" select="$language"/>
    </xsl:call-template>
    <span class="mods-subtitle">
      <xsl:value-of select="mods:subTitle"/>
    </span>
  </xsl:if>

</xsl:template>


<!-- 
  A colon as a separator, following the typographic rules of a given language,
    and a 'lang' attribute of the context node

  Context node: any node

  TODO: other languages for which a space is required; other language encoding
-->
<xsl:template name="colon-separator">
  <xsl:param name="language"/>
  
  <!-- is a space needed before the colon? -->
  <xsl:if test="@lang='fre' or not(@lang) and $language='fre'">
    <xsl:call-template name="nbsp"/>
  </xsl:if>
  
  <xsl:text>: </xsl:text>
</xsl:template>



<!-- 
  ******************************************************************************

  Additional sections:
  
    section-urls
    section-keywords
    section-abstract
    section-jelcodes
    sections-related (generates several sections)
    section-fragments
    
  
  ******************************************************************************
 -->


<!-- 
  Section: fragments
  
  Context node: mods:mods
  Target nodes: *

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
  
  This template does nothing. It is meant to be overwritten by an imported 
    stylesheet.
-->

<xsl:template name="section-fragments">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>
</xsl:template>



<!-- 
  Section: urls
  
  Context node: mods:mods
  Target nodes: mods:location/mods:url

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="section-urls">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="urls">
    <xsl:apply-templates select="mods:location/mods:url"/>
  </xsl:variable>
  
  <xsl:if test="$urls!=''">
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'urls'"/>
        <xsl:with-param name="heading_fre" select="'Lien{s}'"/>
        <xsl:with-param name="heading_eng" select="'Link{s}'"/>
        <xsl:with-param name="count" select="count(mods:location/mods:url)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
      
    <!-- body -->
    <div class="mods-section-body mods-urls">
      <xsl:copy-of select="$urls"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  url
  
  Context node: mods:url
  
  TODO: check the url is valid
-->

<xsl:template match="mods:url">

  <xsl:variable name="href" select="normalize-space(.)"/>

  <xsl:choose>
    <xsl:when test="$href!=''"> <!-- TODO: test for validity instead -->
      <div class="mods-one-url">
        <a>
          <xsl:variable name="s1">
            <xsl:if test="@usage='primary display' or @usage='primary'">
              <xsl:text>mods-url-primary-display</xsl:text>
            </xsl:if>
          </xsl:variable>
          
          <xsl:variable name="s2">
            <xsl:if test="@access='object in context'">
              <xsl:text>mods-url-object-in-context</xsl:text>
            </xsl:if>
          </xsl:variable>
    
          <xsl:variable name="s3">
            <xsl:if test="@access='raw object'">
              <xsl:text>mods-url-raw-object</xsl:text>
            </xsl:if>
          </xsl:variable>
    
          <xsl:variable name="class" select="normalize-space(concat('mods-link-url', ' ', $s1,' ', $s2, ' ', $s3))"/>
          <xsl:if test="string-length($class)">
            <xsl:attribute name="class">
              <xsl:value-of select="$class"/>
            </xsl:attribute>
          </xsl:if>
          
          <xsl:attribute name="href">
            <xsl:value-of select="$href"/>
          </xsl:attribute>
          
          <xsl:choose>
            <xsl:when test="@displayLabel">
              <xsl:value-of select="@displayLabel"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$href"/>
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'empty url'"/>
        <xsl:with-param name="var" select="mods:url"/>
        <xsl:with-param name="exp" select="'mods:url should not be empty'"/>
      </xsl:call-template>
    </xsl:otherwise>    
  </xsl:choose>
  
</xsl:template>


<!-- 
  Section: keywords
  
  Context node: mods:mods
  Target nodes: mods:subject

  @param string $withHeading        display heading?
  @param string $catalogingLanguage cataloging language (e.g. 'fre' or 'eng')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="section-keywords">
  <xsl:param name="withHeading"/>
  <xsl:param name="catalogingLanguage"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="subjects">
    <xsl:apply-templates select="mods:subject">
      <xsl:with-param name="catalogingLanguage" select="$catalogingLanguage"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$subjects!=''">
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'keywords'"/>
        <xsl:with-param name="heading_fre" select="'Mot{s} clef{s}'"/>
        <xsl:with-param name="heading_eng" select="'Keyword{s}'"/>
        <xsl:with-param name="count" select="count(mods:subject)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- body -->
    <div class="mods-section-body mods-keywords">
      <xsl:copy-of select="$subjects"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  subject
  
  Context node: mods:subject
  Target nodes: mods:topic

  @param string $catalogingLanguage cataloging language (e.g. 'fre' or 'eng')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template match="mods:subject">
  <xsl:param name="catalogingLanguage"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="count1" select="count(mods:topic)"/>
  <xsl:variable name="count2" select="count(mods:topic[@lang=$displayLanguage])"/>

  <xsl:variable name="topic">
    <xsl:value-of select="mods:topic[$count1=1 or @lang=$displayLanguage 
      or ($count2=0 and not(@lang) and $displayLanguage=$catalogingLanguage)]"/>      
  </xsl:variable>

  <xsl:if test="$topic!=''">
    
    <!-- one keyword -->
    <div class="mods-one-keyword">
      <xsl:copy-of select="$topic"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  Section: abstract
  
  Context node: mods:mods
  Target nodes: mods:abstract

  @param string $withHeading        display heading?
  @param string $catalogingLanguage cataloging language (e.g. 'fre' or 'eng')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="section-abstract">
  <xsl:param name="withHeading"/>
  <xsl:param name="catalogingLanguage"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="count1" select="count(mods:abstract)"/>
  <xsl:variable name="count2" select="count(mods:abstract[@lang=$displayLanguage])"/>

  <xsl:variable name="abstract">
    <xsl:value-of select="mods:abstract[$count1=1 or @lang=$displayLanguage 
      or ($count2=0 and not(@lang) and $displayLanguage=$catalogingLanguage)]"/>      
  </xsl:variable>
  
  <xsl:if test="$abstract!=''">
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'abstract'"/>
        <xsl:with-param name="heading_fre" select="'Résumé'"/>
        <xsl:with-param name="heading_eng" select="'Abstract'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- body -->
    <div class="mods-section-body mods-abstract">
      <div class="mods-one-abstract">
        <xsl:copy-of select="$abstract"/>
      </div>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  Section: JEL codes

  Context node: mods:mods
  Target nodes: mods:classification 

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->
 
<xsl:template name="section-jelcodes">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="jelcodes">
    <xsl:apply-templates select="mods:classification[@authority='jelc']">
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:apply-templates>
  </xsl:variable>
  
  <xsl:if test="$jelcodes!=''">
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'jelcodes'"/>
        <xsl:with-param name="heading_fre" select="'Code{s} JEL'"/>
        <xsl:with-param name="heading_eng" select="'JEL code{s}'"/>
        <xsl:with-param name="count" select="count(mods:classification[@authority='jelc'])"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- body -->
    <div class="mods-section-body mods-jelcodes">
      <xsl:copy-of select="$jelcodes"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  JEL code, looking up in an external document stored in $JEL_CODES
  
  Context node: mods:classification

  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template match="mods:classification[@authority='jelc']">
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="code" select="normalize-space(.)"/>
  
  <xsl:choose>
    <xsl:when test="$code!=''">
      <div class="mods-one-jelcode">
        <span class="mods-jel-code">
          <xsl:value-of select="$code"/>
        </span>
        
        <xsl:variable name="description" 
          select="$JEL_CODES/data//classification/code[text()=$code]/../description"/>          
    
        <xsl:choose>
          <xsl:when test="$description!=''">
            <xsl:call-template name="colon-separator">
              <xsl:with-param name="language" select="$displayLanguage"/>
            </xsl:call-template>
            
            <!-- replace HTML entities from the CDATA section -->
            <xsl:variable name="s1">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="search" select="'&amp;bull;'"/>
                <xsl:with-param name="replace" select="'&#8226;'"/>
                <xsl:with-param name="string" select="$description"/>       
              </xsl:call-template>
            </xsl:variable>     
            <xsl:variable name="s2">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="search" select="'&amp;ndash;'"/>
                <xsl:with-param name="replace" select="'&#8211;'"/>
                <xsl:with-param name="string" select="$s1"/>        
              </xsl:call-template>
            </xsl:variable>
            
            <span class="mods-jel-description">
              <xsl:value-of select="$s2"/>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="debug">
              <xsl:with-param name="msg" select="'invalid JEL code description'"/>
              <xsl:with-param name="var" select="."/>
              <xsl:with-param name="exp" select="'make sure the description file is accessible'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:when> 
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'empty JEL code'"/>
        <xsl:with-param name="var" select="."/>
        <xsl:with-param name="exp" select="'JEL code should not be empty'"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
  
</xsl:template>


<!-- 
  Sections: relations to other items
  
  The relation is determined by type attribute _and_ the displayLabel attribute.
  
  Context node: mods:mods
  Target nodes: mods:relatedItem

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="sections-related">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>

  <!-- series: series of events -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'series'"/>
    <xsl:with-param name="displayLabel" select="'Series of events'"/>
    <xsl:with-param name="heading_fre" select="concat('Série{s} d',$APOS,'événements')"/>
    <xsl:with-param name="heading_eng" select="'Series of events'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>

  <!-- preceding: replaces -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'preceding'"/>
    <xsl:with-param name="displayLabel" select="'Preceding title'"/>
    <xsl:with-param name="heading_fre" select="'Remplace'"/>
    <xsl:with-param name="heading_eng" select="'Replaces'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>

  <!-- preceding: preceding event -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'preceding'"/>
    <xsl:with-param name="displayLabel" select="'Preceding event'"/>
    <xsl:with-param name="heading_fre" select="'Événement{s} précédent{s}'"/>
    <xsl:with-param name="heading_eng" select="'Preceding event{s}'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>

  <!-- succeeding: replaced by -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'succeeding'"/>
    <xsl:with-param name="displayLabel" select="'Succeeding title'"/>
    <xsl:with-param name="heading_fre" select="'Remplacé par'"/>
    <xsl:with-param name="heading_eng" select="'Replaced by'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>

  <!-- succeeding: succeeding event -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'succeeding'"/>
    <xsl:with-param name="displayLabel" select="'Succeeding event'"/>
    <xsl:with-param name="heading_fre" select="'Événement{s} suivant{s}'"/>
    <xsl:with-param name="heading_eng" select="'Succeeding event{s}'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>
  
  <!-- otherFormat: reprint -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'otherFormat'"/>
    <xsl:with-param name="displayLabel" select="'Reprinted as'"/>
    <xsl:with-param name="heading_fre" select="'Réimpression'"/>
    <xsl:with-param name="heading_eng" select="'Reprinted as'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>
  
  <!-- original: reprint -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'original'"/>
    <xsl:with-param name="displayLabel" select="'Translated from'"/>
    <xsl:with-param name="heading_fre" select="'Traduit de'"/>
    <xsl:with-param name="heading_eng" select="'Translated from'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>

  <!-- references: see also -->
  <xsl:call-template name="section-related">
    <xsl:with-param name="withHeading" select="$withHeading"/>
    <xsl:with-param name="type" select="'references'"/>
    <xsl:with-param name="displayLabel" select="'See also'"/>
    <xsl:with-param name="heading_fre" select="'Voir aussi'"/>
    <xsl:with-param name="heading_eng" select="'See also'"/>
    <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
  </xsl:call-template>
  
</xsl:template>


<!-- 
  Section: relations to other items (a single section)
  
  Context node: mods:mods
  Target nodes: mods:relatedItem
  
  @param string $withHeading      display heading?
  @param string $type             type attribute of the target items
  @param string $displayLabel     displayLabel attribute of the target items
  @param string $heading_fre      section heading in French
  @param string $heading_eng      section heading in English
  @param string $displayLanguage  display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="section-related">
  <xsl:param name="withHeading"/>
  <xsl:param name="type"/>
  <xsl:param name="displayLabel" select="''"/>
  <xsl:param name="heading_fre"/>
  <xsl:param name="heading_eng"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:variable name="items">
    <xsl:apply-templates select="mods:relatedItem[@xlink:href and @type=$type and ($displayLabel='' or @displayLabel=$displayLabel)]"/>
  </xsl:variable>
  
  <xsl:if test="$items!=''">
  
    <xsl:variable name="section-key" select="concat('related-', $type)"/> <!-- FIXME: use displayLabel? -->
  
    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="$section-key"/>  
        <xsl:with-param name="heading_fre" select="$heading_fre"/>
        <xsl:with-param name="heading_eng" select="$heading_eng"/>
        <xsl:with-param name="count" select="count(mods:relatedItem[@xlink:href and @type=$type and ($displayLabel='' or @displayLabel=$displayLabel)])"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- body -->
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('mods-section-body mods-', $section-key)"/>
       </xsl:attribute>
      <xsl:copy-of select="$items"/>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  a related item (as a part of a single section)
  
  Context node: mods:mods
  Target nodes: mods:relatedItem
-->

<xsl:template match="mods:relatedItem[@xlink:href]">

  <xsl:variable name="href">
    <xsl:value-of select="normalize-space(@xlink:href)"/>
  </xsl:variable>
  
  <xsl:choose>
    <xsl:when test="$href!=''">
      <div class="mods-one-related">
        <a class='mods-link-related'>
          <xsl:attribute name="href">
            <xsl:value-of select="$href"/>
          </xsl:attribute>
          <xsl:copy-of select="$href"/>
        </a>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'empty xlink in related item'"/>
        <xsl:with-param name="var" select="mods:identifier[@type='local']"/>
        <xsl:with-param name="exp" select="'xlink should contain a href'"/>
      </xsl:call-template>
    </xsl:otherwise>    
  </xsl:choose>
</xsl:template>




<!-- 
  ******************************************************************************

  High-level functions to handle contributors:
  
    contributors
    other-contributors


  ******************************************************************************
 -->

<!-- 
  Contributors

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name

  Example output:
  
    authors     : 'Doe, John, and Joe Smith'
    coauthors   : '(with John Doe and Joe Smith)'
    editors     : 'Doe, John, and Joe Smith (eds.)'
    editors     : 'sous la direction de John Doe et Joe Smith'
    editors     : 'John Doe (ed.)'
    translators : 'translated by John Doe and Joe Smith'
    grantor     : 'West Virginia University'
  
  @param string $roles              blank-separated list of roles to take into 
                                      account (e.g., 'aut spk')
  @param string $context            context: 
                                      - 'primary': primary responsibility (head 
                                          of a reference)
                                      - 'subordinate': subordinate 
                                          responsibility (within a reference)
                                      - 'with': list of co-contributors 
                                          ("with ...")
  @param string $uriToSkip          valueURI to skip, or '' if all contributors 
                                      must be listed
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="contributors">
  <xsl:param name="roles"/>
  <xsl:param name="context"/>
  <xsl:param name="uriToSkip" select="''"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="count">
    <xsl:call-template name="number-of-contributors">
      <xsl:with-param name="roles" select="$roles"/>
      <xsl:with-param name="uriToSkip" select="$uriToSkip"/>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:if test="$count &gt; 0">
  
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="concat('mods-contributors-', $context)"/>
      </xsl:attribute>
      
      <xsl:variable name="prefix">
        <xsl:choose>
        
          <xsl:when test="$context='with'">
            <xsl:choose>
              <xsl:when test="$displayLanguage='fre'">
                <xsl:text>(avec </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>(with </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$context='subordinate'">
            <xsl:choose>
              <xsl:when test="$roles=$ROLES_EDITOR">
                <xsl:choose>
                  <xsl:when test="$displayLanguage='fre'">
                    <xsl:text>sous la direction de </xsl:text>
                  </xsl:when>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$roles=$ROLES_TRANSLATOR">
                <xsl:choose>
                  <xsl:when test="$displayLanguage='fre'">
                    <xsl:text>traduit par </xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>translated by </xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
        </xsl:choose>
      </xsl:variable>
    
      <xsl:variable name="postfix">
      
        <xsl:choose>
          <xsl:when test="$context='with'">
            <xsl:text>)</xsl:text>
          </xsl:when>

          <xsl:when test="$context='primary'">
            <xsl:choose>
              <xsl:when test="$roles=$ROLES_EDITOR">
                <xsl:choose>
                  <xsl:when test="$displayLanguage='fre'">
                    <xsl:text> (éd{s}.)</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text> (ed{s}.)</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$roles=$ROLES_TRANSLATOR">
                <xsl:choose>
                  <xsl:when test="$displayLanguage='fre'">
                    <xsl:text> (trad.)</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text> (trans.)</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$context='subordinate'">
            <xsl:if test="$roles=$ROLES_EDITOR and $displayLanguage!='fre'">
              <xsl:text> (ed{s}.)</xsl:text>
            </xsl:if>
          </xsl:when>
          
        </xsl:choose>
      </xsl:variable>
    
    
      <xsl:call-template name="contributors-by-role">
        <xsl:with-param name="roles" select="$roles"/>
        <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="postfix" select="$postfix"/>
        <xsl:with-param name="uriToSkip" select="$uriToSkip"/>
        <xsl:with-param name="familyFirst" select="'false'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
    </span>
  </xsl:if>
</xsl:template>


<!--
  Other contributors

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name

  Example output: 'Discussant: John Doe'
  Example output: 'Supervised by John Doe and Joe Smith'  

  @param string $withHeading        display heading?
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="section-other-contributors">
  <xsl:param name="withHeading"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="count">
    <xsl:call-template name="number-of-contributors">
      <xsl:with-param name="roles" select="'ths rev mod cmm orm ive rtm ctb oth'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="$count &gt; 0">

    <!--  heading -->
    <xsl:if test="$withHeading='true'">
      <xsl:call-template name="section-head">
        <xsl:with-param name="key" select="'other-contributors'"/>
        <xsl:with-param name="heading_fre" select="'Contributeurs'"/>
        <xsl:with-param name="heading_eng" select="'Contributors'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
    
    <div class="mods-section-body mods-other-contributors">
      <!-- Thesis advisor -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'ths'"/>
        <xsl:with-param name="prompt_fre" select="'Dirigé par'"/>
        <xsl:with-param name="prompt_eng" select="'Supervised by'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- Reviewer -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'rev'"/>
        <xsl:with-param name="prompt_fre" select="'Évalué par'"/>
        <xsl:with-param name="prompt_eng" select="'Refereed by'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- Moderator -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'mod'"/>
        <xsl:with-param name="prompt_fre" select="'Présidé par'"/>
        <xsl:with-param name="prompt_eng" select="'Chaired by'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    
      <!-- Commentator -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'cmm'"/>
        <xsl:with-param name="prompt_fre" select="'Discuté par'"/>
        <xsl:with-param name="prompt_eng" select="'Discussed by'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- Organizer of meeting -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'orm'"/>
        <xsl:with-param name="prompt_fre" select="'Organisé par'"/>
        <xsl:with-param name="prompt_eng" select="'Organized by'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    
      <!-- Interviewee -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'ive'"/>
        <xsl:with-param name="prompt_fre" select="'Interviewé{s} :'"/>
        <xsl:with-param name="prompt_eng" select="'Interviewee{s}:'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- Research team member -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'rtm'"/>
        <xsl:with-param name="prompt_fre" select="'Membre{s} :'"/>
        <xsl:with-param name="prompt_eng" select="'Member{s}:'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- Contributor and other types of contribution -->
      <xsl:call-template name="other-contributors-by-role">
        <xsl:with-param name="roles" select="'ctb oth'"/>
        <xsl:with-param name="prompt_fre" select="'Contributeur{s} :'"/>
        <xsl:with-param name="prompt_eng" select="'Contributor{s}:'"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </div>
  </xsl:if>
</xsl:template>


<!--
  Other contributors having a role in a given set 

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name

  @param string $roles              a blank-separated list of roles (e.g., 
                                      'ctb oth')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: 'Supervised by John Doe and Joe Smith' 
-->


<xsl:template name="other-contributors-by-role">
  <xsl:param name="roles"/>
  <xsl:param name="prompt_eng"/>
  <xsl:param name="prompt_fre"/>
  <xsl:param name="displayLanguage"/>

  <xsl:variable name="count">
    <xsl:call-template name="number-of-contributors">
      <xsl:with-param name="roles" select="$roles"/>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:if test="$count &gt; 0">
    <div>
      <!-- select the prompt in the current display language -->
      <xsl:variable name="prompt">
        <xsl:choose>
          <xsl:when test="$displayLanguage='fre'">
            <xsl:value-of select="$prompt_fre"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$prompt_eng"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- list of contributors -->
      <xsl:call-template name="contributors-by-role">
        <xsl:with-param name="roles" select="$roles"/>
        <xsl:with-param name="prefix" select="concat($prompt, ' ')"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- final dot -->
      <xsl:text>.</xsl:text>
    </div>
  </xsl:if>
</xsl:template>


<!-- 
  ******************************************************************************

  Low-level functions to handle contributors:
  
    number-of-contributors
    contributors


  ******************************************************************************
 -->


<!-- 
  Return the number of contributors having a role in a given set (zero if the 
    set is empty)

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name
  
  @param string $roles      string a blank-separated roles (e.g., 'aut spk')
  @param string $uriToSkip  valueURI to skip, or '' if all contributors must 
                              be counted
-->

<xsl:template name="number-of-contributors-in-set">
  <xsl:param name="roles"/>
  <xsl:param name="uriToSkip" select="''"/>
  
  <xsl:choose>
    <xsl:when test="$roles=''">
      <xsl:value-of select="0"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="number-of-contributors">
        <xsl:with-param name="roles" select="$roles"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Return the number of contributors, having a role in a given set

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name
  
  @param string $roles        string a blank-separated roles (e.g., 'aut spk')
  @param string $uriToSkip    valueURI to skip, or '' if all contributors must 
                                be counted
-->

<xsl:template name="number-of-contributors">
  <xsl:param name="roles"/>
  <xsl:param name="uriToSkip" select="''"/>
  
  <xsl:value-of select="count(mods:name[($uriToSkip='' or @valueURI!=$uriToSkip) 
    and mods:role/mods:roleTerm[@authority='marcrelator' and @type='code'][contains($roles, .)]])"/>
</xsl:template>


<!-- 
  Contributors having a role in a given set

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name
  
  @param string $roles              string a blank-separated roles (e.g., 
                                      'aut spk')
  @param string $prefix             string to display before the list of 
                                      contributors
  @param string $postfix            string to display after the list of 
                                      contributors
  @param string $familyFirst        'true' if a first contributor's family name 
                                      must be displayed before his surname
  @param string $uriToSkip          valueURI to skip, or '' if no names must be 
                                      skipped
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="contributors-by-role">
  <xsl:param name="roles"/>
  <xsl:param name="prefix" select="''"/>
  <xsl:param name="postfix" select="''"/>
  <xsl:param name="familyFirst" select="'false'"/>
  <xsl:param name="uriToSkip" select="''"/>
  <xsl:param name="displayLanguage"/>
  
  
  <xsl:variable name="count">
    <xsl:call-template name="number-of-contributors">
      <xsl:with-param name="roles" select="$roles"/>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:if test="$count &gt; 0">

    <!-- calculate the actual prefix string -->
    <xsl:variable name="prefixString">
      <xsl:call-template name="singular-or-plural">
        <xsl:with-param name="string" select="$prefix"/>
        <xsl:with-param name="count" select="$count"/>
      </xsl:call-template>
    </xsl:variable>
  
    <!-- prefix -->
    <xsl:if test="string-length($prefixString)">
      <xsl:value-of select="$prefixString"/>
    </xsl:if>
    
    <!-- list of contributors -->
    <xsl:call-template name="list-of-contributors">
      <xsl:with-param name="roles" select="$roles"/>
      <xsl:with-param name="familyFirst" select="$familyFirst"/>
      <xsl:with-param name="uriToSkip" select="$uriToSkip"/>
      <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
    </xsl:call-template>
    
    <!-- calculate the actual postfix string -->
    <xsl:variable name="postfixString">
      <xsl:call-template name="singular-or-plural">
        <xsl:with-param name="string" select="$postfix"/>
        <xsl:with-param name="count" select="$count"/>
      </xsl:call-template>
    </xsl:variable>
  
    <!-- postfix -->
    <xsl:if test="string-length($postfixString)">
      <xsl:value-of select="$postfixString"/>
    </xsl:if>

  </xsl:if>
</xsl:template>


<!-- 
  List of contributors having a role in a given set

  Context node: mods:mods or mods:relatedItem
  Target nodes: mods:name
  
  @param string $roles              string a blank-separated roles (e.g., 
                                      'aut spk')
  @param string $familyFirst        'true' if a first contributor's family name 
                                      must be displayed before his/her surname
  @param string $uriToSkip          valueURI to skip, or '' if no names must be 
                                      skipped
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')
-->

<xsl:template name="list-of-contributors">
  <xsl:param name="roles"/>
  <xsl:param name="familyFirst" select="'false'"/>
  <xsl:param name="uriToSkip" select="''"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:for-each select="mods:name[($uriToSkip='' or @valueURI!=$uriToSkip) 
    and mods:role/mods:roleTerm[@authority='marcrelator' and @type='code'][contains($roles, .)]]">
  
    <!-- name of the contributor, with an hyperlink whenever available -->
    <xsl:choose>
    
      <xsl:when test="@valueURI">

        <!-- API: //a[@class='mods-link-name mods-role-$role']/span -->
        <a>
          <xsl:attribute name="class">
            <xsl:value-of select="concat('mods-link-name', ' ', 'mods-role-', ./mods:role/mods:roleTerm[@authority='marcrelator' and @type='code'])"/>
          </xsl:attribute>
          <xsl:attribute name="href">
            <xsl:value-of select="@valueURI"/>
          </xsl:attribute>
          <span>
            <xsl:call-template name="contributor-name">
              <xsl:with-param name="familyFirst" select="$familyFirst"/>
            </xsl:call-template>
          </span>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="contributor-name">
          <xsl:with-param name="familyFirst" select="$familyFirst"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <!-- affiliation -->
    <xsl:if test="mods:affiliation">
      <!-- do not display affiliation for authors, editors, translators -->
      <xsl:if test="not(mods:role/mods:roleTerm[@authority='marcrelator' and @type='code'][.='aut' or .='edt' or .='trl'])">
        <xsl:value-of select="concat(' (', mods:affiliation, ')')"/>
      </xsl:if>
    </xsl:if>
      
    <!-- separator with the next contributor -->
    <xsl:choose>
      <xsl:when test="position() = last() -1">
        <xsl:choose>
          <xsl:when test="$displayLanguage='fre'">
            <xsl:text> et </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>, and </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:when>
    </xsl:choose>
      
  </xsl:for-each>
</xsl:template>


<!-- 
  Name of a contributor

  Context node: mods:name
  Target nodes: mods:namePart
  
  @param string $familyFirst    'true' if the family name must be displayed 
                                  before the surname
-->

<xsl:template name="contributor-name">
  <xsl:param name="familyFirst"/>
  
  <xsl:variable name="name">
    <xsl:choose>
      <xsl:when test="@type='personal'">
        <xsl:call-template name="personal_name">
          <xsl:with-param name="familyFirst" select="$familyFirst='true' and position()=1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@type='corporate'">
        <xsl:call-template name="corporate_name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="other_name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  <xsl:if test="$name!=''">
    <xsl:copy-of select="$name"/>
  </xsl:if>
</xsl:template>


<!-- 
  Name of a person

  Context node: mods:name
  Target nodes: mods:namePart
  
  @param string $familyFirst  'true' if the family name must be displayed before 
                                the surname
  
  TODO: handle termsOfAddress, displayForm
-->

<xsl:template name="personal_name">
  <xsl:param name="format" select="'xml'"/>
  <xsl:param name="familyFirst" select="'false'"/>

  <!-- given name -->
  <xsl:variable name="given">
    <xsl:call-template name="namePart">
      <xsl:with-param name="type" select="'given'"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- family name -->
  <xsl:variable name="family">
    <xsl:call-template name="namePart">
      <xsl:with-param name="type" select="'family'"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- other name part -->
  <xsl:variable name="other">
    <xsl:call-template name="namePart">
      <xsl:with-param name="excluding" select="'given family'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$family!='' or $given!='' or $other!=''">
      <xsl:choose>
        <xsl:when test="not($family) and not($given)">
          <xsl:copy-of select="$other"/>
        </xsl:when>
        <xsl:when test="not($given)">
          <xsl:copy-of select="$family"/>
        </xsl:when>
        <!-- DATA warning: no family name -->
        <xsl:when test="not($family)">
          <xsl:copy-of select="$given"/>
        </xsl:when>
        <xsl:when test="$familyFirst='true'">
          <xsl:copy-of select="$family"/>
          <xsl:text>, </xsl:text>
          <xsl:copy-of select="$given"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$given"/>
          <xsl:text> </xsl:text>
          <xsl:copy-of select="$family"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'no namePart in name'"/>
        <xsl:with-param name="var" select="mods:name"/>
        <xsl:with-param name="exp" select="'a least a namePart element must be present'"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Corporate name

  Context node: mods:name
  Target nodes: mods:namePart
-->

<xsl:template name="corporate_name">

  <!-- corporate name -->
  <xsl:variable name="corporate" select="normalize-space(mods:namePart)"/>

  <xsl:if test="$corporate!=''">
    <xsl:value-of select="$corporate"/>
  </xsl:if>
  
</xsl:template>


<!-- 
  Other name (i.e. non personal and non corporate)

  Context node: mods:name
  Target nodes: mods:namePart
-->

<xsl:template name="other_name">

  <!-- corporate name -->
  <xsl:variable name="other" select="normalize-space(mods:namePart)"/>

  <xsl:if test="$other!=''">
    <xsl:value-of select="$other"/>
  </xsl:if>
  
</xsl:template>


<!-- 
  Part of a name of a person or a corporate, of a given type, or excluding 
  types in an exclusion list

  Context node: mods:name
  Target nodes: mods:namePart
  
  @param string $type      filter on this type (e.g. 'family', 'given', ...)
  @param string $excluding list of types to reject (e.g. 'family given')
-->

<xsl:template name="namePart">
  <xsl:param name="type" select="''"/>
  <xsl:param name="excluding" select="''"/>

  <!-- is the actual type in the excluding list? -->
  <xsl:variable name="excluded">
    <xsl:call-template name="key-in-list">
      <xsl:with-param name="key" select="mods:namePart/@type"/>
      <xsl:with-param name="list" select="$excluding"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- name -->
  <xsl:variable name="name" select="normalize-space(mods:namePart[($type='' or @type=$type) and ($excluded='false')])"/>
  
  <xsl:if test="$name!=''">
    <span>
      <xsl:attribute name="class">
        <xsl:if test="mods:namePart[@type=$type]/@type">
          <xsl:value-of select="concat('mods-namepart-', mods:namePart[@type=$type]/@type)"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:value-of select="$name"/>
    </span>
  </xsl:if>
</xsl:template>



<!-- 
  ******************************************************************************

  Date functions
  
  
  ******************************************************************************
 -->

<!-- 
  Format a w3cdtf date or a w3cdtf date interval

  @param string $date1              date or start date
  @param string $date2              end date
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: format-datetime-interval('2009-04-09T12:30:00+02:00',
    '2009-04-09T12:30:00+02:00') => 'April 9, 2009, 12:30-14:00'

  TODO: handle other date encodings
-->

<xsl:template name="format-datetime-interval">
  <xsl:param name="date1"/>
  <xsl:param name="date2" select="''"/>
  <xsl:param name="displayLanguage"/>
  
  <!-- start date -->
  
  <xsl:variable name="year1">
    <xsl:call-template name="get-year-part">
      <xsl:with-param name="date" select="$date1"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="month1">
    <xsl:if test="string-length($year1)">
      <xsl:call-template name="get-month-part">
        <xsl:with-param name="date" select="$date1"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="day1">
    <xsl:if test="string-length($month1)">
      <xsl:call-template name="get-day-part">
        <xsl:with-param name="date" select="$date1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="time1">
    <xsl:if test="string-length($day1)">
      <xsl:call-template name="get-time-part">
        <xsl:with-param name="date" select="$date1"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <!-- end date -->
  
  <xsl:variable name="year2">
    <xsl:if test="$date2!=''">
      <xsl:call-template name="get-year-part">
        <xsl:with-param name="date" select="$date2"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="month2">
    <xsl:if test="string-length($year2)">
      <xsl:call-template name="get-month-part">
        <xsl:with-param name="date" select="$date2"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="day2">
    <xsl:if test="string-length($month2)">
      <xsl:call-template name="get-day-part">
        <xsl:with-param name="date" select="$date2"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="time2">
    <xsl:if test="string-length($day2)">
      <xsl:call-template name="get-time-part">
        <xsl:with-param name="date" select="$date2"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <!-- output -->
  
  <xsl:choose>
    <!-- single date -->
    <xsl:when test="string-length($date2)=0">
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year1"/>
        <xsl:with-param name="month" select="$month1"/>
        <xsl:with-param name="day" select="$day1"/>
        <xsl:with-param name="time" select="$time1"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>

    <!-- time interval (e.g., "March 2, 2014, 12:30-14:00")-->
    <xsl:when test="$year1 = $year2 and $month1 = $month2 and $day1 = $day2 and $time1 != $time2">
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year1"/>
        <xsl:with-param name="month" select="$month1"/>
        <xsl:with-param name="day" select="$day1"/>
        <xsl:with-param name="time" select="concat($time1, '&#8211;', $time2)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>
    
    <!-- day interval, same month (e.g., "March 2-3, 2014") -->
    <xsl:when test="$year1 = $year2 and $month1 = $month2 and $day1 != $day2 and string-length(concat($time1,$time2))=0">
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year1"/>
        <xsl:with-param name="month" select="$month1"/>
        <xsl:with-param name="day" select="concat($day1, '&#8211;', $day2)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>
    
    <!-- month interval (e.g., "March-April, 2014") -->
    <xsl:when test="$year1 = $year2 and $month1 != $month2 and string-length(concat($day1,$day2,$time1,$time2))=0">
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year1"/>
        <xsl:with-param name="month" select="concat($month1, '&#8211;', $month2)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>
    
    <!-- year interval (e.g., "2014-2015") -->
    <xsl:when test="$year1 != $year2 and string-length(concat($month1,$month2,$day1,$day2,$time1,$time2))=0">
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="concat($year1, '&#8211;', $year2)"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:when>
    
    <!-- "start 'to' end" forms -->
    <xsl:otherwise>
    
      <!-- suppress the first year when possible -->
      <xsl:variable name="year1s">
        <xsl:choose>
          <xsl:when test="$year1 = $year2">
          </xsl:when> 
          <xsl:otherwise>
            <xsl:value-of select="$year1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      
      <!-- prefix: "du" or "de" (in French only) -->
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:choose>
            <xsl:when test="string-length($day1)">
              <xsl:text>du </xsl:text>
            </xsl:when> 
            <xsl:otherwise>
              <xsl:text>de </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- start date -->
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year1s"/>
        <xsl:with-param name="month" select="$month1"/>
        <xsl:with-param name="day" select="$day1"/>
        <xsl:with-param name="time" select="$time1"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
      
      <!-- separator: "au" or "à" (in French), "to" (in English) -->
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:choose>
            <xsl:when test="string-length($day2)">
              <xsl:text> au </xsl:text>
            </xsl:when> 
            <xsl:otherwise>
              <xsl:text> à </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <!-- en English: insert a comma in cases like "March 22, 2014, to April 1, 2014" -->
          <xsl:if test="string-length($year1s) and string-length($month1) and string-length($day1)">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:text> to </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- end date -->
      <xsl:call-template name="format-datetime">
        <xsl:with-param name="year" select="$year2"/>
        <xsl:with-param name="month" select="$month2"/>
        <xsl:with-param name="day" select="$day2"/>
        <xsl:with-param name="time" select="$time2"/>
        <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- 
  Format a w3cdtf date 

  @param string $year               year part (e.g., '2009')
  @param string $month              month part (e.g., 'April' or 'May-June')
  @param string $day                day part (e.g., '3' or '3-5)
  @param string $time               time part (e.g., '12:30' or '12:30-14:00')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: format-datetime('2009-04-09T12:30:00+02:00') 
    => 'April 9, 2009, 12:30'
-->

<xsl:template name="format-datetime">
  <xsl:param name="year" select="''"/>
  <xsl:param name="month" select="''"/>
  <xsl:param name="day" select="''"/>
  <xsl:param name="time" select="''"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:choose>
    <!-- 
      Case 1: year, month, day, w/ or w/o a time
    
      French  : "22 mars 2014" or "22 mars 2014, 14h30" 
      English : "March 22, 2014" or "March 22, 2014, 14:30" 
    -->
    <xsl:when test="string-length($year) and string-length($month) and string-length($day)">

      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:value-of select="concat($day, ' ', $month, ' ', $year)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($month, ' ', $day, ', ', $year)"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="string-length($time)">
        <xsl:value-of select="concat(', ', $time)"/>
      </xsl:if>
    </xsl:when>
    
    <!-- 
      Case 2: year, month
    
      French  : "mars 2014"
      English : "March 2014"
    -->
    <xsl:when test="string-length($year) and string-length($month)">
      <xsl:value-of select="concat($month, ' ', $year)"/>
    </xsl:when>
    
    <!-- 
      Case 3: year
    
      French  : "2014"
      English : "2014"
    -->
    <xsl:when test="string-length($year)">
      <xsl:value-of select="$year"/>
    </xsl:when>
    
    <!-- 
      Case 4: month, day, w/ or w/o a time
    
      French  : "22 mars" or "22 mars, 14h30" 
      English : "March 22" or "March 22, 14:30" 
    -->
    <xsl:when test="string-length($month) and string-length($day)">
      <xsl:choose>
        <xsl:when test="$displayLanguage='fre'">
          <xsl:value-of select="concat($day, ' ', $month)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($month, ' ', $day)"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="string-length($time)">
        <xsl:value-of select="concat(', ', $time)"/>
      </xsl:if>
    </xsl:when>
    
    <!-- 
      Case 4: month
    
      French  : "mars" 
      English : "March" 
    -->
    <xsl:when test="string-length($month)">
      <xsl:value-of select="$month"/>
    </xsl:when>
    
    <!-- 
      Case 5: time
    
      French  : "14h30" 
      English : "14:30" 
    -->
    <xsl:when test="string-length($time)">
      <xsl:value-of select="$time"/>
    </xsl:when>
    
    <!-- invalid date -->
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'cannot parse the date'"/>
        <xsl:with-param name="var" select="concat('year: ', $year, ', month: ', $month, ', day: ', $day, ', time: ', $time)"/>
        <xsl:with-param name="exp" select="'the format of the date must be w3cdtf'"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose> 
</xsl:template>


<!-- 
  Return the year part of a w3cdtf date, or an empty string if 
  the year part is invalid 

  @param string $date w3cdtf date (e.g. '2009-04-18T12:30:00+02:00')

  Example: get-year-part('2009-04-09T12:30:00+02:00') => '2009'
-->

<xsl:template name="get-year-part">
  <xsl:param name="date"/>
  
  <xsl:variable name="yyyy" select="substring($date, 1, 4)"/>
  
  <xsl:choose>
    <xsl:when test="string-length($yyyy)=4">
      <xsl:variable name="ok">
        <xsl:call-template name="all-digits">
          <xsl:with-param name="string" select="$yyyy"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$ok='true'">
          <xsl:value-of select="$yyyy"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="debug">
            <xsl:with-param name="msg" select="'invalid year value'"/>
            <xsl:with-param name="var" select="concat($yyyy, ' in the date ', $date)"/>
            <xsl:with-param name="exp" select="'a year must only contain digits'"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="'invalid year part'"/>
        <xsl:with-param name="var" select="concat($yyyy, ' in the date ', $date)"/>
        <xsl:with-param name="exp" select="'a year must be of length 4'"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Return the month part of a w3cdtf date (in text format), or an 
  empty string if the month part is missing or invalid 

  @param string $date               w3cdtf date 
                                      (e.g. '2009-04-18T12:30:00+02:00')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: get-month-part('2009-04-09T12:30:00+02:00') => 'April'
-->

<xsl:template name="get-month-part">
  <xsl:param name="date"/>
  <xsl:param name="displayLanguage"/>
  
  <xsl:if test="substring($date, 5, 1)='-'">
  
    <xsl:variable name="mm" select="substring($date, 6, 2)"/>
    
    <xsl:choose>
      <xsl:when test="string-length($mm)=2">
        <xsl:variable name="ok">
          <xsl:call-template name="all-digits">
            <xsl:with-param name="string" select="$mm"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$ok='true'">
            <xsl:choose>
              <xsl:when test="number($mm) &gt;= 1 and number($mm) &lt;= 12">
                <xsl:call-template name="format-month">
                  <xsl:with-param name="mm" select="$mm"/>
                  <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="debug">
                  <xsl:with-param name="msg" select="'out of range month number'"/>
                  <xsl:with-param name="var" select="concat($mm, ' in the date ', $date)"/>
                  <xsl:with-param name="exp" select="'a month must be in the range 1-12'"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="debug">
              <xsl:with-param name="msg" select="'invalid month value'"/>
              <xsl:with-param name="var" select="concat($mm, ' in the date ', $date)"/>
              <xsl:with-param name="exp" select="'mm must only contain digits'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="debug">
          <xsl:with-param name="msg" select="'invalid month part'"/>
          <xsl:with-param name="var" select="concat($mm, ' in the date ', $date)"/>
          <xsl:with-param name="exp" select="'a month number must be of length 2'"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>


<!-- 
  Return the day part of a w3cdtf date (dropping leading zero), or an 
  empty string if the day part is missing or invalid 

  @param string $date w3cdtf date (e.g. '2009-05-09T12:30:00+02:00')

  Example: get-day-part('2009-05-09T12:30:00+02:00') => '9'
-->

<xsl:template name="get-day-part">
  <xsl:param name="date"/>

  <xsl:if test="substring($date, 8, 1)='-'">
    
    <xsl:variable name="dd" select="substring($date, 9, 2)"/>
    
    <xsl:choose>
      <xsl:when test="string-length($dd)=2">
        <xsl:variable name="ok">
          <xsl:call-template name="all-digits">
            <xsl:with-param name="string" select="$dd"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$ok='true'">
            <xsl:choose>
              <xsl:when test="number($dd) &gt;= 1 and number($dd) &lt;= 31">
                <xsl:value-of select="string(number($dd))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="debug">
                  <xsl:with-param name="msg" select="'out of range day number'"/>
                  <xsl:with-param name="var" select="concat($dd, ' in the date ', $date)"/>
                  <xsl:with-param name="exp" select="'a day must be in the range 1-31'"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="debug">
              <xsl:with-param name="msg" select="'invalid day value'"/>
              <xsl:with-param name="var" select="concat($dd, ' in the date ', $date)"/>
              <xsl:with-param name="exp" select="'dd must only contain digits'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="debug">
          <xsl:with-param name="msg" select="'invalid day part'"/>
          <xsl:with-param name="var" select="concat($dd, ' in the date ', $date)"/>
          <xsl:with-param name="exp" select="'a day number must be of length 2'"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>   
</xsl:template>

<!-- 
  Return the time part of a w3cdtf date, or an empty string if the
  time part is missing or invalid 

  @param string $date               w3cdtf date 
                                      (e.g. '2009-05-18T12:30:00+02:00')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: get-time-part('2009-05-18T12:30:00+02:00') => '12:30'

  TODO: seconds; time zone
-->

<xsl:template name="get-time-part">
  <xsl:param name="date"/>
  <xsl:param name="displayLanguage"/>

  <xsl:if test="substring($date, 11, 1)='T' and substring($date, 14, 1)=':'">
    
    <xsl:variable name="hh" select="substring($date, 12, 2)"/>
    <xsl:variable name="mm" select="substring($date, 15, 2)"/>
    
    <xsl:choose>
      <xsl:when test="string-length($hh)=2 and string-length($mm)=2">
        <xsl:variable name="ok">
          <xsl:call-template name="all-digits">
            <xsl:with-param name="string" select="concat($hh, $mm)"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$ok='true'">
            <xsl:choose>
            <xsl:when test="number(concat($hh, $mm)) &lt;= 2359 and number($mm) &lt;= 59">
              <xsl:call-template name="format-time">
                <xsl:with-param name="time" select="concat($hh, ':', $mm)"/>
                <xsl:with-param name="displayLanguage" select="$displayLanguage"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="debug">
                <xsl:with-param name="msg" select="'out of range hh:mm time value'"/>
                <xsl:with-param name="var" select="concat($hh, ':', $mm, ' in the date ', $date)"/>
                <xsl:with-param name="exp" select="'a time value must be in the range 00:00-23:59'"/>
              </xsl:call-template>
            </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="debug">
              <xsl:with-param name="msg" select="'invalid hh:mm time value'"/>
              <xsl:with-param name="var" select="concat($hh, ':', $mm, ' in the date ', $date)"/>
              <xsl:with-param name="exp" select="'hh and mm must only contain digits'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="debug">
          <xsl:with-param name="msg" select="'invalid hh:mm time value'"/>
          <xsl:with-param name="var" select="concat($hh, ':', $mm, ' in the date ', $date)"/>
          <xsl:with-param name="exp" select="'hh and mm must be of length 2'"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>


<!-- 
  Return the month name corresponding to a 01-12 month number, or an 
  empty string if it is not a valid month number

  @param string $mm                 month number (e.g. '04')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: format-month('04') => 'April'
-->

<xsl:template name="format-month">
  <xsl:param name="mm"/>
  <xsl:param name="displayLanguage"/>
  <xsl:choose>
    <xsl:when test="$displayLanguage='fre'">
      <xsl:choose>
        <xsl:when test="$mm='01'">janvier</xsl:when>
        <xsl:when test="$mm='02'">février</xsl:when>
        <xsl:when test="$mm='03'">mars</xsl:when>
        <xsl:when test="$mm='04'">avril</xsl:when>
        <xsl:when test="$mm='05'">mai</xsl:when>
        <xsl:when test="$mm='06'">juin</xsl:when>
        <xsl:when test="$mm='07'">juillet</xsl:when>
        <xsl:when test="$mm='08'">août</xsl:when>
        <xsl:when test="$mm='09'">septembre</xsl:when>
        <xsl:when test="$mm='10'">octobre</xsl:when>
        <xsl:when test="$mm='11'">novembre</xsl:when>
        <xsl:when test="$mm='12'">décembre</xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="debug">
            <xsl:with-param name="msg" select="'out of range month number'"/>
            <xsl:with-param name="var" select="$mm"/>
            <xsl:with-param name="exp" select="'a two-digit code in the range 01-12'"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$mm='01'">January</xsl:when>
        <xsl:when test="$mm='02'">February</xsl:when>
        <xsl:when test="$mm='03'">March</xsl:when>
        <xsl:when test="$mm='04'">April</xsl:when>
        <xsl:when test="$mm='05'">May</xsl:when>
        <xsl:when test="$mm='06'">June</xsl:when>
        <xsl:when test="$mm='07'">July</xsl:when>
        <xsl:when test="$mm='08'">August</xsl:when>
        <xsl:when test="$mm='09'">September</xsl:when>
        <xsl:when test="$mm='10'">October</xsl:when>
        <xsl:when test="$mm='11'">November</xsl:when>
        <xsl:when test="$mm='12'">December</xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="debug">
            <xsl:with-param name="msg" select="'out of range month number'"/>
            <xsl:with-param name="var" select="$mm"/>
            <xsl:with-param name="exp" select="'a two-digit code in the range 01-12'"/>
          </xsl:call-template>
        </xsl:otherwise>    
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Format a hh:mm time value

  @param string $time               string containing a time value 
                                      (e.g. '12:30')
  @param string $displayLanguage    display language (e.g. 'fre' or 'eng')

  Example: format-time('12:30') => '12h30' (when the display language is 'fre')

  TODO: handle full hh:mm:ss+timezone value
-->

<xsl:template name="format-time">
  <xsl:param name="time"/>
  <xsl:param name="displayLanguage"/>
  <xsl:choose>
    <xsl:when test="$displayLanguage='fre'">
      <xsl:value-of select="concat(substring($time,1,2), 'h', substring($time,4))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$time"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  ******************************************************************************

  Checking and debugging functions

  NOTE: use $gDebug

  ******************************************************************************
 -->


<!-- 
  Check that a parameter is in a list of allowed values
  
  @param string $name     name of the parameter (e.g. 'version')
  @param string $value    value of the parameter (e.g. '0.1')
  @param string $multiple multiple (blank separated) values allowed?
  @param string $list     blank separated list of allowed values
-->

<xsl:template name="check-parameter-in">
  <xsl:param name="name"/>
  <xsl:param name="value"/>
  <xsl:param name="multiple" select="'false'"/>
  <xsl:param name="list"/>
  
  <xsl:choose>
    <xsl:when test="$multiple='false' and contains(normalize-space($value), ' ')">
      <xsl:call-template name="debug">
        <xsl:with-param name="msg" select="concat('no blank space allowed in parameter ', $APOS, $name, $APOS)"/>
        <xsl:with-param name="var" select="$value"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="ok">
        <xsl:call-template name="keys-in-list">
          <xsl:with-param name="keys" select="$value"/>
          <xsl:with-param name="list" select="$list"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="$ok='false'">
        <xsl:call-template name="debug">
          <xsl:with-param name="msg" select="concat('incorrect value for parameter ', $APOS, $name, $APOS)"/>
          <xsl:with-param name="var" select="$value"/>
          <xsl:with-param name="exp" select="concat('values in [', translate($list , ' ', ','), ']')"/>
        </xsl:call-template>      
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Print a debug message when in debug mode
  
  @param string $msg debug message
  @param string $var faulty element
  @param string $exp message about what was expected instead
-->

<xsl:template name="debug">
  <xsl:param name="msg"/>
  <xsl:param name="var"/>
  <xsl:param name="exp" select="''"/>

  <xsl:if test="$gDebug!='no'">

    <!-- get the item's id if any -->
    <xsl:variable name="id" select="ancestor::mods:mods/mods:identifier[@type='local']"/>
  
    <!-- build the debug message -->
    <xsl:variable name="message">
      <xsl:value-of select="'(WARNING: '"/>
      <xsl:value-of select="$msg"/>
      <xsl:if test="$id!=''">
        <xsl:value-of select="concat('; id: ', $APOS, $id, $APOS)"/>
      </xsl:if>
      <xsl:value-of select="concat('; value: ', $APOS, $var, $APOS)"/>
      <xsl:if test="$exp!=''">
        <xsl:value-of select="concat('; expected: ', $exp)"/>
      </xsl:if>
      <xsl:value-of select="')'"/>
    </xsl:variable>
    
    <xsl:choose>
    
      <!-- inplace: insert the message in the output stream -->
      <xsl:when test="$gDebug='inplace'">
        <xsl:value-of select="$message"/>
      </xsl:when>
      
      <!-- 
        default: emit a warning
        
        We do not test that $gDebug='warning' in order to be able to display 
        a warning when the value of the debug parameter itself is incorrect.
       -->
      <xsl:otherwise>
        <xsl:message>
          <xsl:value-of select="$message"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>



<!-- 
  ******************************************************************************

  String functions

  NOTE: these functions do not depend on any $g* global variable

  ******************************************************************************
 -->

<!-- 
  Return 'true' if a string contains only digits, and 'false' otherwise
  
  @param string $string string to test for

  Example: all-digits('1230') => 'true'
-->

<xsl:template name="all-digits">
  <xsl:param name="string"/>

  <xsl:value-of select="string-length(translate($string, '0123456789', '')) = 0"/>  
</xsl:template>


<!-- 
  Return 'true' if a each key in a blank-separated list of keys is in a 
    blank-separated list of keys
  
  A key is assumed to contain no spaces (after trimming)
  
  @param string $keys   keys to look for
  @param string $list   list to search in

  Example: keys-in-list('def', 'abc def ghi') => 'true'
  Example: keys-in-list('xyz def', 'abc def ghi') => 'false'
  Example: keys-in-list('xyz def', 'abc def ghi xyz') => 'true'
  Example: keys-in-list('', 'abc def ghi') => 'false'
  Example: keys-in-list('', '') => 'false'
-->

<xsl:template name="keys-in-list">
  <xsl:param name="keys"/>
  <xsl:param name="list"/>

  <!-- trim keys and list -->   
  <xsl:variable name="nkeys" select="normalize-space($keys)"/>
  <xsl:variable name="nlist" select="normalize-space($list)"/>

  <!-- key head and queue -->   
  <xsl:variable name="key" select="substring-before(concat($nkeys, ' '), ' ')"/>
  <xsl:variable name="qkeys" select="substring-after($nkeys, ' ')"/>

  <xsl:choose>
    <!-- cases where 'false' is always returned -->
    <xsl:when test="string-length($nkeys)=0 or string-length($nlist)=0">
      <xsl:value-of select="'false'"/>
    </xsl:when>
    <xsl:otherwise>
      <!-- head in list? -->
      <xsl:variable name="hok">
        <xsl:call-template name="key-in-list">
          <xsl:with-param name="key" select="$key"/>
          <xsl:with-param name="list" select="$list"/>
        </xsl:call-template>
      </xsl:variable>
      <!-- queue in list? -->
      <xsl:variable name="qok">
        <xsl:call-template name="keys-in-list">
          <xsl:with-param name="keys" select="$qkeys"/>
          <xsl:with-param name="list" select="$list"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:value-of select="$hok='true' and (string-length(normalize-space($qkeys))=0 or $qok='true')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Return 'true' if a key is in a blank-separated list of keys
  
  A key is assumed to contain no spaces (after trimming)
  
  @param string $key    string to look for
  @param string $list   list to search in

  Example: key-in-list('def', 'abc def ghi') => 'true'
  Example: key-in-list('xyz', 'abc def ghi') => 'false'
  Example: key-in-list('', 'abc def ghi') => 'false'
  Example: key-in-list('', '') => 'false'
-->

<xsl:template name="key-in-list">
  <xsl:param name="key"/>
  <xsl:param name="list"/>

  <xsl:value-of select="$list!='' and contains(concat(' ', normalize-space($list), ' '), concat(' ', normalize-space($key), ' '))"/>  
</xsl:template>


<!-- 
  Return the part of $haystack after the last occurrence of $needle
  
  @param string $haystack   string to search in
  @param string $needle     string o search for
  
  Example: substring-after-last('/ab/cd/ef', '/') => 'ef'
-->

 <xsl:template name="substring-after-last">
  <xsl:param name="haystack"/>
  <xsl:param name="needle"/>

  <xsl:variable name="substring" select="substring-after($haystack, $needle)"/>
  <xsl:choose>
    <xsl:when test="contains($substring, $needle)">
       <xsl:call-template name="substring-after-last">
        <xsl:with-param name="haystack" select="$substring"/>
        <xsl:with-param name="needle" select="$needle"/>
       </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$substring"/>
    </xsl:otherwise>    
  </xsl:choose>
 </xsl:template>


<!-- 
  Return the singular or plural form of words into a string, using embedded 
    "{sing,plur}" or "{plur}" patterns
  
  @param string  $string  string to process, containing {sing,plur} or {plur} 
                            patterns
  @param integer $count   number meaning plural when greater than 1
  
  Example: singular-or-plural('f{oo,ee}t', 2) => 'feet'
  Example: singular-or-plural('{a ,}cat{s}', 1) => 'a cat'
  
  Note-to-self: substring-after() returns an empty string when the string does 
    not contain the needle
-->

<xsl:template name="singular-or-plural">
  <xsl:param name="string"/>
  <xsl:param name="count"/>

  <!-- search for a "{sing,plur}" or "{plur}" patterns, decomposing the string 
    into three pieces: "$ss { $st } $se" -->
  
  <xsl:variable name="sb" select="substring-before($string, '}')"/>
  <xsl:variable name="ss" select="substring-before($sb, '{')"/>
  <xsl:variable name="st" select="substring-after($sb, '{')"/>
  <xsl:variable name="se" select="substring-after($string, '}')"/>
    
  <xsl:choose>

    <!-- no pattern detected -->
    <xsl:when test="string-length($sb)=0 or not(starts-with($string,'{')) and string-length($ss)=0">
      <xsl:value-of select="$string"/>
    </xsl:when>

    <!-- pattern is "$ss { $st } $se" -->
    <xsl:otherwise>
    
      <!-- search for a comma -->
      <xsl:variable name="c1" select="substring-before($st, ',')"/>
      <xsl:variable name="c2" select="substring-after($st, ',')"/>

      <!--  select the right form, depending on $count -->    
      <xsl:variable name="st_res">
        <xsl:choose>
          <!-- no comma: plural -->
          <xsl:when test="not(contains($st, ',')) and ($count &gt; 1)">
            <xsl:value-of select="$st"/>
          </xsl:when>
          <!-- plural -->
          <xsl:when test="$count &gt; 1">
            <xsl:value-of select="$c2"/>
          </xsl:when>
          <!-- singular -->
          <xsl:otherwise>
            <xsl:value-of select="$c1"/>
          </xsl:otherwise>    
        </xsl:choose>
      </xsl:variable>
      
      <!-- recursive call to process the string end -->
      <xsl:variable name="se_res">
        <xsl:call-template name="singular-or-plural">
          <xsl:with-param name="string" select="$se"/>
          <xsl:with-param name="count" select="$count"/>
        </xsl:call-template>
      </xsl:variable>

      <!--  final result -->
      <xsl:value-of select="concat($ss, $st_res, $se_res)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<!-- 
  Replace by $replace all occurrence of $search into $string
  
  @param string $search   string to replace
  @param string $replace  replacement string
  @param string $string   string to process
  
  Example: string-replace-all('abc', 'x', 'abcoabco') => 'xoxo' 
-->

<xsl:template name="string-replace-all">
  <xsl:param name="search"/>
  <xsl:param name="replace"/>
  <xsl:param name="string"/>
  
  <xsl:choose>

    <xsl:when test="not(contains($string, $search))">
      <xsl:value-of select="$string"/>
    </xsl:when>

    <xsl:otherwise>

      <xsl:variable name="sb" select="substring-before($string, $search)"/>
      <xsl:variable name="se" select="substring-after($string, $search)"/>
      
      <!-- recursive call to process the string end -->
      <xsl:variable name="se_res">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="search" select="$search"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="string" select="$se"/>
        </xsl:call-template>
      </xsl:variable>

      <!--  final result -->
      <xsl:value-of select="concat($sb, $replace, $se_res)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Replace by $replace the first occurrence of $search into $string
  
  @param string $search   string to replace
  @param string $replace  replacement string
  @param string $string   string to process
  
  Example: string-replace('abc', 'x', 'abcoabco') => 'xoabco' 
-->

<xsl:template name="string-replace">
  <xsl:param name="search"/>
  <xsl:param name="replace"/>
  <xsl:param name="string"/>
  
  <xsl:choose>
    <xsl:when test="not(contains($string, $search))">
      <xsl:value-of select="$string"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat(substring-before($string, $search), $replace, substring-after($string, $search))"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- 
  Insert a separator
-->

<xsl:template name="separator">
  <xsl:value-of select="', '"/>
</xsl:template>

 
<!-- 
  Insert a non-breaking space
-->

<xsl:template name="nbsp">
  <xsl:text>&#160;</xsl:text>
</xsl:template>

</xsl:stylesheet>
