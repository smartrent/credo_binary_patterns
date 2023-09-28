# Changelog

## v0.2.2

* Create more specific rules around `bytes`, `binary`, and `size(x)` in patterns. ([#7](https://github.com/smartrent/credo_binary_patterns/pull/7)).
* Fix not handling `unit` correctly.

## v0.2.1

* Adds special case for `bytes` and `binary` options. Size should be specified before these types.

## v0.2.0

* Improve AST parser logic to handle 2, 3, and 4 element patterns.
* Pretty print the pattern in the correct format, along with the issue.
* Initial Hex release 🎉
