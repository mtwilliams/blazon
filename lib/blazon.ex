defmodule Blazon do
  @moduledoc ~S"""
  """

  @serializers [{:map, Blazon.Serializers.Map},
                {:json, Blazon.Serializers.JSON}]

  for {name, serializer} <- @serializers do
    def unquote(:"to_#{name}")(serializable, model, opts \\ []) do
      apply(serializable, :serialize, [unquote(serializer), model, opts])
    end
  end
end
