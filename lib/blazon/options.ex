defmodule Blazon.Options do
  @moduledoc ~S"""
  """

  def fields_to_extract(all, opts) do
    case {Keyword.get(opts, :only), Keyword.get(opts, :except)} do
      {nil, nil} ->
        all

      {keep, nil} ->
        is_list_of_atoms!(:only, keep)
        Enum.filter(all, &(&1 in keep))

      {nil, leave} ->
        is_list_of_atoms!(:except, leave)
        Enum.reject(all, &(&1 in leave))

      _ ->
        raise Blazon.OptionsError,
          options: [:only, :except],
          reason: "May only specify one."
    end
  end

  @doc false
  defp is_list_of_atoms!(option, l) do
    if not is_list_of_atoms(l) do
      raise Blazon.OptionsError,
        options: [option],
        reason: "Expected a list of atoms."
    end
  end

  @doc false
  defp is_list_of_atoms(l) when is_list(l), do: Enum.all?(l, &is_atom/1)
  defp is_list_of_atoms(_), do: false
end

defmodule Blazon.OptionsError do
  defexception options: [], reason: nil

  def message(%{options: _, reason: reason}) do
    reason
  end
end
