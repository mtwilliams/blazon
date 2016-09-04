# Blazon

[![Continuous Integration](https://img.shields.io/travis/mtwilliams/blazon/master.svg)](https://travis-ci.org/mtwilliams/blazon)
[![Code Coverage](https://img.shields.io/coveralls/mtwilliams/blazon/master.svg)](https://coveralls.io/github/mtwilliams/blazon)
[![Documentation](http://inch-ci.org/github/mtwilliams/blazon.svg)](http://inch-ci.org/github/mtwilliams/blazon)
[![Package](https://img.shields.io/hexpm/dt/blazon.svg)](https://hex.pm/packages/blazon)

Blazon allows you to quickly build abstract serializers in a declarative fashion. It also has a large focus on composition, allowing you to quickly build and reuse common functionality for things like pagination, automatic preloading, and so on in a few lines of code. Furthermore, Blazon is format agnostic so you can expose your complex object heirarchies in JSON, XML, UBF, CSV, or whatever you want without changing your presentation logic.

Although Blazon has great test coverage, its design is nowhere near final and is rapidly changing, making it **unsuitable for production**.

## Example

```elixir
defmodule Person.Serializer do
  use Blazon.Serializable

  field :name
  field :title
  field :age
end

Blazon.json(Person.Serializer, %{name: "John Cleese", title: "Minister of Silly Walks", age: 42}, except: ~w(age)a)
```

## Installation

  1. Add `blazon` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:blazon, "~> 0.0.1"}]
  end
  ```

  2. Drink your :tea:

  3. That's it!

## Usage

### First Steps

...

### Options

...

### Embedding

...

### Linking

...

### Composition

...
