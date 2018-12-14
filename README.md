# mods-to-html

An XSLT 1.0 stylesheet to transform a MODS document into an HTML chunk. 

Highlights:

* Thanks to XSLT 1.0, most XSLT processors may be used to apply this stylesheet.
* The HTML chunk is made of several `div` and `span` elements, each having a specific class. This facilitates CSS formatting, or XML editing using a programming language.
* The output is made of sections (e.g., `reference`, `abstract`, `keywords`). One or more sections can be requested.
* When the reference is meant to be part of the CV of one particular contributor, the name of this contributor is omitted, and the others are cited in a "with" statement.

TODO:

- [ ] Add documentation about the particular MODS profile this stylesheet accepts
- [ ] Implement citation styles (e.g., Chicago)
- [ ] Add a demo CSS file


## Installation

To install the stylesheet, clone the repository, and download the last version of the JEL classification XML document from the AEA web site:  

```bash
$ git clone "https://github.com/cbisiere/mods-to-html.git"
$ cd mods-to-html
$ wget "http://www.aeaweb.org/econlit/classificationTree.xml"
```

To test the stylesheet, use a XSLT processor (e.g., `xsltproc`) to transform a sample MODS document:

```bash
$ xsltproc modstohtml.xsl samples/article.xml
```

This should output an HTML chunk:

```xml
<?xml version="1.0" encoding="utf-8"?>
<div class="mods-root">
  <div class="mods-item mods-lang-eng">
    <h1 class="mods-section-head mods-reference">Reference</h1>
    <div class="mods-section-body mods-reference">
    ...

  </div>
</div>
```

## Parameters

The stylesheet accepts the following parameters:

parameter        | values       | default | description
-----------------|--------------|---------|-----------------------------------------------
`version`          | `1`                | `1`     | API version of the stylesheet.
`sections`         | The wilcard `*`, or a space-separated list of section names, in: `reference`, `other-contributors`, `urls`, `abstract`, `keywords`, `jelcodes`, `related`, `fragments`. Each section name may be postfixed with `-body`. | `*`     | List of sections to output. Postfixing a section with `-body` suppresses its heading. The wildcard `*` replaces all the sections but `fragments`. Section `fragments` does nothing, but allows to extend the stylesheet.
`displayLanguage`  | A space-separated list of 3-letter [iso639-2b language codes](https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes), in:`eng`, `fre`| `eng`   | Output languages. The HTML chunk will have an element `<div class="mods-item mods-lang-$lang">` for each language `$lang` in the list.
`headingLevel`     | `1` to `6` | `1`       | Heading level of the output sections.
`vitaeOf`          | A URI        | none  | ValueURI of the contributor this request is for. When such URI is given, only co-contributors will be cited, after a `with`tag.
`debug`            |  `no`, `warning`, `inplace` | `no` | How error messages are reported to the user. `warning`: output the message using `<xsl:message/>`; `inplace`: insert the message in the html chunk itself.


## Usage

### Using a XSLT processor

To get the reference, without headings:

```bash
$ xsltproc --stringparam sections "reference-body" \
    modstohtml.xsl samples/article.xml
```

gives:

```
Bruno Biais, Christophe Bisière, and Chester Spatt, “Imperfect Competition in Financial Markets: 
An Empirical Study of Island and Nasdaq”, Management Science, vol. 56, n. 12, December 2010, 
pp. 2237–2250.
```

To get the reference in French, as part of the CV of the second coauthor:

```bash
$ xsltproc --stringparam sections "reference-body" \
    --stringparam displayLanguage "fre" \
    --stringparam vitaeOf "http://tse-fr.eu/aut/28" \
    modstohtml.xsl samples/article.xml
```

```
« Imperfect Competition in Financial Markets: An Empirical Study of Island and Nasdaq », 
Management Science, vol. 56, n° 12, décembre 2010, p. 2237–2250.
(avec Bruno Biais et Chester Spatt)
```

A more complete example, with four sections:

```bash
$ xsltproc --stringparam sections "reference abstract keywords jelcodes" \
    modstohtml.xsl samples/article.xml
```

```
Reference

Bruno Biais, Christophe Bisière, and Chester Spatt, “Imperfect Competition in Financial Markets: 
An Empirical Study of Island and Nasdaq”, Management Science, vol. 56, n. 12, December 2010, 
pp. 2237–2250.

Abstract

The competition between Island and Nasdaq at the beginning of the century offers a natural 
laboratory to study competition between and within trading platforms and its consequences 
for liquidity supply. Our empirical strategy takes advantage of the difference between the 
pricing grids used on Island and Nasdaq, as well as of the decline in the Nasdaq tick. Using 
the finer grid prevailing on their market, Island limit order traders undercut Nasdaq quotes, 
much more than they undercut one another. The drop in the Nasdaq tick size triggered a drop 
in Island spreads, despite the Island tick already being very thin before Nasdaq decimalization. 
We also estimate a structural model of liquidity supply and find that Island limit order traders 
earned rents before Nasdaq decimalization. Our results suggest that perfect competition cannot 
be taken for granted, even on transparent open limit order books with a very thin pricing grid.

Keywords

competition in financial markets
liquidity supply
trading mechanisms
different tick sizes

JEL codes

G1: General Financial Markets
G14: Information and Market Efficiency • Event Studies • Insider Trading
```

### Using php

TBD

## Output

The transformation creates a single `div` root element, whose structure is detailed below.

### Top elements

The root `div` is structured as follows:


```xml
<div class="mods-root">
  <div class="mods-item mods-lang-{$lang}">                           
    <h{$h} class="mods-section-head mods-{$section}">{$section-title}</h{$h}>
    <div class="mods-section-body mods-{$section}">           
      <div class="mods-one-{$element-name}">
        {$element}
      ...
    ...
  ...
```

where

* `{$lang}`is one of the languages (e.g. `fre`) specified in parameter `displayLanguage`
* `{$h}` is the heading level (e.g. `1`) specified in parameter `headingLevel`
* `{$section}` is one of the sections (e.g. `keywords`) specified in parameter `sections` (except for `related` which covers several actual sections, see below)
* `{$section-title}` is the title of the section (e.g. "Mots-clés")
* `{$element-name}` is name of the element exposed into this section (e.g. "keyword")
* `{$element}` is an element-specific node

Some sections will contain a single element. For instance, section `mods-reference` contains only one `<div class="mods-one-reference">`. Others, like `mods-keywords`, may have many.

### Section "reference"

```xml
<div class="mods-one-reference">
  <span class="mods-contributors-primary">
    <a class="mods-link-name mods-role-aut" href="http://tse-fr.eu/aut/27">
      <span>
        <span class="mods-namepart-given">Bruno</span>
        <span class="mods-namepart-family">Biais</span>
      </span>
    </a>, 
    <a class="mods-link-name mods-role-aut" href="http://tse-fr.eu/aut/28">
      <span>
        <span class="mods-namepart-given">Christophe</span> 
        <span class="mods-namepart-family">Bisière</span>
      </span>
    </a>, and 
    <a class="mods-link-name mods-role-aut" href="http://tse-fr.eu/aut/130">
      <span>
        <span class="mods-namepart-given">Chester</span> 
        <span class="mods-namepart-family">Spatt</span>
      </span>
    </a>
  </span>, 
  <span xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" class="mods-quoted-title">“
    <a class="mods-link-item" href="http://tse-fr.eu/pub/22759">
      <span>
        <span class="mods-title">Imperfect Competition in Financial Markets</span>: 
        <span class="mods-subtitle">An Empirical Study of Island and Nasdaq</span>
      </span>
    </a>”
  </span>, 
  <span xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" class="mods-unquoted-title">
    <a class="mods-link-item" href="http://tse-fr.eu/pub/396">
      <span>
        <span class="mods-title">Management Science</span>
      </span>
    </a>
  </span>, 
  <span xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" class="mods-detail-volume">vol. 56</span>, 
  <span xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" class="mods-detail-issue">n. 12</span>, 
  <span class="mods-date-issued">December 2010</span>, 
  <span class="mods-pages">pp. 2237–2250</span>.
</div>
```

### Section "other-contributors"

This section gathers all the contributors whose name does not appear in the reference section.

```xml
<div>Organized by 
  <a class="mods-link-name mods-role-orm" href="http://tse-fr.eu/aut/27">
    <span>
      <span class="mods-namepart-given">Bruno</span> 
      <span class="mods-namepart-family">Biais</span>
    </span>
  </a> (TSE), and 
  <a class="mods-link-name mods-role-orm" href="http://tse-fr.eu/aut/1522">
    <span>
      <span class="mods-namepart-given">Sophie</span> 
      <span class="mods-namepart-family">Moinas</span>
    </span></a> (TSE).
  </div>
</div>
```
    
    
### Section "urls"

One `div` per link.

```xml
<div class="mods-one-url">
  <a class="mods-link-url mods-url-primary-display mods-url-object-in-context" 
    href="http://tse-fr.eu/pub/22759">
    http://tse-fr.eu/pub/22759
  </a>
</div>
```


### Section "abstracts"

One `div` per abstract. If only one abstract is available in the MODS document, it will appear in the section, whatever the language.

```xml
<div class="mods-one-abstract">
  The competition between Island and Nasdaq at the beginning of the 
  century offers a natural laboratory to study competition between 
  ...
</div>
```

### Section "keywords"

One `div` per keyword.

```xml
<div class="mods-one-keyword">competition in financial markets</div>
```

### Section "jelcodes"

One `div` per JEL code. The JEL description part comes from the file [classificationTree.xml](https://www.aeaweb.org/econlit/classificationTree.xml) downloaded during installation.


```xml
<div class="mods-one-jelcode">
  <span class="mods-jel-code">G1</span>: 
  <span class="mods-jel-description">General Financial Markets</span>
</div>
```

### Sections "related"

Section `related` actually requests several sections, one for each possible type of relation. 

In a MODS document, each relation specifies a type (e.g., `preceding`). Moreover, each type may correspond to different semantics. For instance, when the MODS document is a written document, `preceding` means that it replaces another document, like a published article replacing a working paper version. When the current MODS document describes en event, `preceding` means that this event comes after another one in a series of events, like a conference succeeding another one in a series of conferences. In the HTML output, the heading should be different: it will be "Replaces" in the former case, and "Preceding event" in the latter.

For a given type of relation `{$type}` and a heading `{$heading}`, the section will have the following structure:


```xml
<h1 class="mods-section-head mods-related-{$type}">{$heading}</h1>
<div class="mods-section-body mods-related-{$type}">
  <div class="mods-one-related">
    ...
  </div>
</div>
```  

For instance, for an article replacing a working paper, the chunk will be: 

```xml
<h1 class="mods-section-head mods-related-preceding">Replaces</h1>
<div class="mods-section-body mods-related-preceding">
  <div class="mods-one-related">
    ...
  </div>
</div>
```  

This table lists the possible headings for each type of relation:

type relation | possible headings
---------|------------------
`preceding`   | "Replaces", "Preceding event"
`succeeding`  | "Replaced by", "Succeeding event"
`series`      | "Series of events"
`otherFormat` | "Reprinted as"
`original`    | "Translated from"
`references`  | "See also"

For a given type, the proper heading is selected based on other MODS elements found in the document (see the source code for details).

Each `div` of class `mods-one-related` contains a link to the related document:


```xml
<div class="mods-one-related">
  <a class="mods-link-related" href="http://tse-fr.eu/pub/1569">
    http://tse-fr.eu/pub/1569
  </a>
</div>
```



## Extending the stylesheet 

TBD

## Author

* **Christophe Bisière** 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
