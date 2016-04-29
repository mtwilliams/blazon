if Code.ensure_loaded?(Poison) do
  defmodule Blazon.Serializers.JSON do
    @moduledoc ~S"""
    """

    @behaviour Blazon.Serializer

    def serialize(agnostic, opts) do
      Enum.into(agnostic, %{})
      |> Poison.encode!
    end
  end
end