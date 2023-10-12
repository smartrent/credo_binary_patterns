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

  # 5 elements
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
                     {:-, _,
                      [
                        first,
                        second
                      ]},
                     third
                   ]},
                  fourth
                ]},
               fifth
             ]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    process_traverse(
      value_matched,
      [first, second, third, fourth, fifth],
      pattern_line,
      pattern_col,
      issue_meta,
      issues,
      ast
    )
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
    process_traverse(
      value_matched,
      [first, second, third, fourth],
      pattern_line,
      pattern_col,
      issue_meta,
      issues,
      ast
    )
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
    process_traverse(
      value_matched,
      [first, second, third],
      pattern_line,
      pattern_col,
      issue_meta,
      issues,
      ast
    )
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
    process_traverse(
      value_matched,
      [left, right],
      pattern_line,
      pattern_col,
      issue_meta,
      issues,
      ast
    )
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp process_traverse(
         value_matched,
         elements,
         pattern_line,
         pattern_col,
         issue_meta,
         issues,
         ast
       ) do
    elements = Enum.map(elements, &unwrap/1)
    value_matched = unwrap_value(value_matched)
    pattern_info = build_info(elements)

    maybe_issue =
      determine_issue(
        value_matched,
        pattern_info,
        elements,
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

  defp unwrap({:size, _, [value]}) do
    {:size, unwrap(value)}
  end

  defp unwrap({:unit, _, [value]}) do
    {:unit, unwrap(value)}
  end

  defp unwrap({atom_name, _, _}) do
    atom_name
  end

  defp unwrap(val), do: val

  defp unwrap_value(val), do: Macro.to_string(val) |> String.trim_leading(":")
  defp unwrap_tuple({_, value}), do: value

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

  defp issue_for(:no_size_here, fixed, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Don't use size with integer/float] Please re-write this binary pattern as #{fixed}",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:no_size_with_bytes, value, size_constant, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Do not use size with `bytes`] Please re-write this binary pattern using as <<#{value}::binary-size(#{size_constant})>>",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:no_constants_with_binary, value, size_constant, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Do not use bare sizes with `binary`] Please re-write this binary pattern using as <<#{value}::#{size_constant}-bytes>>",
      line_no: line,
      column: col
    )
  end

  defp issue_for(:no_constants_with_bitstring, value, size_constant, line, col, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "[Do not use bare sizes with `bitstring`] Please re-write this binary pattern using as <<#{value}::#{size_constant}-bits>>",
      line_no: line,
      column: col
    )
  end

  # Special cases for binary
  defp determine_issue(value, pattern_info, original_members, line, col, meta)
       when pattern_info.type in [:binary, :bitstring] do
    cond do
      not is_tuple(pattern_info.size) and pattern_info.type == :binary ->
        issue_for(:no_constants_with_binary, value, pattern_info.size, line, col, meta)

      not is_tuple(pattern_info.size) and pattern_info.type == :bitstring ->
        issue_for(:no_constants_with_bitstring, value, pattern_info.size, line, col, meta)

      not in_correct_order?(pattern_info, original_members) ->
        issue_for(:out_of_order, stringify(value, pattern_info), line, col, meta)

      true ->
        nil
    end
  end

  # Special cases for bytes
  defp determine_issue(value, pattern_info, original_members, line, col, meta)
       when pattern_info.type == :bytes do
    cond do
      is_tuple(pattern_info.size) ->
        {_size, size_constant} = pattern_info.size
        issue_for(:no_size_with_bytes, value, size_constant, line, col, meta)

      not in_correct_order?(pattern_info, original_members) ->
        issue_for(:out_of_order, stringify(value, pattern_info), line, col, meta)

      true ->
        nil
    end
  end

  # All other pattern types (integers, floats, bits, etc.)
  defp determine_issue(value, pattern_info, original_members, line, col, meta) do
    cond do
      not in_correct_order?(pattern_info, original_members) ->
        issue_for(:out_of_order, stringify(value, pattern_info), line, col, meta)

      default_size(pattern_info.type) == pattern_info.size ->
        issue_for(:default_size, stringify(value, pattern_info), line, col, meta)

      default_sign(pattern_info.type) == pattern_info.sign ->
        issue_for(:default_sign, stringify(value, pattern_info), line, col, meta)

      default_endian(pattern_info.type) == pattern_info.endian ->
        issue_for(:default_endian, stringify(value, pattern_info), line, col, meta)

      is_tuple(pattern_info.size) and is_integer(unwrap_tuple(pattern_info.size)) ->
        issue_for(:no_size_here, stringify(value, pattern_info), line, col, meta)

      true ->
        nil
    end
  end

  # The general order should always be: [endian]-[sign]-[type]-[size]
  # What we do here, is rank each component type with a numeric value corresponding to the proper ordering.
  # If we sort this ranked list, and the result does not match the original list, the pattern is out of order.
  defp in_correct_order?(pattern_info, components) when is_list(components) do
    # special case, if the type is a binary, size comes before type!
    is_bytes? = pattern_info.type == :bytes
    type_order = if is_bytes?, do: 4, else: 3
    size_order = if is_bytes?, do: 3, else: 4

    components_ranked =
      Enum.map(components, fn c ->
        case get_component_type(c) do
          :endian -> 1
          :sign -> 2
          :type -> type_order
          :size -> size_order
          :unit -> size_order + 1
        end
      end)

    Enum.sort(components_ranked) == components_ranked
  end

  # Proper format of the pattern as a string, used to suggest corrections
  defp stringify(value, %{
         type: :integer,
         sign: :unsigned,
         size: {:size, :size},
         unit: {:unit, unit_value},
         endian: nil
       }),
       do: "<<" <> value <> "::integer-size(size)-unit(#{unit_value})>>"

  defp stringify(value, %{
         type: :integer,
         sign: :signed,
         size: {:size, size},
         unit: {:unit, unit_value},
         endian: nil
       }),
       do: "<<" <> value <> "::signed-size(#{size})-unit(#{unit_value})" <> ">>"

  defp stringify(value, %{
         type: nil,
         sign: :signed,
         size: {:size, byte_size},
         unit: {:unit, unit_value}
       })
       when byte_size in [:byte_size, :size],
       do: "<<" <> value <> "::signed-size(#{byte_size})-unit(#{unit_value})" <> ">>"

  defp stringify(value, pattern_info) do
    order =
      if pattern_info.type in [:bytes, :bits] do
        [:endian, :sign, :size, :unit, :type]
      else
        [:endian, :sign, :type, :size, :unit]
      end

    result =
      Enum.reduce(order, "", fn key, acc ->
        if is_nil(pattern_info[key]) or pattern_info[key] == default(key, pattern_info.type) do
          acc
        else
          acc <> "#{maybe_stringify_tuple(pattern_info[key], pattern_info.type)}-"
        end
      end)

    result = "#{value}::#{result}" |> String.trim_trailing("-")
    "<<#{result}>>"
  end

  defp build_info(members) do
    type = Enum.find(members, &type_option?/1)
    sign = Enum.find(members, &sign_option?/1)
    endian = Enum.find(members, &endian_option?/1)
    size = Enum.find(members, &size_option?/1)
    unit = Enum.find(members, &unit_option?/1)

    %{type: type, size: size, sign: sign, endian: endian, unit: unit}
  end

  # Helper that routes to the proper "defaults" function below
  defp default(component_name, component_value) do
    case component_name do
      :type -> :integer
      :size -> default_size(component_value)
      :endian -> default_endian(component_value)
      :sign -> default_sign(component_value)
      _ -> :no_default
    end
  end

  defp default_size(nil), do: 8
  defp default_size(:integer), do: 8
  defp default_size(:float), do: 64
  defp default_size(:bitstring), do: 1
  defp default_size(:bits), do: 1
  defp default_size(:utf8), do: 8
  defp default_size(:utf16), do: 16
  defp default_size(:utf32), do: 32
  defp default_size(_), do: :none

  defp default_endian(nil), do: :big
  defp default_endian(:integer), do: :big
  defp default_endian(:float), do: :big
  defp default_endian(:utf8), do: :big
  defp default_endian(:utf16), do: :big
  defp default_endian(:utf32), do: :big
  defp default_endian(:bitstring), do: :none
  defp default_endian(:bits), do: :none
  defp default_endian(_), do: :none

  defp default_sign(nil), do: :unsigned
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
  defp size_option?(c), do: is_integer(c) or match?({:size, _}, c)
  defp unit_option?(c), do: match?({:unit, _}, c)

  defp maybe_stringify_tuple({:size, raw_value}, type) when type in [:integer, :float, nil],
    do: "#{raw_value}"

  defp maybe_stringify_tuple({:size, raw_value}, _), do: "size(#{raw_value})"
  defp maybe_stringify_tuple({:unit, raw_value}, _), do: "unit(#{raw_value})"
  defp maybe_stringify_tuple(value, _), do: value

  defp get_component_type(c) do
    cond do
      endian_option?(c) -> :endian
      sign_option?(c) -> :sign
      type_option?(c) -> :type
      size_option?(c) -> :size
      unit_option?(c) -> :unit
    end
  end
end
