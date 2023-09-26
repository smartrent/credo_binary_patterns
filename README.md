# CredoBinaryPatterns

[![CircleCI](https://circleci.com/gh/smartrent/credo_binary_patterns.svg?style=svg)](https://circleci.com/gh/smartrent/credo_binary_patterns)
[![Hex version](https://img.shields.io/hexpm/v/credo_binary_patterns.svg "Hex version")](https://hex.pm/packages/credo_binary_patterns)

The `:credo_binary_patterns` library contains Credo checks for
writing consistent binary patterns. Elixir lets you do whatever you want.
The checks in this library do not.

## Installation

Add the `:credo_binary_patterns` package to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:credo_binary_patterns, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

## Usage

Add the check to your `.credo.exs` configuration file.

### Ensure pattern consistency

This check will raise issues if any binary patterns in your code do not follow the expected ordering or formatting.

```elixir
{CredoBinaryPatterns.Check.Consistency.Patterns}
```

## Conventions

The following conventions are covered in this library:

  1. Ordering of options in a pattern must be: `endian`, `sign`, `type`, then `size`.
  2. Do not specify unnecessary options (endian, size, sign/unsigned). See the [Elixir Documentation](https://hexdocs.pm/elixir/1.13.4/Kernel.SpecialForms.html#%3C%3C%3E%3E/1-types) for more information on defaults.)

## Example Issues

Suppose you write the following code:

```elixir
defmodule Test do
  def test do
    # This pattern is out of order (size comes before type)
    <<x::32-integer>>

    # This pattern does not need to specify the size (integers default to `8`)
    <<x::integer-8>>

    # This pattens does not need to specify the endian (integers default to `big`)
    <<x::big-integer-16>>
  end
end
```

Credo will warn you about the formatting issues:

```
$ mix credo

  Consistency
┃ 
┃ [C] ↗ [Unneeded endian specified] Please re-write this binary pattern as <<x::integer-16>>
┃       test.ex:10:8 #(Test.test)
┃ [C] ↗ [Unneeded size specified] Please re-write this binary pattern as <<x::integer>>
┃       test.ex:7:8 #(Test.test)
┃ [C] ↗ [Options out of order] Should follow: [endian]-[sign]-[type]-[size]. Please re-write this binary pattern as <<x::integer-32>>
┃       test.ex:4:8 #(Test.test)
```

## License

This library is licensed under the MIT License like Credo.

```text
Copyright (C) 2023 SmartRent

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
