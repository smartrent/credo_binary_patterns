defmodule CredoBinaryPatterns.Check.Consistency.Pattern do
  @moduledoc """
  Credo check to ensure binary pattern matches follow common formats.

  It will capture the following binary expressions:
    [value]::[left]-[right]
    [value]::[first]-[second]-[third]
    [value]::[first]-[second]-[third]-[fourth]
  """
  use Credo.Check, base_priority: :high

  @signs [:signed, :unsigned]
  @endians [:big, :little, :native]
  @types [:integer, :float, :bits, :bitstring, :binary, :bytes, :utf8, :utf16, :utf32]

  @impl Credo.Check
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.postwalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # 4 elements
  defp traverse(
         {:"::", [line: pattern_line, column: pattern_col],
          [
            value_matched,
            {:-, _,
             [
               {:-, _,
                [
                  {:-, _,
                   [
                     first,
                     second
                   ]},
                  third
                ]},
               fourth
             ]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    first = unwrap(first)
    second = unwrap(second)
    third = unwrap(third)
    fourth = unwrap(fourth)
    value_matched = unwrap_value(value_matched)

    pattern_info = build_info([first, second, third, fourth])

    maybe_issue =
      determine_issue(
        value_matched,
        pattern_info,
        [first, second, third, fourth],
        pattern_line,
        pattern_col,
        issue_meta
      )

    if maybe_issue do
      {ast, [maybe_issue | issues]}
    else
      {ast, issues}
    end
  end

  # 3 elements
  defp traverse(
         {:"::", [line: pattern_line, column: pattern_col],
          [
            value_matched,
            {:-, _,
             [
               {:-, _,
                [
                  first,
                  second
                ]},
               third
             ]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    first = unwrap(first)
    second = unwrap(second)
    third = unwrap(third)
    value_matched = unwrap_value(value_matched)

    pattern_info = build_info([first, second, third])

    maybe_issue =
      determine_issue(
        value_matched,
        pattern_info,
        [first, second, third],
        pattern_line,
        pattern_col,
        issue_meta
      )

    if maybe_issue do
      {ast, [maybe_issue | issues]}
    else
      {ast, issues}
    end
  end

  # 2 elements
  defp traverse(
         {:"::", [line: pattern_line, column: pattern_col],
          [
            {value_matched, [line: _, column: _], nil},
            {:-, _, [left, right]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    left = unwrap(left)
    right = unwrap(right)
    value_matched = unwrap_value(value_matched)

    pattern_info = build_info([left, right])

    maybe_issue =
      determine_issue(
        value_matched,
        pattern_info,
        [left, right],
        pattern_line,
        pattern_col,
        issue_meta
      )

    if maybe_issue != nil do
      {ast, [maybe_issue | issues]}
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

  defp unwrap_value(val), do: Macro.to_string(val) |> String.trim_leading(":")

  defp issue_for(:out_of_order, fixed, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Options out of order] Should follow: [endian]-[sign]-[type]-[size]. Please re-write this binary pattern as #{fixed}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:default_size, fixed, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message: "[Unneeded size specified] Please re-write this binary pattern as #{fixed}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:default_sign, fixed, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Unneeded signed/unsigned specified] Please re-write this binary pattern as #{fixed}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:default_endian, fixed, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message: "[Unneeded endian specified] Please re-write this binary pattern as #{fixed}",
      line_no: line,
      column: col
    )
  end

  defp determine_issue(value, pattern_info, original_members, line, col, meta) do
    cond do
      # Bits must come AFTER the type/other members of the pattern
      not in_correct_order?(original_members) ->
        issue_for(:out_of_order, stringify(value, pattern_info), line, col, meta)

      # Check if the size specified in the pattern is the default size of the type
      default_size(pattern_info.type) == pattern_info.size ->
        issue_for(:default_size, stringify(value, pattern_info), line, col, meta)

      # Check if the sign specified in the pattern is the default sign for the type
      default_sign(pattern_info.type) == pattern_info.sign ->
        issue_for(:default_sign, stringify(value, pattern_info), line, col, meta)

      default_endian(pattern_info.type) == pattern_info.endian ->
        issue_for(:default_endian, stringify(value, pattern_info), line, col, meta)

      true ->
        nil
    end
  end

  # The general order should always be: [endian]-[sign]-[type]-[size]
  # What we do here, is rank each component type with a numeric value corresponding to the proper ordering.
  # If we sort this ranked list, and the result does not match the original list, the pattern is out of order.
  defp in_correct_order?(components) when is_list(components) do
    components_ranked =
      Enum.map(components, fn c ->
        case get_component_type(c) do
          :endian -> 1
          :sign -> 2
          :type -> 3
          :size -> 4
        end
      end)

    Enum.sort(components_ranked) == components_ranked
  end

  # Proper format of the pattern as a string
  defp stringify(value, %{type: type, size: size, endian: endian, sign: sign}) do
    subj = ""

    subj =
      if is_nil(endian) or default_endian(type) == endian do
        subj
      else
        subj <> "#{endian}-"
      end

    subj =
      if is_nil(sign) or default_sign(type) == sign do
        subj
      else
        subj <> "#{sign}-"
      end

    subj =
      if is_nil(type) do
        subj
      else
        subj <> "#{type}-"
      end

    subj =
      if is_nil(size) or default_size(type) == size do
        subj
      else
        subj <> "#{size}"
      end

    result = "#{value}::#{subj}" |> String.trim_trailing("-")
    "<<#{result}>>"
  end

  defp build_info(members) do
    type = Enum.find(members, &type_option?/1)
    sign = Enum.find(members, &sign_option?/1)
    endian = Enum.find(members, &endian_option?/1)
    size = Enum.find(members, &size_option?/1)
    %{type: type, size: size, sign: sign, endian: endian}
  end

  defp default_size(:integer), do: 8
  defp default_size(:float), do: 64
  defp default_size(:bitstring), do: 1
  defp default_size(:bits), do: 1
  defp default_size(:utf8), do: 8
  defp default_size(:utf16), do: 16
  defp default_size(:utf32), do: 32
  defp default_size(_), do: :none

  defp default_endian(:integer), do: :big
  defp default_endian(:float), do: :big
  defp default_endian(:utf8), do: :big
  defp default_endian(:utf16), do: :big
  defp default_endian(:utf32), do: :big
  defp default_endian(:bitstring), do: :none
  defp default_endian(:bits), do: :none
  defp default_endian(_), do: :none

  defp default_sign(:integer), do: :unsigned
  defp default_sign(:float), do: :unsigned
  defp default_sign(:utf8), do: :unsigned
  defp default_sign(:utf16), do: :unsigned
  defp default_sign(:utf32), do: :unsigned
  defp default_sign(:bitstring), do: :none
  defp default_sign(:bits), do: :none
  defp default_sign(_), do: :none

  defp type_option?(c), do: c in @types
  defp sign_option?(c), do: c in @signs
  defp endian_option?(c), do: c in @endians
  defp size_option?(c), do: is_integer(c)

  defp get_component_type(c) do
    cond do
      endian_option?(c) -> :endian
      sign_option?(c) -> :sign
      type_option?(c) -> :type
      size_option?(c) -> :size
      :size -> :size
    end
  end
end
