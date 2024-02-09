defmodule ABI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :abi,
      version: "1.0.0-alpha5",
      elixir: "~> 1.14",
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
      {:ex_doc, "~> 0.31.1", only: :dev, runtime: false},
      {:jason, "~> 1.4"},
      {:ex_sha3, "~> 0.1.4"},
    ]
  end
end
