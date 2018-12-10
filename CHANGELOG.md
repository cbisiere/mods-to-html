# Changelog


## 2016-02-26

### Added
- section `mods-related-series` for series of events

## 2016-02-22

### Added
- CSS class `mods-role-$role`
- CSS classes `mods-one-*`, `mods-jel-code`, `mods-jel-description`
- extra parameter checks

### Changed
- put each keyword, JEL code and JEL description into its own element
- put each keyword into a `div`, right below the section body 
- root `mods-root` now always present

### Fixed
- fix function `substring-after-last`

## 2016-01-27
### Added
- process requests for several languages at once: if `displayLanguage` is, e.g., `"fre eng"`, the slylesheet returns a document with the following structure:

```xml
<div class="mods-root">
  <div class="mods-item mods-lang-fre">
     ...
  </div>
  <div class="mods-item mods-lang-eng">
     ...
  </div>
</div>
```

## 2015-07-28
### Changed
- for convenience, the stylesheet now also handles OAI responses, not just MODS documents

## 2014-05
- initial version
