defmodule MCPDocs.DocumentationTest do
  use ExUnit.Case, async: true

  alias MCPDocs.Fixtures.Sample

  # We need to compile documentation
  Code.compiler_options(docs: true)

  setup_all do
    Code.ensure_loaded(Sample)
    :ok
  end


  describe "get_docs/3" do
    test "returns module documentation" do
      result = MCPDocs.Documentation.get_docs(Sample, nil, nil)
      assert match?(%{type: :module, module: Sample}, result)
      assert result.moduledoc =~ "A test module for documentation testing"
      assert length(result.functions) > 0
      assert length(result.types) > 0
      assert length(result.callbacks) > 0
    end

    test "returns function documentation" do
      result = MCPDocs.Documentation.get_docs(Sample, :test_function, 1)
      assert match?(%{type: :function, module: Sample}, result)
      assert [function] = result.functions
      assert function.name == :test_function
      assert function.arity == 1
      assert function.doc =~ "A test function with documentation"
      assert function.spec != nil
    end

    test "returns all function arities when arity is nil" do
      result = MCPDocs.Documentation.get_docs(Sample, :multi_arity, nil)
      assert match?(%{type: :function, module: Sample}, result)
      assert length(result.functions) == 2

      arities = Enum.map(result.functions, & &1.arity)
      assert Enum.sort(arities) == [0, 1]
    end

    test "returns error for non-existent module" do
      result = MCPDocs.Documentation.get_docs(NonExistentModule, nil, nil)
      assert match?({:error, _}, result)
    end

    test "returns error for non-existent function" do
      result = MCPDocs.Documentation.get_docs(Sample, :non_existent, 1)
      assert match?({:error, _}, result)
    end

    test "returns error when module is nil" do
      result = MCPDocs.Documentation.get_docs(nil, nil, nil)
      assert match?({:error, "Module name is required"}, result)
    end
  end

  describe "list_modules/1" do
    test "lists modules matching pattern" do
      # Use our Sample module instead since we know it exists
      modules = MCPDocs.Documentation.list_modules("MCPDocs.Fixtures.S*")
      assert Sample in modules
    end

    test "returns empty list for non-matching pattern" do
      modules = MCPDocs.Documentation.list_modules("NonExistent.*")
      assert modules == []
    end

    test "handles empty pattern" do
      modules = MCPDocs.Documentation.list_modules("")
      assert is_list(modules)
      assert length(modules) > 0
      # Our Sample module should be in the list
      assert Sample in modules
    end
  end

  describe "list_functions/2" do
    test "lists functions matching pattern" do
      functions = MCPDocs.Documentation.list_functions(Sample, "test_*")
      assert {:test_function, 1} in functions
    end

    test "returns empty list for non-matching pattern" do
      functions = MCPDocs.Documentation.list_functions(Sample, "nonexistent_*")
      assert functions == []
    end

    test "returns empty list for non-existent module" do
      functions = MCPDocs.Documentation.list_functions(NonExistentModule, "*")
      assert functions == []
    end

    test "handles empty pattern" do
      functions = MCPDocs.Documentation.list_functions(Sample, "")
      assert is_list(functions)
      assert length(functions) > 0
      # Should include our test function
      assert {:test_function, 1} in functions
    end
  end
end
