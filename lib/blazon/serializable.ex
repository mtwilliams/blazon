defmodule Blazon.Serializable do
  @moduledoc ~S"""
  """

  @options ~w(only except via)a

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Blazon.Serializable

      # This helps us differentiate between representers and structs. We could
      # use `Module.defines?(__MODULE__, :__struct__)`, but this seems cleaner
      # because it's not tied to Elixir's internals. It also allows us to
      # detect modules that are neither (and inform the user of their incompetence).
      def __blazon__, do: true

      # Our field/3, link/3, and embed/3 macros simply build up an agnostic
      # definition of how to serialize an object that's used by Blazon.Serializer
      # implementations.
      @before_compile Blazon.Serializable
      Module.register_attribute __MODULE__, :__serialize__, accumulate: true, persist: false

      # Allow users to massage their model prior to serialization.
      defp __before_serialize__(model), do: model
      defoverridable [__before_serialize__: 1]

      # Also allow users to massage their model after serialization. I can't
      # think of case where this makes sense (in production). However, it can
      # be useful for profiling.
      defp __after_serialize__(model), do: model
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

      def serialize(serializer, model, opts \\ []) do
        fields = to_be_serialized(opts)
        extract = fn model -> Enum.map(fields, &({&1, __field__(&1, model)})) end

        model
        |> __before_serialize__
        |> extract.()
        |> serializer.serialize(opts)
        |> __after_serialize__
      end

      defp to_be_serialized(opts) do
        case {Keyword.get(opts, :only), Keyword.get(opts, :except)} do
          {nil, nil} ->
            @__serialize__
          {nil, leave} ->
            Enum.reject(@__serialize__, &(&1 in leave))
          {keep, nil} ->
            Enum.filter(@__serialize__, &(&1 in keep))
        end
      end
    end
  end

  def is?(module) do
    if Code.ensure_loaded?(module) do
      function_exported?(module, :__blazon__, 0)
    else
      false
    end
  end

  @hooks ~w(before after)a

  defmacro hook(hook, do: body) when hook in @hooks do
    quote do
      defp unquote(:"__#{hook}_serialize__")(var!(model)) do
        unquote(body)
      end
    end
  end

  defmacro field(name, opts \\ []) do
    case Keyword.get(opts, :via) do
      {:&, _, _} = generator ->
        serialize_via_generator(name, generator)
      {:fn, _, _} = generator ->
        serialize_via_generator(name, generator)
      _ ->
        quote do
          @__serialize__ unquote(name)
          defp __field__(unquote(name), model), do: Map.get(model, unquote(name))
        end
    end
  end

  defp serialize_via_generator(name, generator) do
    quote do
      @__serialize__ unquote(name)
      defp __field__(unquote(name), model), do: unquote(generator).(model)
    end
  end

  defmacro link(name, opts \\ []) do
    # TODO(mtwilliams): Implement linking.
    raise "Not implemented yet!"
  end

  defmacro embed(name, representer_or_type, opts \\ []) do
    case representer_or_type do
      [aliased] ->
        representer_or_type = Macro.expand(aliased, __CALLER__)
        embed = do_embed(representer_or_type, opts)
        quote do
          @__serialize__ unquote(name)
          defp __field__(unquote(name), model) do
            Enum.map(Map.get(model, unquote(name)), unquote(embed))
          end
        end

      aliased ->
        representer_or_type = Macro.expand(aliased, __CALLER__)
        embed = do_embed(representer_or_type, opts)
        quote do
          @__serialize__ unquote(name)
          defp __field__(unquote(name), model) do
            unquote(embed).(Map.get(model, unquote(name)))
          end
        end
    end
  end

  defp do_embed(representer_or_type, opts) do
    quote do
      if Blazon.Serializable.is?(unquote(representer_or_type)) do
        fn model ->
          unquote(representer_or_type).serialize(Blazon.Serializers.Map, model, unquote(opts))
        end
      else
        fn model ->
          # SMELL(mtwilliams): This is pretty much the same as the code in
          # our __before_compile__ hook.
          case unquote({Keyword.get(opts, :only), Keyword.get(opts, :except)}) do
            {nil, nil} ->
              model
            {nil, leave} ->
              Enum.reject(model, fn {field, _} -> field in leave end)
            {keep, nil} ->
              Enum.filter(model, fn {field, _} -> field in keep end)
          end
        end
      end
    end
  end
end

