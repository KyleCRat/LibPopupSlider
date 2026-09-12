# Changelog

## [1.2.0] - 2026-09-12

### Added
- Added public visual-parts, interaction-state, and font-appearance methods for
  optional skin libraries without changing popup values or drag behavior.

### Fixed
- Advanced LibStub MINOR to 3 so older embedded copies cannot mask the new
  presentation API. Preserved the existing `showBorder` option and verified
  both load orders, existing popups, and equal-MINOR loads under Lua 5.1.

## [1.1.0] - 2026-09-03

### Added
- Added a `showBorder` option so consumers can replace the built-in border while preserving the existing default appearance.
