defmodule TryingThings.MixProject do
  use Mix.Project

  def project do
    [
      app: :trying_things,
      version: "0.1.0",
      elixir: "~> 1.18",
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
      {:yolo, ">= 0.2.0"},

      # I'm using EXLA as Nx backend
      # Nx is mostly used for pre/post processing
      {:exla, "~> 0.9.2"},
      # evision for image processing (you can use :image instead)
      {:evision, "~> 0.2.0"},
      {:kino_yolo, github: "poeticoding/kino_yolo"},
      {:vix, "~> 0.35"},
      {:boombox, "~> 0.2.6"}

      # {:boombox, github: "membraneframework/boombox", branch: "player"},
      # {:boombox, path: "../../boombox"},
      # {
      #   :ex_hls,
      #   #  branch: "handle-weird-segment-extensions",
      #   github: "membraneframework/ex_hls", branch: "varsill/handle_absolute_urls", override: true
      # }
      # {:ex_hls, path: "../../ex_hls", override: true}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
