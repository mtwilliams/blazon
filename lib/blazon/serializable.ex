defmodule Blazon.Serializable do
  @moduledoc ~S"""
  """

  @hooks ~w(before after)a

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Blazon.Serializable

      # This helps us differentiate between serializables and structs. We could
      # use `Module.defines?(__MODULE__, :__struct__)`, but this seems cleaner
      # because it's not tied to Elixir's internals. It also allows us to
      # detect modules that are neither (and inform the user of their incompetence).
      def __blazon__, do: true

      # Our field/3, link/3, and embed/3 macros simply build up an agnostic
      # definition of how to serialize an object that's used by Blazon.Serializer
      # implementations.
      @before_compile Blazon.Serializable
      Module.register_attribute __MODULE__, :__serialize__, accumulate: true

      # Allow users to massage their model prior to serialization.
      @doc false
      def __before_serialize__(model), do: model
      defoverridable [__before_serialize__: 1]

      # Also allow users to massage their model after serialization. I can't
      # think of case where this makes sense (in production). However, it can
      # be useful for profiling.
      @doc false
      def __after_serialize__(model), do: model
      defoverridable [__after_serialize__: 1]
    end
  end

  @doc false
  defmacro __before_compile__(_opts) do
    quote do
      # We ensure __field__ is defined at least once so `extract` (in
      # `serialize/3` below) compiles even if a user doesn't declare a single
      # field, link, or embed to serialize.
      defp __field__(:__blazon__, _), do: true

      # This shouldn't be called directly... so we obsfucate the name.
      def __serialize__(serializer, model, opts \\ []) do
        fields = Blazon.Options.fields_to_extract(@__serialize__, opts)
        extract = fn model -> Enum.map(fields, &({&1, __field__(&1, model)})) end

        model
        |> __before_serialize__
        |> extract.()
        |> serializer.serialize(opts)
        |> __after_serialize__
      end
    end
  end

  defmacro hook(hook, do: body) when hook in @hooks do
    quote do
      defp unquote(:"__#{hook}_serialize__")(var!(model)), do: unquote(body)
    end
  end

  @doc ~S"""
  """
  defmacro field(name, opts \\ []) do
    quote do
      @__serialize__ unquote(name)

      defp __field__(unquote(name), var!(model)) do
        unquote(
          case Keyword.get(opts, :via) do
            nil ->
              __field_via_fetcher__(name)
            {:&, _, _} = via ->
              __field_via_generator__(name, via)
            {:fn, _, _} = via ->
              __field_via_generator__(name, via)
          end
        )
      end
    end
  end

  @doc false
  defp __field_via_fetcher__(name) do
    quote do Map.get(var!(model), unquote(name)) end
  end

  @doc false
  defp __field_via_generator__(_name, generator) do
    quote do unquote(generator).(var!(model)) end
  end

  @doc ~S"""
  """
  defmacro link(_name, _opts \\ []) do
    # TODO(mtwilliams): Implement linking.
    raise "Not implemented yet!"
  end

  @doc ~S"""
  """
  defmacro embed(name, serializable, opts \\ []) do
    {aliased, unaliased, plural} = case serializable do
      [aliased] -> {aliased, Macro.expand(aliased, __CALLER__), true}
      aliased   -> {aliased, Macro.expand(aliased, __CALLER__), false}
    end

    subfield = quote do
      defp __field__(unquote(:"#{name}[]"), model) do
        if Blazon.serializable?(unquote(aliased)) do
          unquote(unaliased).__serialize__(Blazon.Serializers.Map, model, unquote(opts))
        else
          case unquote({Keyword.get(opts, :only), Keyword.get(opts, :except)}) do
            {nil, nil}   -> model
            {nil, leave} -> Enum.reject(model, fn {field, _} -> field in leave end)
            {keep, nil}  -> Enum.filter(model, fn {field, _} -> field in keep end)
          end
        end
      end
    end

    # SMELL(mtwilliams): This is a lot of code duplication.
    field = if plural do
      quote do
        defp __field__(unquote(name), model) do
          case Map.get(model, unquote(name)) do
            nil -> nil
            submodels when is_list(submodels) ->
              Enum.map(submodels, &(__field__(unquote(:"#{name}[]"), &1)))
          end
        end
      end
    else
      quote do
        defp __field__(unquote(name), model) do
          case Map.get(model, unquote(name)) do
            nil -> nil
            submodel ->
              __field__(unquote(:"#{name}[]"), submodel)
          end
        end
      end
    end

    quote do
      @__serialize__ unquote(name)

      unquote(field)
      unquote(subfield)
    end
  end
end

