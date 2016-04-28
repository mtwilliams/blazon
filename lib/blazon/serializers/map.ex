defmodule Blazon.Serializers.Map do
  @moduledoc ~S"""
  """

  @behaviour Blazon.Serializer

  def serialize(agnostic, opts) do
    Enum.into(agnostic, %{})
  end
end
