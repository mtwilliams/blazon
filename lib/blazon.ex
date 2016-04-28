defmodule Blazon do
  @moduledoc ~S"""
  """

  def serialize(serializer, model) do
    apply(serializer, :serialize, [model])
  end
end
