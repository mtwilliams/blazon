defmodule Blazon.Serializable do
  @moduledoc ~S"""
  """

  @options ~w(only except via)a

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Blazon.Serializable

      # This is helps us differentiate between representers and structs. We
      # could use `Module.defines?(__MODULE__, :__struct__)`, but this seems
      # cleaner because it's not tied to Elixir's internals. It also allows us
      # to detect modules that are neither.
      def __blazon__, do: true

      # Our field/3, link/3, and embed/3 macros simply build up an agnostic
      # definition of how to serialize an object thats used by Blazon.Serializer
      # implementations.
      @before_compile Blazon.Serializable
      Module.register_attribute __MODULE__, :__serialize__, accumulate: true, persist: false
    end
  end

  @doc false
  defmacro __before_compile__(_opts) do
    quote do
      def serialize(serializer, model, opts \\ []) do
        filtered = case {Keyword.get(opts, :only), Keyword.get(opts, :except)} do
          {nil, nil} ->
            @__serialize__
          {nil, leave} ->
            Enum.reject(@__serialize__, fn field -> field in leave end)
          {keep, nil} ->
            Enum.filter(@__serialize__, fn field -> field in keep end)
        end

        filtered
        |> Enum.map(fn serialize -> {serialize, __field__(serialize, model)} end)
        |> serializer.serialize(opts)
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

  defmacro field(name, opts \\ []) do
    case Keyword.get(opts, :via) do
      {:fn, _, _} = generator ->
        quote do
          @__serialize__ unquote(name)
          def __field__(unquote(name), model) do
            unquote(generator).(model)
          end
        end
      _ ->
        quote do
          @__serialize__ unquote(name)
          def __field__(unquote(name), model) do
            Map.get(model, unquote(name))
          end
        end
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
        expand = expander(representer_or_type, opts)
        quote do
          @__serialize__ unquote(name)
          def __field__(unquote(name), model) do
            Enum.map(Map.get(model, unquote(name)), unquote(expand))
          end
        end

      aliased ->
        representer_or_type = Macro.expand(aliased, __CALLER__)
        expand = expander(representer_or_type, opts)
        quote do
          @__serialize__ unquote(name)
          def __field__(unquote(name), model) do
            unquote(expand).(Map.get(model, unquote(name)))
          end
        end
    end
  end

  defp expander(representer_or_type, opts) do
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

