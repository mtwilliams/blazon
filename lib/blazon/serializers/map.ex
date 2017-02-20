defmodule Blazon.Serializers.Map do
  @moduledoc ~S"""
  """

  @behaviour Blazon.Serializer

  def serialize(agnostic, _opts) do
    Enum.into(agnostic, %{})
  end
end
