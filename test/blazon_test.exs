defmodule Blazon.Tests do
  use ExUnit.Case, async: true

  @basics %{
    nil: nil,
    atom: :foo,
    truthy: true,
    falsey: false,
    integer: 1,
    float: 1.0,
    string: "foo",
    charlist: 'foo',
    list: [1, 2, 3],
    map: %{foo: :bar}
  }

  defmodule BasicsSerializer do
    use Blazon.Serializable

    field :nil
    field :atom
    field :truthy
    field :falsey
    field :integer
    field :float
    field :string
    field :charlist
    field :list
    field :map
  end

  test "serialization of basic types" do
    assert BasicsSerializer.serialize(Blazon.Serializers.Map, @basics) == @basics
  end

  defmodule DouglasAdamsSerializer do
    use Blazon.Serializable
    field :meaning_of_life
  end

  @the_answer_to_the_ultimate_question %{meaning_of_life: 42}

  test "only" do
    assert DouglasAdamsSerializer.serialize(Blazon.Serializers.Map, @the_answer_to_the_ultimate_question, only: []) == %{}

    serialized = DouglasAdamsSerializer.serialize(Blazon.Serializers.Map, @the_answer_to_the_ultimate_question, only: ~w(meaning_of_life)a)
    assert serialized == @the_answer_to_the_ultimate_question
  end

  test "except" do
    assert DouglasAdamsSerializer.serialize(Blazon.Serializers.Map, @the_answer_to_the_ultimate_question, except: ~w(meaning_of_life)a) == %{}

    serialized = DouglasAdamsSerializer.serialize(Blazon.Serializers.Map, @the_answer_to_the_ultimate_question, except: [])
    assert serialized == @the_answer_to_the_ultimate_question
  end

  test "only and except are mutually exclusive" do
    # TODO(mtwilliams): Provide a custom exception type.
    assert_raise CaseClauseError, fn ->
      DouglasAdamsSerializer.serialize(Blazon.Serializers.Map, %{}, only: ~w(meaning_of_life)a, except: ~w(meaning_of_life)a)
    end
  end

  defmodule EmbeddedSerializer do
    use Blazon.Serializable
    embed :basics, BasicsSerializer
  end

  test "embedding" do
    assert EmbeddedSerializer.serialize(Blazon.Serializers.Map, %{basics: @basics}) == %{basics: @basics}
  end

  test "json" do
    encoded = BasicsSerializer.serialize(Blazon.Serializers.JSON, @basics)
    assert encoded == Poison.encode!(@basics)
  end

  defmodule HooksSerializer do
    use Blazon.Serializable

    hook :before do
      %{before: true}
    end

    hook :after do
      Map.merge(model, %{after: true})
    end

    field :before
    field :after
  end

  test "hooks" do
    assert HooksSerializer.serialize(Blazon.Serializers.Map, %{}) == %{before: true, after: true}
  end
end
