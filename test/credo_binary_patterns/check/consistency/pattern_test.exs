defmodule CredoBinaryPatterns.Check.Consistency.PatternTest do
  use Credo.Test.Case

  @described_check CredoBinaryPatterns.Check.Consistency.Pattern

  #
  # cases NOT raising issues
  #

  test "Should NOT report violation" do
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

  test "Should raise an issue if bit size comes before the data type" do
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

  test "Should raise an issue if bit size is the default of the specified type" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::float-64>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end

  test "Should raise an issue if the endian specified is the default of the specified type" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::big-float>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end
end
