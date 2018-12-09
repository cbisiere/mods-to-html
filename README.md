# mods-to-html

An XSLT 1.0 stylesheet to transform a MODS document into an HTML chunk. 

Highlights:

* Thanks to XSLT 1.0, the stylesheet is compatible with most XSLT processors.
* The HTML chunk is made of several `div` and `span` elements, each having a specific class. This facilitates CSS formatting, or XML editing using a programming language.
* The output is made of sections (e.g., `reference`, `abstract`, `keywords`). One or more sections can be requested.
* When the reference is meant to be part of the CV of one contributor, the name of this contributor is omitted, and the others are cited in a "with" statement.


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
$ xsltproc --stringparam sections "reference-body" ./modstohtml.xsl article.xml
```

gives:

```
Bruno Biais, Christophe Bisière, and Chester Spatt, “Imperfect Competition in Financial Markets: 
An Empirical Study of Island and Nasdaq”, Management Science, vol. 56, n. 12, December 2010, 
pp. 2237–2250.
```

To get the reference in French, as part of the CV of the second coauthor:

```bash
$ xsltproc --stringparam sections "reference-body" --stringparam displayLanguage "fre" \
  --stringparam vitaeOf "http://tse-fr.eu/aut/28" ./modstohtml.xsl article.xml
```

```
« Imperfect Competition in Financial Markets: An Empirical Study of Island and Nasdaq », 
Management Science, vol. 56, n° 12, décembre 2010, p. 2237–2250.
(avec Bruno Biais et Chester Spatt)
```

A more complete example, with four sections:

```bash
$ xsltproc --stringparam sections "reference abstract keywords jelcodes" ./modstohtml.xsl article.xml
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

## CSS classes

TBD

## Using Fragments 

TBD

## Author

* **Christophe Bisière** 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
