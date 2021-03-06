defmodule RSSBot.Mixfile do
  use Mix.Project

  def project do
    [app: :bot,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :nadia],
     mod: {RSSBot, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.7.2"},
     {:nadia, "~> 0.3"},
     {:feeder_ex, github: "manukall/feeder_ex"},
     {:exleveldb, "~> 0.6"},
     {:eleveldb, github: "basho/eleveldb", tag: "2.1.4"}]
  end
end
