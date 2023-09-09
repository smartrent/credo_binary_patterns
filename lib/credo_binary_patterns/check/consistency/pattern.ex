defmodule CredoBinaryPatterns.Check.Consistency.Pattern do
  @moduledoc """
  Credo check to ensure binary pattern matches follow common forms
  """
  require Logger
  use Credo.Check, base_priority: :high, category: :warning

  # Default modifier pairs that can be shortened
  @default_pairs [
    {:unsigned, 8},
    {:float, 64},
    {:bitstring, 1}
  ]

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # Matches all forms of [value_matched]::[left]-[right]
  defp traverse(
         {:"::", [line: pattern_line, column: pattern_col],
          [
            value_match,
            {:-, _loc, [left, right]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    left = unwrap(left)
    right = unwrap(right)
    value_match = Macro.to_string(value_match)

    issue =
      cond do
        # Number of bits should not come before the type
        is_number(left) and is_atom(right) -> :out_of_order
        {left, right} in @default_pairs -> :default
        left == :unsigned -> :unneeded_unsigned
        true -> nil
      end

    if issue do
      {ast,
       issues ++
         [issue_for(issue, value_match, left, right, pattern_line, pattern_col, issue_meta)]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp unwrap({atom_name, _, _}) do
    atom_name
  end

  defp unwrap(val), do: val

  defp issue_for(:out_of_order, value, left, right, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Bits should come after type] Please re-write this binary pattern as #{value}::#{right}-#{left}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:unneeded_unsigned, value, _left, right, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message: "[Unneeded 'unsigned'] Please re-write this binary pattern as #{value}::#{right}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:default, value, left, right, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message: "[Unneeded '#{left}'] Please re-write this binary pattern as #{value}::#{right}",
      line_no: line,
      column: col
    )
  end
end
