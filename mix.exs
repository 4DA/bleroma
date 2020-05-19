defmodule App.Mixfile do
  use Mix.Project

  def project do
    [app: :app,
     version: "0.1.0",
     elixir: "~> 1.3",
     default_task: "server",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  def application do
    [applications: [:logger, :nadia],
     mod: {App, []}]
  end

  defp deps do
    [
      {:nadia, "~> 0.6.0"},
      {:tesla, "~> 1.3.0"},
      {:poison, "~> 4.0"},
      # upstream without my login_ouath fix
      # {:hunter, "~> 0.5.1"}
      {:hunter, git: "https://github.com/4DA/hunter.git", branch: "master"},
      # for local debugging:
      # {:hunter, path: "deps/hunter"},
      {:websockex, "~> 0.4.2"},
      {:html_sanitize_ex, "~> 1.4.0"}
    ]

  end

  defp aliases do
    [server: "run --no-halt"]
  end
end
