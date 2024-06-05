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
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Should raise an issue if bit size comes before the data type" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::32-integer>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if bit size is the default of the specified type" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::float-64>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if the endian specified is the default of the specified type" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::big-float>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue by assuming the default type is integer" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::big-unsigned-32>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should NOT raise an issue by assuming the default type is integer" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::little-32>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Should NOT raise an issue when using syntax: <<X-bits>>" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::4-bits>>
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
  end

  test "Should NOT raise an issue when using `unit`" do
    """
    defmodule Test do
      def some_function(x) do
        <<_values::size(length)-unit(8), rest::binary>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
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
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Should raise an issue for pattern if `size(x)` is used with `bytes`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(16)-bytes>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if constant size comes after `bytes`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::bytes-16>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if size is used with integer" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::little-integer-size(32)>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if size is used with a plain value" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(32)>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  # Bit Strings

  test "Should raise an issue if constants are used with `bitstring`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::bitstring-16>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if size comes before `bitstring`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(16)-bitstring>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should NOT raise an issue for pattern <<x::bitstring-size(...)>>" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::bitstring-size(@something)>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
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
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should raise an issue if size comes before `binary`" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::size(16)-binary>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Should NOT raise an issue for pattern <<x::binary-size(...)>>" do
    """
    defmodule Test do
      def some_function(x) do
        <<x::binary-size(@something)>>
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end
end
