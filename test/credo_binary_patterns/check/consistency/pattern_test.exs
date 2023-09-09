defmodule CredoBinaryPatterns.Check.Consistency.PatternTest do
  use Credo.Test.Case

  @described_check CredoBinaryPatterns.Check.Consistency.Pattern

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::integer-32>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::32-integer>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end
end
