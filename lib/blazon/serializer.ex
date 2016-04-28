defmodule Blazon.Serializer do
  @moduledoc ~S"""
  """

  # TODO(mtwilliams): Improve type signature.
  @callback serialize([{atom, any}], Keyword.t) :: any
end
