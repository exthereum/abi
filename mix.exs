defmodule ABI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :abi,
      version: "0.1.18",
      elixir: "~> 1.12",
      description: "Ethereum's ABI Interface",
      package: [
        maintainers: ["Geoffrey Hayes", "Mason Fischer"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/exthereum/abi"}
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false},
      {:jason, "~> 1.2"},
      {:ex_sha3, "~> 0.1"},
    ]
  end
end
