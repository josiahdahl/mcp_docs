defmodule MCPDocs.Fixtures.Sample do
  @moduledoc """
  A test module for documentation testing.
  """

  @doc """
  A test function with documentation.
  """
  @spec test_function(String.t()) :: String.t()
  def test_function(arg), do: arg

  @doc """
  Another test function with multiple arities.
  """
  def multi_arity, do: :ok

  @doc """
  Another test function with multiple arities.
  """
  def multi_arity(arg), do: arg

  @type custom_type :: String.t()

  @callback required_callback() :: :ok
end
