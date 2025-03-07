defmodule MCPDocs.Documentation do
  @moduledoc """
  Functions for extracting documentation and code information.
  """

  @doc """
  Gets documentation for a module, function, or both.

  ## Parameters

    * `module` - The module to get documentation for
    * `function` - The function to get documentation for (optional)
    * `arity` - The arity of the function (optional)
    
  ## Returns

  A map containing the documentation information or an error message.
  """
  def get_docs(nil, _function, _arity), do: {:error, "Module name is required"}

  def get_docs(module, function, arity) do
    elixir_module = String.to_atom("Elixir.#{module}")
    function = String.to_atom(function)
    arity = String.to_integer(arity)

    cond do
      not Code.ensure_loaded?(elixir_module) ->
        {:error, "Module #{inspect(elixir_module)} is not available"}

      is_nil(function) ->
        get_module_docs(elixir_module)

      true ->
        get_function_docs(elixir_module, function, arity)
    end
  end

  @doc """
  Lists all loaded modules matching the given pattern.

  Returns a list of module names.
  """
  def list_modules(pattern) do
    pattern_regex = pattern_to_regex(pattern)

    :code.all_loaded()
    |> Enum.map(fn {module, _} -> module end)
    |> Enum.filter(fn module ->
      module_name = Atom.to_string(module)
      String.match?(module_name, pattern_regex)
    end)
    |> Enum.sort()
  end

  @doc """
  Lists all functions in a module matching the given pattern.

  Returns a list of {function_name, arity} tuples.
  """
  def list_functions(module, pattern) do
    pattern_regex = pattern_to_regex(pattern)

    if Code.ensure_loaded?(module) do
      :functions
      |> module.__info__()
      |> Enum.filter(fn {function, _arity} ->
        function_name = Atom.to_string(function)
        String.match?(function_name, pattern_regex)
      end)
      |> Enum.sort()
    else
      []
    end
  end

  # Gets documentation for a module
  defp get_module_docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, :elixir, _, module_doc, _, _} ->
        %{
          type: :module,
          module: module,
          moduledoc: clean_doc(module_doc),
          types: get_module_types(module),
          callbacks: get_module_callbacks(module),
          functions: get_module_functions(module)
        }

      {:error, reason} ->
        {:error, "Could not fetch docs for #{inspect(module)}: #{reason}"}

      _ ->
        {:error, "No documentation found for #{inspect(module)}"}
    end
  end

  # Gets documentation for a specific function
  defp get_function_docs(module, function, arity) do
    # Get all functions if arity is not specified
    functions =
      if is_nil(arity) do
        Enum.filter(get_module_functions(module), fn %{name: name} ->
          name == function
        end)
      else
        functions = get_module_functions(module)

        Enum.filter(functions, fn %{name: name, arity: func_arity} ->
          name == function and func_arity == arity
        end)
      end

    if Enum.empty?(functions) do
      {:error, "No documentation found for #{inspect(module)}.#{function}/#{arity || "*"}"}
    else
      %{
        type: :function,
        module: module,
        functions: functions
      }
    end
  end

  # Gets all functions in a module with their documentation
  defp get_module_functions(module_or_path) do
    docs = Code.fetch_docs(module_or_path)

    case docs do
      {:docs_v1, _, _, _, _, _, function_docs} ->
        function_docs
        |> Enum.filter(fn {{kind, _, _}, _, _, _, _} -> kind == :function end)
        |> Enum.map(fn {{_, name, arity}, line, signatures, doc, metadata} ->
          %{
            name: name,
            arity: arity,
            line: line,
            signatures: signatures,
            doc: clean_doc(doc),
            metadata: metadata
            # spec: get_function_spec(module, name, arity)
          }
        end)

      _ ->
        []
    end
  end

  # Gets all types in a module
  defp get_module_types(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, function_docs} ->
        function_docs
        |> Enum.filter(fn {{kind, _, _}, _, _, _, _} -> kind == :type end)
        |> Enum.map(fn {{_, name, arity}, line, _, doc, _} ->
          %{
            name: name,
            arity: arity,
            line: line,
            doc: clean_doc(doc),
            definition: format_type(module, name, arity)
          }
        end)

      _ ->
        []
    end
  end

  # Gets all callbacks in a module
  defp get_module_callbacks(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, function_docs} ->
        function_docs
        |> Enum.filter(fn {{kind, _, _}, _, _, _, _} -> kind == :callback end)
        |> Enum.map(fn {{_, name, arity}, line, _, doc, _} ->
          %{
            name: name,
            arity: arity,
            line: line,
            doc: clean_doc(doc),
            spec: get_callback_spec(module, name, arity)
          }
        end)

      _ ->
        []
    end
  end

  # Gets the typespec for a function
  defp get_function_spec(module, function, arity) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} ->
        case Enum.find(specs, fn
               {{^function, ^arity}, _} -> true
               _ -> false
             end) do
          {_, [spec]} -> Code.Typespec.spec_to_quoted(function, spec)
          nil -> nil
        end

      _ ->
        nil
    end
  end

  # Gets the typespec for a callback
  defp get_callback_spec(module, function, arity) do
    case Code.Typespec.fetch_callbacks(module) do
      {:ok, callbacks} ->
        case Enum.find(callbacks, fn
               {{^function, ^arity}, _} -> true
               _ -> false
             end) do
          {_, [callback]} -> Code.Typespec.spec_to_quoted(function, callback)
          nil -> nil
        end

      _ ->
        nil
    end
  end

  # Formats a type definition
  defp format_type(module, name, arity) do
    case Code.Typespec.fetch_types(module) do
      {:ok, types} ->
        type =
          Enum.find(types, fn {kind, {type_name, _, args}} ->
            kind in [:type, :opaque] and type_name == name and length(args) == arity
          end)

        case type do
          {_, type_info} -> Code.Typespec.type_to_quoted(type_info)
          nil -> nil
        end

      _ ->
        nil
    end
  end

  # Converts a glob pattern to a regex
  defp pattern_to_regex("") do
    ~r/.*/
  end

  defp pattern_to_regex(pattern) do
    pattern
    |> String.replace(~r/\*/, ".*")
    |> String.replace(~r/\?/, ".")
    |> then(fn p -> "^(Elixir\.)?#{p}" end)
    |> Regex.compile!()
  end

  # Cleans up documentation
  defp clean_doc(:hidden), do: nil
  defp clean_doc(:none), do: nil
  defp clean_doc(nil), do: nil
  defp clean_doc(%{"en" => doc}), do: doc
  defp clean_doc(doc) when is_binary(doc), do: doc
end
