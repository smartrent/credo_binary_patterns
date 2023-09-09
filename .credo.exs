# .credo.exs
%{
  configs: [
    %{
      name: "default",
      strict: true,
      requires: ["lib/"],
      checks: [
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},
        {Credo.Check.Readability.Specs, tags: []},
        {Credo.Check.Readability.StrictModuleLayout, tags: []},
        {CredoBinaryPatterns.Check.Consistency.Pattern}
      ]
    }
  ]
}
