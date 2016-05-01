defmodule Blazon do
  @moduledoc ~S"""
  """

  def serializable?(mod) do
    if Code.ensure_loaded?(mod) do
      function_exported?(mod, :__blazon__, 0)
    else
      false
    end
  end

  @serializers [{:map, Blazon.Serializers.Map},
                {:json, Blazon.Serializers.JSON}]

  for {name, serializer} <- @serializers do
    def unquote(:"to_#{name}")(serializable, model, opts \\ []) do
      apply(serializable, :serialize, [unquote(serializer), model, opts])
    end
  end
end
