defmodule CredoBinaryPatterns.Check.Consistency.PatternTest do
  use Credo.Test.Case

  @described_check CredoBinaryPatterns.Check.Consistency.Pattern

  ## Floats and Integers

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

  ## Bytes

  test "Should NOT raise an issue for pattern <<[constant]-bytes>>" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::16-bytes>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
  end

  test "Should raise an issue for pattern if `size(x)` is used with `bytes`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(16)-bytes>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end

  test "Should raise an issue if constant size comes after `bytes`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::bytes-16>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end

  ## Binaries

  test "Should raise an issue if constants are used with `binary`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::binary-16>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end

  test "Should raise an issue if size comes before `binary`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(16)-binary>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue
  end

  test "Should NOT raise an issue for pattern <<x::binary-size(...)>>" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::binary-size(@something)>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
  end
end
