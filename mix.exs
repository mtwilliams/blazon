defmodule Blazon.Mixfile do
  use Mix.Project

  def project do
    [name: "Blazon",
     app: :blazon,
     version: version,
     description: "Declarative abstract serializers.",
     homepage_url: homepage_url,
     source_url: github_url,
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "_build",
     deps_path: "_deps",
     deps: deps,
     package: package,
     docs: docs,
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(_), do: ~w()a ++ applications
  defp applications, do: ~w()a

  defp homepage_url, do: github_url
  defp github_url, do: "https://github.com/mtwilliams/blazon"
  defp documentation_url, do: "https://github.com/mtwilliams/blazon"

  defp version do
    "0.2.1"
  end

  defp elixirc_paths(:test), do: ~w(test/support) ++ elixirc_paths
  defp elixirc_paths(_), do: elixirc_paths
  defp elixirc_paths, do: ~w(lib)

  defp deps do [
    # Testing
    {:poison, ">= 0.0.0", only: [:test, :docs], optional: true},
    {:excoveralls, "~> 0.4", only: :test},

    # Documentation
    {:ex_doc, "~> 0.10", only: :docs},
    {:earmark, "~> 0.1", only: :docs},
    {:inch_ex, ">= 0.0.0", only: :docs}
  ] end

  defp package do
    [maintainers: ["Michael Williams"],
     licenses: ["Public Domain"],
     links: %{"GitHub" => github_url, "Docs" => documentation_url},
     files: ~w(mix.exs lib README* LICENSE*)]
  end

  defp docs do
    [main: "Blazon",
     canonical: "http://hexdocs.pm/blazon",
     source_ref: version,
     source_url: github_url]
  end
end
