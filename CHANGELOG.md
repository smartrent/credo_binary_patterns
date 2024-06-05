# Changelog

## v0.2.6

* Fixes an issue where the `:extraneous_size` rule would be raised when using a variable in a `size` expression.

## v0.2.5

* Suggest patterns in the form of `<<x::size(y)>>` to be rewritten as `<<x::y>>`.
* Fix suggested pattern strings sometimes having a trailing `::` in Credo output.

## v0.2.4

* Treat `bytes` and `bits` both as units. Fixes a false warning when using: `<<x::4-bits>>`.
* Bump dependencies and Elixir version in CI.
* Update code formatting to be more consistent.

## v0.2.3

* Treat `bitstring`/`bits` with the same rules as `binary`/`bytes` ([#13](https://github.com/smartrent/credo_binary_patterns/pull/13)).
* Do not allow `size(constant)` with `interger` and `float`.

## v0.2.2

* Create more specific rules around `bytes`, `binary`, and `size(x)` in patterns. ([#7](https://github.com/smartrent/credo_binary_patterns/pull/7)).
* Fix not handling `unit` correctly.

## v0.2.1

* Adds special case for `bytes` and `binary` options. Size should be specified before these types.

## v0.2.0

* Improve AST parser logic to handle 2, 3, and 4 element patterns.
* Pretty print the pattern in the correct format, along with the issue.
* Initial Hex release 🎉
